package handler

import (
	"encoding/csv"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/yourname/aimusic-backend/internal/model"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ==================== 1. AI任务中心增强 ====================

// GetAITaskStats 获取AI任务统计数据
func GetAITaskStats(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

		// 总量统计
		var totalTasks, successTasks, failedTasks, pendingTasks, runningTasks int64
		db.Model(&model.AsyncTask{}).Count(&totalTasks)
		db.Model(&model.AsyncTask{}).Where("status = 2").Count(&successTasks)
		db.Model(&model.AsyncTask{}).Where("status = 3").Count(&failedTasks)
		db.Model(&model.AsyncTask{}).Where("status = 0").Count(&pendingTasks)
		db.Model(&model.AsyncTask{}).Where("status = 1").Count(&runningTasks)

		// 今日统计
		var todayTotal, todaySuccess, todayFailed int64
		db.Model(&model.AsyncTask{}).Where("created_at >= ?", todayStart).Count(&todayTotal)
		db.Model(&model.AsyncTask{}).Where("status = 2 AND created_at >= ?", todayStart).Count(&todaySuccess)
		db.Model(&model.AsyncTask{}).Where("status = 3 AND created_at >= ?", todayStart).Count(&todayFailed)

		// 按类型统计
		type TypeCount struct {
			TaskType int8  `json:"task_type"`
			Count    int64 `json:"count"`
		}
		var typeStats []TypeCount
		db.Model(&model.AsyncTask{}).Select("task_type, COUNT(*) as count").Group("task_type").Scan(&typeStats)

		// 7天趋势
		trendDates := make([]string, 7)
		trendSuccess := make([]int64, 7)
		trendFailed := make([]int64, 7)
		for i := 6; i >= 0; i-- {
			dayStart := time.Date(now.Year(), now.Month(), now.Day()-i, 0, 0, 0, 0, now.Location())
			dayEnd := dayStart.AddDate(0, 0, 1)
			trendDates[6-i] = dayStart.Format("01-02")
			db.Model(&model.AsyncTask{}).Where("status = 2 AND created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&trendSuccess[6-i])
			db.Model(&model.AsyncTask{}).Where("status = 3 AND created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&trendFailed[6-i])
		}

		successRate := 0.0
		if totalTasks > 0 {
			successRate = float64(successTasks) / float64(totalTasks) * 100
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"total":        totalTasks,
				"success":      successTasks,
				"failed":       failedTasks,
				"pending":      pendingTasks,
				"running":      runningTasks,
				"today_total":  todayTotal,
				"today_success": todaySuccess,
				"today_failed": todayFailed,
				"success_rate": fmt.Sprintf("%.1f", successRate),
				"by_type":      typeStats,
				"trend": gin.H{
					"dates":   trendDates,
					"success": trendSuccess,
					"failed":  trendFailed,
				},
			},
			"message": "success",
		})
	}
}

// BatchRetryAITasks 批量重试失败任务
func BatchRetryAITasks(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			TaskIDs []uint `json:"task_ids" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		result := db.Model(&model.AsyncTask{}).Where("id IN ? AND status = 3", req.TaskIDs).Update("status", 0)
		if result.Error != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "操作失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{"updated": result.RowsAffected},
			"message": fmt.Sprintf("已重试%d个任务", result.RowsAffected),
		})
	}
}

// BatchCancelAITasks 批量取消任务
func BatchCancelAITasks(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			TaskIDs []uint `json:"task_ids" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		result := db.Model(&model.AsyncTask{}).Where("id IN ? AND status IN (0, 1)", req.TaskIDs).
			Updates(map[string]interface{}{"status": 3, "error_msg": "管理员取消"})
		if result.Error != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "操作失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{"cancelled": result.RowsAffected},
			"message": fmt.Sprintf("已取消%d个任务", result.RowsAffected),
		})
	}
}

