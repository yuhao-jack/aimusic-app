package main

import (
	"log"
	"time"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
)

func main() {
	log.Println("=== AI Music Daily Stats Collector ===")

	// 初始化配置
	if err := config.InitConfig(); err != nil {
		log.Fatalf("Init config failed: %v", err)
	}
	log.Println("Config initialized successfully")

	// 初始化MySQL
	if err := db.InitMySQL(); err != nil {
		log.Fatalf("Init MySQL failed: %v", err)
	}
	log.Println("MySQL initialized successfully")

	// 初始化Redis（虽然统计任务不需要Redis，但保持一致性）
	if err := db.InitRedis(); err != nil {
		log.Printf("Init Redis failed (non-critical): %v", err)
	}

	// 启动时立即执行一次
	collectDailyStats()

	// 计算距离明天凌晨1点的等待时间
	now := time.Now()
	tomorrow1AM := time.Date(now.Year(), now.Month(), now.Day()+1, 1, 0, 0, 0, now.Location())
	waitDuration := tomorrow1AM.Sub(now)
	log.Printf("下次执行时间: %s (等待 %v)", tomorrow1AM.Format("2006-01-02 15:04:05"), waitDuration)

	// 每天凌晨1点执行统计
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()

	// 先等待到明天凌晨1点
	time.Sleep(waitDuration)
	collectDailyStats()

	// 之后每24小时执行一次
	for range ticker.C {
		collectDailyStats()
	}
}

// collectDailyStats 收集并保存每日统计数据
func collectDailyStats() {
	today := time.Now().Format("2006-01-02")
	log.Printf("[%s] 开始收集每日统计数据...", today)

	stats := model.DailyStats{Date: today}

	// 统计新增用户
	var newUsers int64
	db.DB.Model(&model.User{}).Where("DATE(created_at) = ?", today).Count(&newUsers)
	stats.NewUsers = int(newUsers)

	// 统计活跃用户（从播放历史中去重统计）
	var activeUsers int64
	db.DB.Model(&model.PlayHistory{}).
		Where("DATE(created_at) = ?", today).
		Distinct("user_id").
		Count(&activeUsers)
	stats.ActiveUsers = int(activeUsers)

	// 统计新增歌曲
	var newSongs int64
	db.DB.Model(&model.Song{}).Where("DATE(created_at) = ?", today).Count(&newSongs)
	stats.NewSongs = int(newSongs)

	// 统计播放次数
	var totalPlays int64
	db.DB.Model(&model.PlayHistory{}).Where("DATE(created_at) = ?", today).Count(&totalPlays)
	stats.TotalPlays = int(totalPlays)

	// 统计新增动态
	var newPosts int64
	db.DB.Model(&model.Post{}).Where("DATE(created_at) = ?", today).Count(&newPosts)
	stats.NewPosts = int(newPosts)

	// 统计新增已支付订单
	var newOrders int64
	db.DB.Model(&model.MembershipOrder{}).
		Where("DATE(created_at) = ? AND status = 1", today).
		Count(&newOrders)
	stats.NewOrders = int(newOrders)

	// 统计收入（单位：分）
	var revenue float64
	db.DB.Model(&model.MembershipOrder{}).
		Where("DATE(created_at) = ? AND status = 1", today).
		Select("COALESCE(SUM(amount), 0)").
		Scan(&revenue)
	stats.Revenue = int(revenue)

	// 统计AI生成次数
	var aiGenerations int64
	db.DB.Model(&model.AsyncTask{}).Where("DATE(created_at) = ?", today).Count(&aiGenerations)
	stats.AIGenerations = int(aiGenerations)

	// 保存或更新统计数据（按日期唯一）
	result := db.DB.Where("date = ?", today).Assign(stats).FirstOrCreate(&stats)
	if result.Error != nil {
		log.Printf("保存每日统计数据失败: %v", result.Error)
		return
	}

	log.Printf("[%s] 统计完成: 新增用户=%d, 活跃用户=%d, 新增歌曲=%d, 播放次数=%d, 新增动态=%d, 新增订单=%d, 收入=%d分, AI生成=%d",
		today, stats.NewUsers, stats.ActiveUsers, stats.NewSongs,
		stats.TotalPlays, stats.NewPosts, stats.NewOrders, stats.Revenue, stats.AIGenerations)

	// 检查并处理过期会员
	checkExpiredMembers()
}

// checkExpiredMembers 检查并重置过期会员状态
// 将 member_expire_at < NOW() 且 member_level > 0 的用户重置为普通用户
func checkExpiredMembers() {
	log.Println("开始检查过期会员...")

	// 查询过期会员数量
	var expiredCount int64
	db.DB.Model(&model.User{}).
		Where("member_expire_at IS NOT NULL AND member_expire_at < ? AND member_level > 0", time.Now()).
		Count(&expiredCount)

	if expiredCount == 0 {
		log.Println("没有过期会员")
		return
	}

	log.Printf("发现 %d 个过期会员，开始处理...", expiredCount)

	// 批量更新过期会员为普通用户
	result := db.DB.Model(&model.User{}).
		Where("member_expire_at IS NOT NULL AND member_expire_at < ? AND member_level > 0", time.Now()).
		Updates(map[string]interface{}{
			"member_level":     model.MemberLevelFree,
			"member_expire_at": nil,
			"max_daily_ai":     3, // 恢复普通用户每日AI上限
		})

	if result.Error != nil {
		log.Printf("重置过期会员失败: %v", result.Error)
		return
	}

	log.Printf("成功重置 %d 个过期会员为普通用户", result.RowsAffected)
}
