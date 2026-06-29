package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ==================== AI对话推荐 ====================

// AIChatRecommend AI对话推荐（简单实现）
func AIChatRecommend(c *gin.Context) {
	var req struct {
		Message string `json:"message" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
		return
	}

	reply := generateAIReply(req.Message)

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"data": gin.H{"reply": reply},
		"message": "success",
	})
}

func generateAIReply(message string) string {
	keywords := map[string]string{
		"流行": "推荐你试试《晴天》《稻香》《起风了》，都是经典流行歌曲！",
		"摇滚": "推荐《倔强》《海阔天空》《New Divide》，感受摇滚的力量！",
		"民谣": "推荐《成都》《南山南》《安和桥》，安静的民谣时光。",
		"电子": "推荐《Faded》《Alone》《Something Just Like This》，电子音乐的律动！",
		"说唱": "推荐《差不多先生》《我的滑板鞋》《野狼disco》，感受说唱的魅力！",
		"古风": "推荐《青花瓷》《烟花易冷》《琵琶行》，古风韵味十足。",
		"伤感": "推荐《后来》《匆匆那年》《那些年》，感受音乐的温度。",
		"快乐": "推荐《小苹果》《最炫民族风》《卡路里》，嗨起来！",
		"安静": "推荐《River Flows in You》《Kiss The Rain》《天空之城》，纯音乐的治愈。",
	}

	for keyword, reply := range keywords {
		if len(message) >= len(keyword) {
			for i := 0; i <= len(message)-len(keyword); i++ {
				if message[i:i+len(keyword)] == keyword {
					return reply
				}
			}
		}
	}

	return "你好！我是AI音乐助手，可以为你推荐歌曲、生成歌词。试试告诉我你喜欢的音乐风格或心情吧！"
}

// ==================== 积分商城 ====================

// ShopProduct 商城商品模型
type ShopProduct struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	Name        string `json:"name" gorm:"size:64"`
	Description string `json:"description" gorm:"size:255"`
	Points      int    `json:"points"`
	Type        string `json:"type" gorm:"size:32"`
	Value       int    `json:"value"`
	Stock       int    `json:"stock"`
	Image       string `json:"image" gorm:"size:255"`
	IsActive    bool   `json:"is_active" gorm:"default:true"`
	SortOrder   int    `json:"sort_order" gorm:"default:0"`
}

func (ShopProduct) TableName() string {
	return "shop_products"
}

// DailyTaskRecord 每日任务记录
type DailyTaskRecord struct {
	ID       uint   `json:"id" gorm:"primaryKey"`
	UserID   uint   `json:"user_id" gorm:"index"`
	TaskType string `json:"task_type" gorm:"size:32"`
	Date     string `json:"date" gorm:"size:10;index:idx_user_date"`
	Progress int    `json:"progress"`
	Rewarded bool   `json:"rewarded"`
}

func (DailyTaskRecord) TableName() string {
	return "daily_task_records"
}

// GetShopProducts 获取商城商品列表
func GetShopProducts(c *gin.Context) {
	var products []ShopProduct
	if err := db.DB.Where("is_active = ?", true).Order("sort_order ASC").Find(&products).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取商品失败")
		return
	}
	utils.Success(c, products)
}

// ExchangeProduct 兑换商品
func ExchangeProduct(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		ProductID uint `json:"product_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	var product ShopProduct
	if err := db.DB.First(&product, req.ProductID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "商品不存在")
		return
	}

	if !product.IsActive || product.Stock <= 0 {
		utils.Fail(c, http.StatusBadRequest, "商品已下架或库存不足")
		return
	}

	// 计算用户积分（签到次数 * 10）
	var checkInDays int64
	db.DB.Model(&model.CoinTransaction{}).Where("user_id = ? AND type = ?", userID, model.CoinTypeCheckIn).Count(&checkInDays)
	points := int(checkInDays) * 10

	if points < product.Points {
		utils.Fail(c, http.StatusBadRequest, fmt.Sprintf("积分不足，需要%d，当前%d", product.Points, points))
		return
	}

	var user model.User
	db.DB.First(&user, userID)

	err := db.DB.Transaction(func(tx *gorm.DB) error {
		// 原子扣减库存，使用 WHERE stock > 0 防止库存变负
		result := tx.Model(&ShopProduct{}).Where("id = ? AND stock > 0", product.ID).Update("stock", gorm.Expr("stock - 1"))
		if result.RowsAffected == 0 {
			return fmt.Errorf("库存不足")
		}
		if result.Error != nil {
			return result.Error
		}

		switch product.Type {
		case "vip_days":
			var expireAt time.Time
			if user.MemberExpireAt != nil && user.MemberExpireAt.After(time.Now()) {
				expireAt = user.MemberExpireAt.AddDate(0, 0, product.Value)
			} else {
				expireAt = time.Now().AddDate(0, 0, product.Value)
			}
			tx.Model(&model.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
				"member_level":     1,
				"member_expire_at": expireAt,
			})
		case "coins":
			tx.Model(&model.User{}).Where("id = ?", userID).Update("coins", gorm.Expr("coins + ?", product.Value))
			var updatedUser model.User
			tx.Select("coins").First(&updatedUser, userID)
			tx.Create(&model.CoinTransaction{
				UserID:      userID,
				Amount:      product.Value,
				Balance:     updatedUser.Coins,
				Type:        model.CoinTypeTaskReward,
				Description: "商城兑换: " + product.Name,
			})
		}

		return nil
	})

	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "兑换失败")
		return
	}

	utils.Success(c, gin.H{"message": "兑换成功"})
}