// GetUserAIUsageRank 获取用户AI使用排行
func GetUserAIUsageRank(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		type UserUsage struct {
			UserID   uint   `json:"user_id"`
			Nickname string `json:"nickname"`
			Total    int64  `json:"total"`
			Success  int64  `json:"success"`
			Failed   int64  `json:"failed"`
		}
		var results []UserUsage
		db.Raw(`SELECT u.id as user_id, u.nickname,
			COUNT(t.id) as total,
			SUM(CASE WHEN t.status = 2 THEN 1 ELSE 0 END) as success,
			SUM(CASE WHEN t.status = 3 THEN 1 ELSE 0 END) as failed
			FROM users u
			JOIN async_tasks t ON t.user_id = u.id
			GROUP BY u.id, u.nickname
			ORDER BY total DESC
			LIMIT 20`).Scan(&results)

		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"data":    results,
			"message": "success",
		})
	}
}

// ==================== 2. 数据分析增强（真实数据） ====================

// GetRealRetentionData 获取真实留存数据
func GetRealRetentionData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()

		// 次日留存：昨天注册的用户今天是否活跃
		yesterday := time.Date(now.Year(), now.Month(), now.Day()-1, 0, 0, 0, 0, now.Location())
		today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

		var yesterdayNewUsers int64
		db.Model(&model.User{}).Where("created_at >= ? AND created_at < ?", yesterday, today).Count(&yesterdayNewUsers)

		// 检查这些用户今天是否有播放记录
		var day1Retained int64
		if yesterdayNewUsers > 0 {
			db.Raw(`SELECT COUNT(DISTINCT u.id) FROM users u
				JOIN play_histories h ON h.user_id = u.id AND h.created_at >= ?
				WHERE u.created_at >= ? AND u.created_at < ?`,
				today, yesterday, today).Scan(&day1Retained)
		}

		// 7日留存
		weekAgo := time.Date(now.Year(), now.Month(), now.Day()-7, 0, 0, 0, 0, now.Location())
		weekAgoEnd := time.Date(now.Year(), now.Month(), now.Day()-6, 0, 0, 0, 0, now.Location())
		var weekNewUsers int64
		db.Model(&model.User{}).Where("created_at >= ? AND created_at < ?", weekAgo, weekAgoEnd).Count(&weekNewUsers)

		var day7Retained int64
		if weekNewUsers > 0 {
			db.Raw(`SELECT COUNT(DISTINCT u.id) FROM users u
				JOIN play_histories h ON h.user_id = u.id AND h.created_at >= ?
				WHERE u.created_at >= ? AND u.created_at < ?`,
				weekAgoEnd, weekAgo, weekAgoEnd).Scan(&day7Retained)
		}

		// 30日留存
		monthAgo := time.Date(now.Year(), now.Month(), now.Day()-30, 0, 0, 0, 0, now.Location())
		monthAgoEnd := time.Date(now.Year(), now.Month(), now.Day()-29, 0, 0, 0, 0, now.Location())
		var monthNewUsers int64
		db.Model(&model.User{}).Where("created_at >= ? AND created_at < ?", monthAgo, monthAgoEnd).Count(&monthNewUsers)

		var day30Retained int64
		if monthNewUsers > 0 {
			db.Raw(`SELECT COUNT(DISTINCT u.id) FROM users u
				JOIN play_histories h ON h.user_id = u.id AND h.created_at >= ?
				WHERE u.created_at >= ? AND u.created_at < ?`,
				monthAgoEnd, monthAgo, monthAgoEnd).Scan(&day30Retained)
		}

		day1Rate := 0.0
		if yesterdayNewUsers > 0 {
			day1Rate = float64(day1Retained) / float64(yesterdayNewUsers) * 100
		}
		day7Rate := 0.0
		if weekNewUsers > 0 {
			day7Rate = float64(day7Retained) / float64(weekNewUsers) * 100
		}
		day30Rate := 0.0
		if monthNewUsers > 0 {
			day30Rate = float64(day30Retained) / float64(monthNewUsers) * 100
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"day1": gin.H{
					"new_users": yesterdayNewUsers,
					"retained":  day1Retained,
					"rate":      fmt.Sprintf("%.1f", day1Rate),
				},
				"day7": gin.H{
					"new_users": weekNewUsers,
					"retained":  day7Retained,
					"rate":      fmt.Sprintf("%.1f", day7Rate),
				},
				"day30": gin.H{
					"new_users": monthNewUsers,
					"retained":  day30Retained,
					"rate":      fmt.Sprintf("%.1f", day30Rate),
				},
			},
			"message": "success",
		})
	}
}

// GetRealFunnelData 获取真实漏斗数据
func GetRealFunnelData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var totalUsers, usersWithSong, usersWithPost, usersWithOrder int64
		db.Model(&model.User{}).Count(&totalUsers)
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM songs").Scan(&usersWithSong)
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM posts").Scan(&usersWithPost)
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM membership_orders WHERE status = 1").Scan(&usersWithOrder)

		songRate := 0.0
		if totalUsers > 0 {
			songRate = float64(usersWithSong) / float64(totalUsers) * 100
		}
		postRate := 0.0
		if totalUsers > 0 {
			postRate = float64(usersWithPost) / float64(totalUsers) * 100
		}
		orderRate := 0.0
		if totalUsers > 0 {
			orderRate = float64(usersWithOrder) / float64(totalUsers) * 100
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"funnel": []gin.H{
					{"name": "注册用户", "count": totalUsers, "rate": "100.0"},
					{"name": "创作歌曲", "count": usersWithSong, "rate": fmt.Sprintf("%.1f", songRate)},
					{"name": "发布动态", "count": usersWithPost, "rate": fmt.Sprintf("%.1f", postRate)},
					{"name": "付费用户", "count": usersWithOrder, "rate": fmt.Sprintf("%.1f", orderRate)},
				},
			},
			"message": "success",
		})
	}
}

// GetRealRevenueData 获取真实营收数据
func GetRealRevenueData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

		// 今日/本月营收
		var todayRevenue, monthRevenue int64
		db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ?", todayStart.Unix()).Select("COALESCE(SUM(amount),0)").Scan(&todayRevenue)
		db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ?", monthStart.Unix()).Select("COALESCE(SUM(amount),0)").Scan(&monthRevenue)

		// 付费用户数
		var paidUsers int64
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM membership_orders WHERE status = 1").Scan(&paidUsers)

		// 总用户数
		var totalUsers int64
		db.Model(&model.User{}).Count(&totalUsers)

		payRate := 0.0
		if totalUsers > 0 {
			payRate = float64(paidUsers) / float64(totalUsers) * 100
		}

		// 7天营收趋势
		trendDates := make([]string, 7)
		trendRevenue := make([]int64, 7)
		for i := 6; i >= 0; i-- {
			dayStart := time.Date(now.Year(), now.Month(), now.Day()-i, 0, 0, 0, 0, now.Location())
			dayEnd := dayStart.AddDate(0, 0, 1)
			trendDates[6-i] = dayStart.Format("01-02")
			db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ? AND pay_time < ?", dayStart.Unix(), dayEnd.Unix()).Select("COALESCE(SUM(amount),0)").Scan(&trendRevenue[6-i])
		}

		// 收入来源分布
		type SourceAmount struct {
			Name   string `json:"name"`
			Amount int64  `json:"amount"`
		}
		var vipRevenue, coinRevenue int64
		db.Model(&model.MembershipOrder{}).Where("status = 1").Select("COALESCE(SUM(amount),0)").Scan(&vipRevenue)
		db.Model(&model.CoinTransaction{}).Where("type = 1").Select("COALESCE(SUM(ABS(amount)),0)").Scan(&coinRevenue)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"today_revenue": todayRevenue,
				"month_revenue": monthRevenue,
				"paid_users":    paidUsers,
				"pay_rate":      fmt.Sprintf("%.1f", payRate),
				"trend": gin.H{
					"dates":   trendDates,
					"revenue": trendRevenue,
				},
				"sources": []gin.H{
					{"name": "VIP订阅", "amount": vipRevenue},
					{"name": "音币充值", "amount": coinRevenue},
				},
			},
			"message": "success",
		})
	}
}