// ==================== 每日任务 ====================

// DailyTask 每日任务定义
type DailyTask struct {
	Type        string `json:"type"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Reward      int    `json:"reward"`
	Target      int    `json:"target"`
}

var dailyTasks = []DailyTask{
	{Type: "check_in", Name: "每日签到", Description: "完成每日签到", Reward: 5, Target: 1},
	{Type: "play_song", Name: "听歌3首", Description: "播放3首不同的歌曲", Reward: 3, Target: 3},
	{Type: "like_song", Name: "点赞歌曲", Description: "为喜欢的歌曲点赞", Reward: 2, Target: 1},
	{Type: "share_song", Name: "分享歌曲", Description: "分享一首歌曲给好友", Reward: 5, Target: 1},
	{Type: "create_post", Name: "发布动态", Description: "发布一条社区动态", Reward: 5, Target: 1},
	{Type: "ai_create", Name: "AI创作", Description: "使用AI创作一首歌词", Reward: 10, Target: 1},
}

// GetDailyTasks 获取每日任务列表
func GetDailyTasks(c *gin.Context) {
	userID := c.GetUint("user_id")
	today := time.Now().Format("2006-01-02")

	// 检查今日是否已签到
	var user model.User
	db.DB.First(&user, userID)
	isCheckedIn := user.LastCheckInDate == today

	// 获取今日任务完成记录
	var records []DailyTaskRecord
	db.DB.Where("user_id = ? AND date = ?", userID, today).Find(&records)

	recordMap := make(map[string]DailyTaskRecord)
	for _, r := range records {
		recordMap[r.TaskType] = r
	}

	type TaskWithStatus struct {
		DailyTask
		Progress int  `json:"progress"`
		Complete bool `json:"complete"`
		Rewarded bool `json:"rewarded"`
	}

	var result []TaskWithStatus
	for _, task := range dailyTasks {
		status := recordMap[task.Type]
		progress := status.Progress
		rewarded := status.Rewarded

		// 签到任务特殊处理
		if task.Type == "check_in" && isCheckedIn {
			progress = 1
			rewarded = true
		}

		result = append(result, TaskWithStatus{
			DailyTask: task,
			Progress:  progress,
			Complete:  progress >= task.Target,
			Rewarded:  rewarded,
		})
	}

	utils.Success(c, result)
}

// CompleteTask 完成任务并领取奖励
func CompleteTask(c *gin.Context) {
	userID := c.GetUint("user_id")
	taskType := c.Param("task_type")
	today := time.Now().Format("2006-01-02")

	var task *DailyTask
	for _, t := range dailyTasks {
		if t.Type == taskType {
			task = &t
			break
		}
	}
	if task == nil {
		utils.Fail(c, http.StatusBadRequest, "未知任务类型")
		return
	}

	// 签到任务走已有逻辑
	if taskType == "check_in" {
		utils.Fail(c, http.StatusBadRequest, "请使用签到接口")
		return
	}

	var record DailyTaskRecord
	db.DB.Where("user_id = ? AND task_type = ? AND date = ?", userID, taskType, today).First(&record)

	if record.Rewarded {
		utils.Fail(c, http.StatusBadRequest, "今日已领取奖励")
		return
	}

	if record.Progress < task.Target {
		utils.Fail(c, http.StatusBadRequest, fmt.Sprintf("任务未完成 (%d/%d)", record.Progress, task.Target))
		return
	}

	err := db.DB.Transaction(func(tx *gorm.DB) error {
		// 标记已领取
		tx.Model(&record).Update("rewarded", true)

		// 增加音币
		tx.Model(&model.User{}).Where("id = ?", userID).Update("coins", gorm.Expr("coins + ?", task.Reward))

		var user model.User
		tx.Select("coins").First(&user, userID)

		tx.Create(&model.CoinTransaction{
			UserID:      userID,
			Amount:      task.Reward,
			Balance:     user.Coins,
			Type:        model.CoinTypeTaskReward,
			Description: "每日任务: " + task.Name,
		})

		return nil
	})

	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "领取失败")
		return
	}

	utils.Success(c, gin.H{
		"message": fmt.Sprintf("领取成功，获得%d音币", task.Reward),
		"reward":  task.Reward,
	})
}

// GetTaskStats 获取任务统计
func GetTaskStats(c *gin.Context) {
	userID := c.GetUint("user_id")
	today := time.Now().Format("2006-01-02")

	var completedCount int64
	db.DB.Model(&DailyTaskRecord{}).Where("user_id = ? AND date = ? AND rewarded = true", userID, today).Count(&completedCount)

	// 加上签到
	var user model.User
	db.DB.First(&user, userID)
	if user.LastCheckInDate == today {
		completedCount++
	}

	var todayCoins int
	db.DB.Raw(`
		SELECT COALESCE(SUM(amount), 0) FROM coin_transactions
		WHERE user_id = ? AND type = 3 AND DATE(created_at) = ?
	`, userID, today).Scan(&todayCoins)

	utils.Success(c, gin.H{
		"completed_tasks": completedCount,
		"total_tasks":     len(dailyTasks),
		"today_coins":     todayCoins,
	})
}

// ==================== 限时折扣 ====================

// GetActiveDiscounts 获取有效的折扣信息
func GetActiveDiscounts(c *gin.Context) {
	var discounts []model.Discount
	now := time.Now().Unix()
	if err := db.DB.Where("is_active = true AND start_at <= ? AND end_at >= ?", now, now).Find(&discounts).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取折扣失败")
		return
	}
	utils.Success(c, discounts)
}

// ==================== 听歌统计 ====================

// GetListeningStats 获取用户听歌统计
func GetListeningStats(c *gin.Context) {
	userID := c.GetUint("user_id")
	now := time.Now()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	weekStart := todayStart.AddDate(0, 0, -7)
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	var todayPlays, weekPlays, monthPlays, totalPlays int64
	var todayDuration, weekDuration, monthDuration int64

	db.DB.Model(&model.PlayHistory{}).Where("user_id = ? AND created_at >= ?", userID, todayStart).Count(&todayPlays)
	db.DB.Model(&model.PlayHistory{}).Where("user_id = ? AND created_at >= ?", userID, weekStart).Count(&weekPlays)
	db.DB.Model(&model.PlayHistory{}).Where("user_id = ? AND created_at >= ?", userID, monthStart).Count(&monthPlays)
	db.DB.Model(&model.PlayHistory{}).Where("user_id = ?", userID).Count(&totalPlays)

	db.DB.Raw(`SELECT COALESCE(SUM(s.duration), 0) FROM play_histories h JOIN songs s ON s.id = h.song_id WHERE h.user_id = ? AND h.created_at >= ?`, userID, todayStart).Scan(&todayDuration)
	db.DB.Raw(`SELECT COALESCE(SUM(s.duration), 0) FROM play_histories h JOIN songs s ON s.id = h.song_id WHERE h.user_id = ? AND h.created_at >= ?`, userID, weekStart).Scan(&weekDuration)
	db.DB.Raw(`SELECT COALESCE(SUM(s.duration), 0) FROM play_histories h JOIN songs s ON s.id = h.song_id WHERE h.user_id = ? AND h.created_at >= ?`, userID, monthStart).Scan(&monthDuration)

	var likedSongs int64
	db.DB.Model(&model.Like{}).Where("user_id = ? AND like_type = 'song'", userID).Count(&likedSongs)

	type StyleCount struct {
		Style string `json:"style"`
		Count int64  `json:"count"`
	}
	var stylePrefs []StyleCount
	db.DB.Raw(`
		SELECT s.style, COUNT(*) as count FROM play_histories h
		JOIN songs s ON s.id = h.song_id
		WHERE h.user_id = ? AND s.style != ''
		GROUP BY s.style ORDER BY count DESC LIMIT 5
	`, userID).Scan(&stylePrefs)

	utils.Success(c, gin.H{
		"today":       gin.H{"plays": todayPlays, "duration": todayDuration / 60},
		"week":        gin.H{"plays": weekPlays, "duration": weekDuration / 60},
		"month":       gin.H{"plays": monthPlays, "duration": monthDuration / 60},
		"total_plays": totalPlays,
		"liked_songs": likedSongs,
		"style_prefs": stylePrefs,
	})
}

// ==================== 管理后台：关注关系管理 ====================

// AdminGetFollowList 管理后台获取关注关系列表
func AdminGetFollowList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	userID := c.Query("user_id")

	if page < 1 { page = 1 }
	if pageSize < 1 || pageSize > 100 { pageSize = 20 }

	var follows []model.Follow
	var total int64

	query := db.DB.Model(&model.Follow{})
	if userID != "" {
		query = query.Where("follower_id = ? OR following_id = ?", userID, userID)
	}

	query.Count(&total)
	query.Order("created_at DESC").Offset((page - 1) * pageSize).Limit(pageSize).Find(&follows)

	utils.Success(c, gin.H{"list": follows, "total": total})
}

// AdminDeleteFollow 管理后台删除关注关系
func AdminDeleteFollow(c *gin.Context) {
	id := c.Param("id")
	if err := db.DB.Delete(&model.Follow{}, id).Error; err != nil {
		utils.Fail(c, 500, "删除失败")
		return
	}
	utils.Success(c, gin.H{"message": "已解除关注关系"})
}

// ==================== 管理后台：MV管理 ====================

// AdminGetMVList 管理后台获取MV列表
func AdminGetMVList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 { page = 1 }
	if pageSize < 1 || pageSize > 100 { pageSize = 20 }

	var mvs []model.MV
	var total int64

	db.DB.Model(&model.MV{}).Count(&total)
	db.DB.Order("created_at DESC").Offset((page - 1) * pageSize).Limit(pageSize).Find(&mvs)

	utils.Success(c, gin.H{"list": mvs, "total": total})
}

// AdminDeleteMV 管理后台删除MV
func AdminDeleteMV(c *gin.Context) {
	id := c.Param("id")
	if err := db.DB.Delete(&model.MV{}, id).Error; err != nil {
		utils.Fail(c, 500, "删除失败")
		return
	}
	utils.Success(c, gin.H{"message": "删除成功"})
}

// ==================== 管理后台：敏感词管理 ====================

// GetSensitiveWords 获取敏感词列表
func GetSensitiveWords(c *gin.Context) {
	loadSensitiveWords()
	utils.Success(c, gin.H{"words": sensitiveWords})
}

// SaveSensitiveWords 保存敏感词列表
func SaveSensitiveWords(c *gin.Context) {
	var req struct {
		Words []string `json:"words" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误")
		return
	}

	wordsJSON, _ := json.Marshal(req.Words)

	// 保存到数据库
	var cfg model.SystemConfig
	if err := db.DB.Where("`key` = ?", "sensitive_words").First(&cfg).Error; err == nil {
		db.DB.Model(&cfg).Update("value", string(wordsJSON))
	} else {
		db.DB.Create(&model.SystemConfig{
			Key:   "sensitive_words",
			Value: string(wordsJSON),
		})
	}

	// 重新加载敏感词
	ReloadSensitiveWords()

	utils.Success(c, gin.H{"message": "保存成功", "count": len(req.Words)})
}