// ==================== 3. 实时监控增强 ====================

// GetRealMonitorStats 获取真实监控数据
func GetRealMonitorStats(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		hourAgo := now.Add(-1 * time.Hour)

		// 今日活跃用户（有播放记录的）
		var todayActiveUsers int64
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ?", todayStart).Scan(&todayActiveUsers)

		// 今日播放量
		var todayPlays int64
		db.Model(&model.PlayHistory{}).Where("created_at >= ?", todayStart).Count(&todayPlays)

		// 近1小时播放量
		var hourPlays int64
		db.Model(&model.PlayHistory{}).Where("created_at >= ?", hourAgo).Count(&hourPlays)

		// 今日新增用户
		var todayNewUsers int64
		db.Model(&model.User{}).Where("created_at >= ?", todayStart).Count(&todayNewUsers)

		// 今日AI任务
		var todayAITasks int64
		db.Model(&model.AsyncTask{}).Where("created_at >= ?", todayStart).Count(&todayAITasks)

		// AI任务队列状态
		var waitingTasks, runningTasks int64
		db.Model(&model.AsyncTask{}).Where("status = 0").Count(&waitingTasks)
		db.Model(&model.AsyncTask{}).Where("status = 1").Count(&runningTasks)

		// 今日新增歌曲
		var todayNewSongs int64
		db.Model(&model.Song{}).Where("created_at >= ?", todayStart).Count(&todayNewSongs)

		// 今日新增动态
		var todayNewPosts int64
		db.Model(&model.Post{}).Where("created_at >= ?", todayStart).Count(&todayNewPosts)

		// 总用户/总歌曲
		var totalUsers, totalSongs int64
		db.Model(&model.User{}).Count(&totalUsers)
		db.Model(&model.Song{}).Count(&totalSongs)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"realtime": gin.H{
					"today_active_users": todayActiveUsers,
					"today_plays":        todayPlays,
					"hour_plays":         hourPlays,
					"waiting_tasks":      waitingTasks,
					"running_tasks":      runningTasks,
				},
				"today": gin.H{
					"new_users":   todayNewUsers,
					"new_songs":   todayNewSongs,
					"new_posts":   todayNewPosts,
					"ai_tasks":    todayAITasks,
				},
				"totals": gin.H{
					"users": totalUsers,
					"songs": totalSongs,
				},
			},
			"message": "success",
		})
	}
}

// GetAPIStats 获取API调用统计（基于操作日志）
func GetAPIStats(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

		// 今日操作日志数
		var todayLogs int64
		db.Model(&model.AdminOperationLog{}).Where("created_at >= ?", todayStart).Count(&todayLogs)

		// 按操作类型统计
		type TypeCount struct {
			Action string `json:"action"`
			Count  int64  `json:"count"`
		}
		var actionStats []TypeCount
		db.Model(&model.AdminOperationLog{}).Select("action, COUNT(*) as count").Where("created_at >= ?", todayStart).Group("action").Order("count DESC").Limit(10).Scan(&actionStats)

		// 每小时操作量（今日）
		hourlyData := make([]int64, 24)
		for i := 0; i < 24; i++ {
			hourStart := time.Date(now.Year(), now.Month(), now.Day(), i, 0, 0, 0, now.Location())
			hourEnd := hourStart.Add(1 * time.Hour)
			db.Model(&model.AdminOperationLog{}).Where("created_at >= ? AND created_at < ?", hourStart, hourEnd).Count(&hourlyData[i])
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"today_total": todayLogs,
				"by_action":   actionStats,
				"hourly":      hourlyData,
			},
			"message": "success",
		})
	}
}

// ==================== 4. 用户画像增强 ====================

// GetUserProfile 获取用户详细画像
func GetUserProfile(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.Param("id")
		if userID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "用户ID不能为空"})
			return
		}

		// 用户基本信息
		var user model.User
		if err := db.First(&user, userID).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "用户不存在"})
			return
		}

		// 创作统计
		var songCount, postCount, commentCount, aiTaskCount int64
		db.Model(&model.Song{}).Where("user_id = ?", userID).Count(&songCount)
		db.Model(&model.Post{}).Where("user_id = ?", userID).Count(&postCount)
		db.Model(&model.Comment{}).Where("user_id = ?", userID).Count(&commentCount)
		db.Model(&model.AsyncTask{}).Where("user_id = ?", userID).Count(&aiTaskCount)

		// 互动统计
		var likeCount, followCount, followerCount int64
		db.Model(&model.Like{}).Where("user_id = ?", userID).Count(&likeCount)
		db.Model(&model.Follow{}).Where("follower_id = ?", userID).Count(&followCount)
		db.Model(&model.Follow{}).Where("following_id = ?", userID).Count(&followerCount)

		// 消费统计
		var totalSpent int64
		db.Model(&model.MembershipOrder{}).Where("user_id = ? AND status = 1", userID).Select("COALESCE(SUM(amount),0)").Scan(&totalSpent)

		// 播放统计
		var playCount int64
		db.Model(&model.PlayHistory{}).Where("user_id = ?", userID).Count(&playCount)

		// 最近活动
		type Activity struct {
			Type      string `json:"type"`
			Content   string `json:"content"`
			CreatedAt string `json:"created_at"`
		}
		var recentActivities []Activity

		// 最近播放
		var recentPlays []struct {
			SongID    uint   `json:"song_id"`
			Title     string `json:"title"`
			CreatedAt string `json:"created_at"`
		}
		db.Raw(`SELECT h.song_id, s.title, h.created_at
			FROM play_histories h
			JOIN songs s ON s.id = h.song_id
			WHERE h.user_id = ?
			ORDER BY h.created_at DESC
			LIMIT 5`, userID).Scan(&recentPlays)

		for _, p := range recentPlays {
			recentActivities = append(recentActivities, Activity{
				Type:      "play",
				Content:   "播放了《" + p.Title + "》",
				CreatedAt: p.CreatedAt,
			})
		}

		// 最近创作
		var recentSongs []struct {
			ID        uint   `json:"id"`
			Title     string `json:"title"`
			CreatedAt string `json:"created_at"`
		}
		db.Raw("SELECT id, title, created_at FROM songs WHERE user_id = ? ORDER BY created_at DESC LIMIT 3", userID).Scan(&recentSongs)

		for _, s := range recentSongs {
			recentActivities = append(recentActivities, Activity{
				Type:      "create",
				Content:   "创作了《" + s.Title + "》",
				CreatedAt: s.CreatedAt,
			})
		}

		// 听歌风格偏好
		type StylePref struct {
			Style string `json:"style"`
			Count int64  `json:"count"`
		}
		var stylePrefs []StylePref
		db.Model(&model.Song{}).Select("style, COUNT(*) as count").Where("user_id = ? AND style != ''", userID).Group("style").Order("count DESC").Limit(5).Scan(&stylePrefs)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"user": gin.H{
					"id":           user.ID,
					"username":     user.Username,
					"nickname":     user.Nickname,
					"avatar":       user.Avatar,
					"email":        user.Email,
					"member_level": user.MemberLevel,
					"coins":        user.Coins,
					"status":       user.Status,
					"created_at":   user.CreatedAt.Format("2006-01-02 15:04:05"),
				},
				"stats": gin.H{
					"songs":       songCount,
					"posts":       postCount,
					"comments":    commentCount,
					"ai_tasks":    aiTaskCount,
					"likes":       likeCount,
					"following":   followCount,
					"followers":   followerCount,
					"play_count":  playCount,
					"total_spent": totalSpent,
				},
				"style_preferences": stylePrefs,
				"recent_activities": recentActivities,
			},
			"message": "success",
		})
	}
}