// ==================== 管理后台：歌曲详情增强 ====================

// AdminGetSongDetail 管理后台获取歌曲详情（含歌词）
func AdminGetSongDetail(c *gin.Context) {
	id := c.Param("id")
	var song model.Song
	if err := db.DB.First(&song, id).Error; err != nil {
		utils.Fail(c, 404, "歌曲不存在")
		return
	}

	// 获取评论数
	var commentCount int64
	db.DB.Model(&model.Comment{}).Where("song_id = ?", song.ID).Count(&commentCount)

	utils.Success(c, gin.H{
		"song":          song,
		"comment_count": commentCount,
	})
}

// AdminUpdateSongLyric 管理后台更新歌曲歌词
func AdminUpdateSongLyric(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Lyric string `json:"lyric"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误")
		return
	}

	// 敏感词检测
	if matched := CheckSensitiveWords(req.Lyric); len(matched) > 0 {
		utils.Fail(c, 400, "歌词包含敏感词: "+strings.Join(matched, ", "))
		return
	}

	if err := db.DB.Model(&model.Song{}).Where("id = ?", id).Update("lyric", req.Lyric).Error; err != nil {
		utils.Fail(c, 500, "更新失败")
		return
	}

	utils.Success(c, gin.H{"message": "更新成功"})
}

// ==================== 管理后台：动态隐藏/显示 ====================

// AdminTogglePostStatus 管理后台切换动态状态
func AdminTogglePostStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status int `json:"status"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误")
		return
	}

	if err := db.DB.Model(&model.Post{}).Where("id = ?", id).Update("status", req.Status).Error; err != nil {
		utils.Fail(c, 500, "操作失败")
		return
	}

	utils.Success(c, gin.H{"message": "操作成功"})
}