// GetUserSegments 获取用户分群统计
func GetUserSegments(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		weekAgo := now.AddDate(0, 0, -7)
		monthAgo := now.AddDate(0, 0, -30)
		threeMonthsAgo := now.AddDate(0, 0, -90)

		// 高活跃用户（7天内有播放记录）
		var highActiveUsers int64
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ?", weekAgo).Scan(&highActiveUsers)

		// 中活跃用户（30天内有播放记录但7天内没有）
		var midActiveUsers int64
		db.Raw(`SELECT COUNT(DISTINCT user_id) FROM play_histories
			WHERE created_at >= ? AND user_id NOT IN
			(SELECT DISTINCT user_id FROM play_histories WHERE created_at >= ?)`, monthAgo, weekAgo).Scan(&midActiveUsers)

		// 低活跃用户（90天内有播放记录但30天内没有）
		var lowActiveUsers int64
		db.Raw(`SELECT COUNT(DISTINCT user_id) FROM play_histories
			WHERE created_at >= ? AND user_id NOT IN
			(SELECT DISTINCT user_id FROM play_histories WHERE created_at >= ?)`, threeMonthsAgo, monthAgo).Scan(&lowActiveUsers)

		// 流失用户（90天内无播放记录）
		var totalUsers int64
		db.Model(&model.User{}).Count(&totalUsers)
		var activeUsers int64
		db.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ?", threeMonthsAgo).Scan(&activeUsers)
		churnedUsers := totalUsers - activeUsers

		// 高消费用户（累计消费超过100元）
		var highSpenders int64
		db.Raw(`SELECT COUNT(*) FROM (
			SELECT user_id, SUM(amount) as total
			FROM membership_orders WHERE status = 1
			GROUP BY user_id HAVING total >= 10000
		) t`).Scan(&highSpenders)

		// 创作达人（发布超过5首歌曲）
		var creators int64
		db.Raw(`SELECT COUNT(*) FROM (
			SELECT user_id, COUNT(*) as cnt
			FROM songs GROUP BY user_id HAVING cnt >= 5
		) t`).Scan(&creators)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"segments": []gin.H{
					{"name": "高活跃用户", "count": highActiveUsers, "desc": "7天内有播放"},
					{"name": "中活跃用户", "count": midActiveUsers, "desc": "30天内有播放"},
					{"name": "低活跃用户", "count": lowActiveUsers, "desc": "90天内有播放"},
					{"name": "流失用户", "count": churnedUsers, "desc": "90天无播放"},
					{"name": "高消费用户", "count": highSpenders, "desc": "累计消费≥100元"},
					{"name": "创作达人", "count": creators, "desc": "发布≥5首歌曲"},
				},
			},
			"message": "success",
		})
	}
}

// ==================== 5. 财务报表增强 ====================

// GetFinanceReport 获取财务报表
func GetFinanceReport(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		reportType := c.DefaultQuery("type", "daily") // daily/weekly/monthly
		now := time.Now()

		var startDate time.Time
		var dateStrs []string

		switch reportType {
		case "daily":
			// 近7天日报
			for i := 6; i >= 0; i-- {
				d := time.Date(now.Year(), now.Month(), now.Day()-i, 0, 0, 0, 0, now.Location())
				dateStrs = append(dateStrs, d.Format("2006-01-02"))
			}
			startDate = time.Date(now.Year(), now.Month(), now.Day()-6, 0, 0, 0, 0, now.Location())
		case "weekly":
			// 近4周周报
			for i := 3; i >= 0; i-- {
				d := now.AddDate(0, 0, -7*i)
				weekStart := d.AddDate(0, 0, -int(d.Weekday())+1)
				dateStrs = append(dateStrs, "W"+weekStart.Format("01-02"))
			}
			startDate = now.AddDate(0, 0, -28)
		case "monthly":
			// 近6月月报
			for i := 5; i >= 0; i-- {
				d := time.Date(now.Year(), now.Month()-time.Month(i), 1, 0, 0, 0, 0, now.Location())
				dateStrs = append(dateStrs, d.Format("2006-01"))
			}
			startDate = time.Date(now.Year(), now.Month()-5, 1, 0, 0, 0, 0, now.Location())
		}

		// 收入数据
		type DailyFinance struct {
			Date         string `json:"date"`
			OrderCount   int64  `json:"order_count"`
			Revenue      int64  `json:"revenue"`
			NewPaidUsers int64  `json:"new_paid_users"`
		}
		var reports []DailyFinance

		if reportType == "daily" {
			for _, dateStr := range dateStrs {
				dayStart, _ := time.Parse("2006-01-02", dateStr)
				dayEnd := dayStart.AddDate(0, 0, 1)
				var df DailyFinance
				df.Date = dateStr
				db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ? AND pay_time < ?", dayStart.Unix(), dayEnd.Unix()).Count(&df.OrderCount)
				db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ? AND pay_time < ?", dayStart.Unix(), dayEnd.Unix()).Select("COALESCE(SUM(amount),0)").Scan(&df.Revenue)
				db.Raw(`SELECT COUNT(DISTINCT user_id) FROM membership_orders
					WHERE status = 1 AND pay_time >= ? AND pay_time < ?
					AND user_id NOT IN (SELECT DISTINCT user_id FROM membership_orders WHERE status = 1 AND pay_time < ?)`,
					dayStart.Unix(), dayEnd.Unix(), dayStart.Unix()).Scan(&df.NewPaidUsers)
				reports = append(reports, df)
			}
		}

		// 汇总统计
		var totalRevenue int64
		db.Model(&model.MembershipOrder{}).Where("status = 1 AND created_at >= ?", startDate).Select("COALESCE(SUM(amount),0)").Scan(&totalRevenue)

		var totalOrders int64
		db.Model(&model.MembershipOrder{}).Where("status = 1 AND created_at >= ?", startDate).Count(&totalOrders)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"type":          reportType,
				"dates":         dateStrs,
				"reports":       reports,
				"total_revenue": totalRevenue,
				"total_orders":  totalOrders,
			},
			"message": "success",
		})
	}
}

// ExportFinanceCSV 导出财务报表CSV
func ExportFinanceCSV(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		startDate := c.Query("start_date")
		endDate := c.Query("end_date")

		if startDate == "" {
			startDate = time.Now().AddDate(0, 0, -30).Format("2006-01-02")
		}
		if endDate == "" {
			endDate = time.Now().Format("2006-01-02")
		}

		start, _ := time.Parse("2006-01-02", startDate)
		end, _ := time.Parse("2006-01-02", endDate)
		end = end.AddDate(0, 0, 1)

		var orders []model.MembershipOrder
		db.Where("status = 1 AND pay_time >= ? AND pay_time < ?", start.Unix(), end.Unix()).Find(&orders)

		c.Header("Content-Type", "text/csv")
		c.Header("Content-Disposition", "attachment; filename=finance_report.csv")

		w := csv.NewWriter(c.Writer)
		w.Write([]string{"订单号", "用户ID", "会员等级", "金额(分)", "支付方式", "支付时间"})

		for _, order := range orders {
			payTime := ""
			if order.PayTime != nil {
				payTime = time.Unix(*order.PayTime, 0).Format("2006-01-02 15:04:05")
			}
			w.Write([]string{
				order.OrderNo,
				strconv.FormatUint(uint64(order.UserID), 10),
				strconv.Itoa(order.Level),
				strconv.Itoa(order.Amount),
				order.PayMethod,
				payTime,
			})
		}
		w.Flush()
	}
}
