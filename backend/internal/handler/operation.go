package handler

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/yourname/aimusic-backend/internal/model"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ==================== Banner管理 ====================

// GetBannerList 获取轮播图列表
func GetBannerList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		position := c.DefaultQuery("position", "")

		offset := (page - 1) * pageSize
		var banners []model.Banner
		var total int64

		query := db.Model(&model.Banner{})
		if position != "" {
			query = query.Where("position = ?", position)
		}

		query.Count(&total).Order("sort_order ASC, id DESC").Offset(offset).Limit(pageSize).Find(&banners)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     banners,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// CreateBanner 创建轮播图
func CreateBanner(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var banner model.Banner
		if err := c.ShouldBindJSON(&banner); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		if err := db.Create(&banner).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "创建失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": banner, "message": "success"})
	}
}

// UpdateBanner 更新轮播图
func UpdateBanner(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var banner model.Banner
		if err := db.First(&banner, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "轮播图不存在"})
			return
		}

		var req struct {
			Title     string `json:"title"`
			Image     string `json:"image"`
			Link      string `json:"link"`
			LinkType  int8   `json:"link_type"`
			Position  string `json:"position"`
			SortOrder int    `json:"sort_order"`
			IsActive  bool   `json:"is_active"`
			StartAt   *int64 `json:"start_at"`
			EndAt     *int64 `json:"end_at"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&banner).Updates(map[string]interface{}{
			"title":      req.Title,
			"image":      req.Image,
			"link":       req.Link,
			"link_type":  req.LinkType,
			"position":   req.Position,
			"sort_order": req.SortOrder,
			"is_active":  req.IsActive,
			"start_at":   req.StartAt,
			"end_at":     req.EndAt,
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteBanner 删除轮播图
func DeleteBanner(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		if err := db.Delete(&model.Banner{}, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "删除失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetPublicBanners 公开接口 - 只返回已激活的轮播图
func GetPublicBanners(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var banners []model.Banner
		now := time.Now().Unix()
		db.Where("is_active = ? AND (start_at IS NULL OR start_at <= ?) AND (end_at IS NULL OR end_at >= ?)", true, now, now).
			Order("sort_order ASC, id DESC").
			Find(&banners)

		c.JSON(http.StatusOK, gin.H{
			"code":    0,
			"data":    banners,
			"message": "success",
		})
	}
}

// ==================== 话题管理 ====================

// GetTopicList 获取话题列表
func GetTopicList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")

		offset := (page - 1) * pageSize
		var topics []model.Topic
		var total int64

		query := db.Model(&model.Topic{})
		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("name LIKE ?", "%"+keyword+"%")
		}

		query.Count(&total).Order("sort_order ASC, id DESC").Offset(offset).Limit(pageSize).Find(&topics)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     topics,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// CreateTopic 创建话题
func CreateTopic(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var topic model.Topic
		if err := c.ShouldBindJSON(&topic); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		if err := db.Create(&topic).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "创建失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": topic, "message": "success"})
	}
}

// UpdateTopic 更新话题
func UpdateTopic(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var topic model.Topic
		if err := db.First(&topic, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "话题不存在"})
			return
		}

		var req struct {
			Name      string `json:"name"`
			Icon      string `json:"icon"`
			SortOrder int    `json:"sort_order"`
			IsActive  bool   `json:"is_active"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&topic).Updates(map[string]interface{}{
			"name":       req.Name,
			"icon":       req.Icon,
			"sort_order": req.SortOrder,
			"is_active":  req.IsActive,
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteTopic 删除话题
func DeleteTopic(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		if err := db.Delete(&model.Topic{}, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "删除失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// ==================== 举报管理 ====================

// GetReportList 获取举报列表
func GetReportList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		status, err := strconv.Atoi(c.DefaultQuery("status", "-1"))
		if err != nil {
			status = -1
		}

		offset := (page - 1) * pageSize
		var reports []struct {
			model.Report
			ReporterNickname string `json:"reporter_nickname"`
			HandlerNickname  string `json:"handler_nickname"`
		}
		var total int64

		query := db.Table("reports").
			Select("reports.*, r.nickname as reporter_nickname, h.nickname as handler_nickname").
			Joins("LEFT JOIN users r ON r.id = reports.reporter_id").
			Joins("LEFT JOIN users h ON h.id = reports.handler_id")

		if status >= 0 {
			query = query.Where("reports.status = ?", status)
		}

		query.Count(&total).Order("reports.id DESC").Offset(offset).Limit(pageSize).Find(&reports)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     reports,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// HandleReport 处理举报
func HandleReport(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var report model.Report
		if err := db.First(&report, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "举报记录不存在"})
			return
		}

		var req struct {
			Status    int8   `json:"status" binding:"required"` // 1已处理 2已驳回
			HandleNote string `json:"handle_note"`
			HandlerID uint   `json:"handler_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		if err := db.Model(&report).Updates(map[string]interface{}{
			"status":      req.Status,
			"handle_note": req.HandleNote,
			"handler_id":  req.HandlerID,
		}).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "处理失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "处理成功"})
	}
}

// ==================== 封禁管理 ====================

// GetBanList 获取封禁列表
func GetBanList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}

		offset := (page - 1) * pageSize
		var bans []struct {
			model.UserBan
			UserNickname    string `json:"user_nickname"`
			HandlerNickname string `json:"handler_nickname"`
		}
		var total int64

		query := db.Table("user_bans").
			Select("user_bans.*, u.nickname as user_nickname, h.nickname as handler_nickname").
			Joins("LEFT JOIN users u ON u.id = user_bans.user_id").
			Joins("LEFT JOIN users h ON h.id = user_bans.handler_id")

		query.Count(&total).Order("user_bans.id DESC").Offset(offset).Limit(pageSize).Find(&bans)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     bans,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// BanUser 封禁用户
func BanUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			UserID    uint   `json:"user_id" binding:"required"`
			Reason    string `json:"reason" binding:"required"`
			BanType   int8   `json:"ban_type" binding:"required"` // 1禁言 2封号
			ExpireAt  *int64 `json:"expire_at"`                   // null表示永久
			HandlerID uint   `json:"handler_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		// 检查用户是否存在
		var user model.User
		if err := db.First(&user, req.UserID).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "用户不存在"})
			return
		}

		ban := model.UserBan{
			UserID:    req.UserID,
			Reason:    req.Reason,
			BanType:   req.BanType,
			ExpireAt:  req.ExpireAt,
			HandlerID: req.HandlerID,
		}

		if err := db.Create(&ban).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "封禁失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": ban, "message": "封禁成功"})
	}
}

// UnbanUser 解封用户
func UnbanUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var ban model.UserBan
		if err := db.First(&ban, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "封禁记录不存在"})
			return
		}

		if err := db.Delete(&ban).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "解封失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "解封成功"})
	}
}

// ==================== 数据统计 ====================

// GetDashboardOverview 获取仪表盘概览数据（从数据库聚合真实数据）
func GetDashboardOverview(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		today := now.Format("2006-01-02")
		yesterday := now.AddDate(0, 0, -1).Format("2006-01-02")

		// 本周起始（周一）
		weekday := int(now.Weekday())
		if weekday == 0 {
			weekday = 7
		}
		weekStart := now.AddDate(0, 0, -(weekday - 1)).Format("2006-01-02")
		// 本月起始
		monthStart := now.Format("2006-01") + "-01"

		// 查询指定日期的统计数据
		queryDay := func(date string) map[string]interface{} {
			var stats model.DailyStats
			result := db.Where("date = ?", date).First(&stats)
			if result.Error != nil {
				// 表中无数据时从原始表实时聚合
				return queryDayFromSource(db, date)
			}
			return map[string]interface{}{
				"date":           stats.Date,
				"new_users":      stats.NewUsers,
				"active_users":   stats.ActiveUsers,
				"new_songs":      stats.NewSongs,
				"total_plays":    stats.TotalPlays,
				"new_posts":      stats.NewPosts,
				"new_orders":     stats.NewOrders,
				"revenue":        stats.Revenue,
				"ai_generations": stats.AIGenerations,
			}
		}

		// 查询日期范围的汇总数据
		queryRange := func(startDate, endDate string) map[string]interface{} {
			var stats model.DailyStats
			result := db.Where("date >= ? AND date <= ?", startDate, endDate).
				Select("COALESCE(SUM(new_users),0) as new_users, COALESCE(SUM(active_users),0) as active_users, COALESCE(SUM(new_songs),0) as new_songs, COALESCE(SUM(total_plays),0) as total_plays, COALESCE(SUM(new_posts),0) as new_posts, COALESCE(SUM(new_orders),0) as new_orders, COALESCE(SUM(revenue),0) as revenue, COALESCE(SUM(ai_generations),0) as ai_generations").
				Scan(&stats)
			if result.Error != nil || stats.NewUsers == 0 {
				// 表中无数据时从原始表实时聚合
				return queryRangeFromSource(db, startDate, endDate)
			}
			return map[string]interface{}{
				"new_users":      stats.NewUsers,
				"active_users":   stats.ActiveUsers,
				"new_songs":      stats.NewSongs,
				"total_plays":    stats.TotalPlays,
				"new_posts":      stats.NewPosts,
				"new_orders":     stats.NewOrders,
				"revenue":        stats.Revenue,
				"ai_generations": stats.AIGenerations,
			}
		}

		todayData := queryDay(today)
		yesterdayData := queryDay(yesterday)
		weekData := queryRange(weekStart, today)
		monthData := queryRange(monthStart, today)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"today":     todayData,
				"yesterday": yesterdayData,
				"week":      weekData,
				"month":     monthData,
			},
			"message": "success",
		})
	}
}

// queryDayFromSource 从原始表实时查询单日数据（daily_stats 无数据时的降级方案）
func queryDayFromSource(db *gorm.DB, date string) map[string]interface{} {
	startDate := date + " 00:00:00"
	endDate := date + " 23:59:59"

	var newUsers int64
	db.Model(&model.User{}).Where("created_at >= ? AND created_at <= ?", startDate, endDate).Count(&newUsers)

	var activeUsers int64
	db.Model(&model.PlayHistory{}).Where("created_at >= ? AND created_at <= ?", startDate, endDate).Distinct("user_id").Count(&activeUsers)

	var newSongs int64
	db.Model(&model.Song{}).Where("created_at >= ? AND created_at <= ?", startDate, endDate).Count(&newSongs)

	var totalPlays int64
	db.Model(&model.PlayHistory{}).Where("created_at >= ? AND created_at <= ?", startDate, endDate).Count(&totalPlays)

	var newPosts int64
	db.Model(&model.Post{}).Where("created_at >= ? AND created_at <= ?", startDate, endDate).Count(&newPosts)

	var newOrders int64
	db.Model(&model.MembershipOrder{}).Where("created_at >= ? AND created_at <= ? AND status = 1", startDate, endDate).Count(&newOrders)

	var revenue int64
	db.Model(&model.MembershipOrder{}).Where("created_at >= ? AND created_at <= ? AND status = 1", startDate, endDate).Select("COALESCE(SUM(amount),0)").Scan(&revenue)

	var aiGenerations int64
	db.Model(&model.AsyncTask{}).Where("created_at >= ? AND created_at <= ?", startDate, endDate).Count(&aiGenerations)

	return map[string]interface{}{
		"date":           date,
		"new_users":      newUsers,
		"active_users":   activeUsers,
		"new_songs":      newSongs,
		"total_plays":    totalPlays,
		"new_posts":      newPosts,
		"new_orders":     newOrders,
		"revenue":        revenue,
		"ai_generations": aiGenerations,
	}
}

// queryRangeFromSource 从原始表实时查询日期范围汇总数据
func queryRangeFromSource(db *gorm.DB, startDate, endDate string) map[string]interface{} {
	start := startDate + " 00:00:00"
	end := endDate + " 23:59:59"

	var newUsers int64
	db.Model(&model.User{}).Where("created_at >= ? AND created_at <= ?", start, end).Count(&newUsers)

	var activeUsers int64
	db.Model(&model.PlayHistory{}).Where("created_at >= ? AND created_at <= ?", start, end).Distinct("user_id").Count(&activeUsers)

	var newSongs int64
	db.Model(&model.Song{}).Where("created_at >= ? AND created_at <= ?", start, end).Count(&newSongs)

	var totalPlays int64
	db.Model(&model.PlayHistory{}).Where("created_at >= ? AND created_at <= ?", start, end).Count(&totalPlays)

	var newPosts int64
	db.Model(&model.Post{}).Where("created_at >= ? AND created_at <= ?", start, end).Count(&newPosts)

	var newOrders int64
	db.Model(&model.MembershipOrder{}).Where("created_at >= ? AND created_at <= ? AND status = 1", start, end).Count(&newOrders)

	var revenue int64
	db.Model(&model.MembershipOrder{}).Where("created_at >= ? AND created_at <= ? AND status = 1", start, end).Select("COALESCE(SUM(amount),0)").Scan(&revenue)

	var aiGenerations int64
	db.Model(&model.AsyncTask{}).Where("created_at >= ? AND created_at <= ?", start, end).Count(&aiGenerations)

	return map[string]interface{}{
		"new_users":      newUsers,
		"active_users":   activeUsers,
		"new_songs":      newSongs,
		"total_plays":    totalPlays,
		"new_posts":      newPosts,
		"new_orders":     newOrders,
		"revenue":        revenue,
		"ai_generations": aiGenerations,
	}
}

// GetDashboardTrend 获取趋势数据（最近30天，从 daily_stats 表读取真实数据）
func GetDashboardTrend(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 计算日期范围
		endDate := time.Now().Format("2006-01-02")
		startDate := time.Now().AddDate(0, 0, -29).Format("2006-01-02")

		// 一次查询获取所有数据
		var statsList []model.DailyStats
		db.Where("date >= ? AND date <= ?", startDate, endDate).Find(&statsList)

		// 构建日期到统计数据的映射
		statsMap := make(map[string]model.DailyStats, len(statsList))
		for _, stats := range statsList {
			statsMap[stats.Date] = stats
		}

		// 生成最近30天的趋势数据
		var trend []map[string]interface{}
		for i := 29; i >= 0; i-- {
			date := time.Now().AddDate(0, 0, -i).Format("2006-01-02")

			if stats, exists := statsMap[date]; exists {
				trend = append(trend, map[string]interface{}{
					"date":           stats.Date,
					"new_users":      stats.NewUsers,
					"active_users":   stats.ActiveUsers,
					"new_songs":      stats.NewSongs,
					"total_plays":    stats.TotalPlays,
					"new_posts":      stats.NewPosts,
					"new_orders":     stats.NewOrders,
					"revenue":        stats.Revenue,
					"ai_generations": stats.AIGenerations,
				})
			} else {
				// daily_stats 无数据时返回0值
				trend = append(trend, map[string]interface{}{
					"date":           date,
					"new_users":      0,
					"active_users":   0,
					"new_songs":      0,
					"total_plays":    0,
					"new_posts":      0,
					"new_orders":     0,
					"revenue":        0,
					"ai_generations": 0,
				})
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"trend": trend,
			},
			"message": "success",
		})
	}
}

// GetDashboardDistribution 获取分布数据
func GetDashboardDistribution(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 用户等级分布（模拟）
		userLevelDist := []map[string]interface{}{
			{"level": "普通用户", "count": 18976},
			{"level": "VIP用户", "count": 3456},
			{"level": "SVIP用户", "count": 789},
		}

		// 歌曲类型分布（模拟）
		songTypeDist := []map[string]interface{}{
			{"type": "流行", "count": 5678},
			{"type": "摇滚", "count": 2345},
			{"type": "民谣", "count": 1890},
			{"type": "电子", "count": 1567},
			{"type": "说唱", "count": 1234},
			{"type": "古典", "count": 890},
			{"type": "其他", "count": 678},
		}

		// 收入来源分布（模拟）
		revenueDist := []map[string]interface{}{
			{"source": "VIP订阅", "amount": 12345600},
			{"source": "音币充值", "amount": 8765400},
			{"source": "单曲购买", "amount": 3456700},
			{"source": "其他", "amount": 1234500},
		}

		// 地区分布（模拟）
		regionDist := []map[string]interface{}{
			{"region": "广东", "count": 3456},
			{"region": "北京", "count": 2890},
			{"region": "上海", "count": 2567},
			{"region": "浙江", "count": 1890},
			{"region": "江苏", "count": 1678},
			{"region": "四川", "count": 1456},
			{"region": "其他", "count": 8345},
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"user_level": userLevelDist,
				"song_type":  songTypeDist,
				"revenue":    revenueDist,
				"region":     regionDist,
			},
			"message": "success",
		})
	}
}

// ==================== 运营分析 ====================

// GetUserBehaviorData 获取用户行为分析数据
func GetUserBehaviorData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 模拟用户行为数据
		metricCards := []map[string]interface{}{
			{"title": "今日活跃用户", "value": "12,456", "color": "#409eff", "trend": "8.5%", "trendDir": "up"},
			{"title": "今日新增用户", "value": "856", "color": "#67c23a", "trend": "12.3%", "trendDir": "up"},
			{"title": "次日留存率", "value": "68.5%", "color": "#e6a23c", "trend": "2.1%", "trendDir": "down"},
			{"title": "人均使用时长", "value": "23.5分钟", "color": "#f56c6c", "trend": "5.2%", "trendDir": "up"},
		}

		featureRank := []map[string]interface{}{
			{"name": "AI作词", "usage_count": 45678, "percent": 85, "color": "#409eff", "trend": "12%", "trendDir": "up"},
			{"name": "AI作曲", "usage_count": 38921, "percent": 72, "color": "#67c23a", "trend": "8%", "trendDir": "up"},
			{"name": "一起听", "usage_count": 28456, "percent": 53, "color": "#e6a23c", "trend": "15%", "trendDir": "up"},
			{"name": "歌单创建", "usage_count": 21345, "percent": 40, "color": "#f56c6c", "trend": "3%", "trendDir": "down"},
			{"name": "动态发布", "usage_count": 18234, "percent": 34, "color": "#909399", "trend": "5%", "trendDir": "up"},
			{"name": "音色克隆", "usage_count": 12456, "percent": 23, "color": "#c0c4cc", "trend": "20%", "trendDir": "up"},
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"metric_cards": metricCards,
				"feature_rank": featureRank,
			},
			"message": "success",
		})
	}
}

// GetRetentionData 获取留存数据
func GetRetentionData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		retention := []map[string]interface{}{
			{"period": "次日留存", "rate": 68.5, "desc": "新用户次日回访比例"},
			{"period": "7日留存", "rate": 42.3, "desc": "新用户7日内回访比例"},
			{"period": "30日留存", "rate": 28.7, "desc": "新用户30日内回访比例"},
		}

		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"data":    retention,
			"message": "success",
		})
	}
}

// GetFunnelData 获取漏斗数据
func GetFunnelData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		funnel := []map[string]interface{}{
			{"name": "注册用户", "count": 10000, "rate": 100.0, "conversionRate": 45.2},
			{"name": "首次创作", "count": 4520, "rate": 45.2, "conversionRate": 62.5},
			{"name": "首次分享", "count": 2825, "rate": 28.3, "conversionRate": 35.8},
			{"name": "付费用户", "count": 1011, "rate": 10.1, "conversionRate": nil},
		}

		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"data":    funnel,
			"message": "success",
		})
	}
}

// GetRevenueData 获取营收分析数据
func GetRevenueData(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		metricCards := []map[string]interface{}{
			{"title": "今日营收", "value": "¥12,456", "color": "#e6a23c", "trend": "15.2%", "trendDir": "up"},
			{"title": "本月营收", "value": "¥356,789", "color": "#409eff", "trend": "8.7%", "trendDir": "up"},
			{"title": "付费率", "value": "14.7%", "color": "#67c23a", "trend": "2.1%", "trendDir": "up"},
			{"title": "ARPU值", "value": "¥8.56", "color": "#f56c6c", "trend": "1.5%", "trendDir": "down"},
		}

		revenueSources := []map[string]interface{}{
			{"name": "VIP订阅", "amount": 123456, "percent": 45, "color": "#409eff"},
			{"name": "音币充值", "amount": 87654, "percent": 32, "color": "#67c23a"},
			{"name": "单曲购买", "amount": 34567, "percent": 13, "color": "#e6a23c"},
			{"name": "其他", "amount": 27223, "percent": 10, "color": "#909399"},
		}

		packageRank := []map[string]interface{}{
			{"name": "VIP月度订阅", "type": "vip", "price": 28, "sales": 12345, "revenue": 345660, "percent": 28, "color": "#409eff"},
			{"name": "VIP年度订阅", "type": "vip", "price": 268, "sales": 5678, "revenue": 1521704, "percent": 35, "color": "#67c23a"},
			{"name": "100音币充值包", "type": "coin", "price": 10, "sales": 23456, "revenue": 234560, "percent": 18, "color": "#e6a23c"},
			{"name": "500音币充值包", "type": "coin", "price": 45, "sales": 8901, "revenue": 400545, "percent": 12, "color": "#f56c6c"},
			{"name": "VIP季度订阅", "type": "vip", "price": 78, "sales": 3456, "revenue": 269568, "percent": 7, "color": "#909399"},
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"metric_cards":    metricCards,
				"revenue_sources": revenueSources,
				"package_rank":    packageRank,
			},
			"message": "success",
		})
	}
}

// ==================== 告警管理 ====================

// GetAlertList 获取告警列表
func GetAlertList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		alertType := c.DefaultQuery("type", "")
		level, err := strconv.Atoi(c.DefaultQuery("level", "0"))
		if err != nil {
			level = 0
		}
		status, err := strconv.Atoi(c.DefaultQuery("status", "-1"))
		if err != nil {
			status = -1
		}

		offset := (page - 1) * pageSize
		var alerts []model.Alert
		var total int64

		query := db.Model(&model.Alert{})
		if alertType != "" {
			query = query.Where("type = ?", alertType)
		}
		if level > 0 {
			query = query.Where("level = ?", level)
		}
		if status >= 0 {
			query = query.Where("status = ?", status)
		}

		query.Count(&total).Order("id DESC").Offset(offset).Limit(pageSize).Find(&alerts)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     alerts,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// HandleAlert 标记告警已处理
func HandleAlert(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var alert model.Alert
		if err := db.First(&alert, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "告警记录不存在"})
			return
		}

		handlerID, _ := strconv.ParseUint(c.DefaultQuery("handler_id", "0"), 10, 32)
		if err := db.Model(&alert).Updates(map[string]interface{}{
			"status":     1,
			"handler_id": uint(handlerID),
		}).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "处理失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "处理成功"})
	}
}

// ==================== 实时监控 ====================

// GetMonitorStats 获取实时监控统计数据
func GetMonitorStats(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		now := time.Now()
		today := now.Format("2006-01-02")
		todayStart := today + " 00:00:00"
		todayEnd := today + " 23:59:59"

		// 今日AI生成次数
		var aiGenerations int64
		db.Model(&model.AsyncTask{}).Where("created_at >= ? AND created_at <= ?", todayStart, todayEnd).Count(&aiGenerations)

		// 今日新增用户
		var newUsers int64
		db.Model(&model.User{}).Where("created_at >= ? AND created_at <= ?", todayStart, todayEnd).Count(&newUsers)

		// 今日收入
		var revenue int64
		db.Model(&model.MembershipOrder{}).Where("created_at >= ? AND created_at <= ? AND status = 1", todayStart, todayEnd).Select("COALESCE(SUM(amount),0)").Scan(&revenue)

		// 当前在线用户数（最近15分钟有活动的用户）
		fifteenMinAgo := now.Add(-15 * time.Minute).Format("2006-01-02 15:04:05")
		var onlineUsers int64
		db.Model(&model.PlayHistory{}).Where("created_at >= ?", fifteenMinAgo).Distinct("user_id").Count(&onlineUsers)

		// 最近1小时请求量趋势（按5分钟分组）
		var requestTrend []map[string]interface{}
		for i := 11; i >= 0; i-- {
			start := now.Add(-time.Duration(i*5) * time.Minute)
			end := start.Add(5 * time.Minute)
			var count int64
			db.Model(&model.PlayHistory{}).Where("created_at >= ? AND created_at < ?", start.Format("2006-01-02 15:04:05"), end.Format("2006-01-02 15:04:05")).Count(&count)
			requestTrend = append(requestTrend, map[string]interface{}{
				"time":  start.Format("15:04"),
				"count": count,
			})
		}

		// 最近告警（取前10条）
		var recentAlerts []model.Alert
		db.Order("id DESC").Limit(10).Find(&recentAlerts)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"online_users":    onlineUsers,
				"ai_generations":  aiGenerations,
				"new_users":       newUsers,
				"revenue":         revenue,
				"request_trend":   requestTrend,
				"recent_alerts":   recentAlerts,
			},
			"message": "success",
		})
	}
}

// ==================== 配额配置 ====================

// GetQuotaConfig 获取配额配置
func GetQuotaConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var config model.QuotaConfig
		result := db.First(&config)
		if result.Error != nil {
			// 不存在则返回默认值
			config = model.QuotaConfig{
				NormalDailyAI:   3,
				VIPDailyAI:      20,
				SVIPDailyAI:     -1,
				NormalCoinPerAI: 5,
				VIPCoinPerAI:    2,
				SVIPCoinPerAI:   0,
				LoginRateLimit:    5,
				RegisterRateLimit: 3,
				AIRateLimit:       2,
			}
		}
		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"data":    config,
			"message": "success",
		})
	}
}

// SaveQuotaConfig 保存配额配置
func SaveQuotaConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			NormalDailyAI   int `json:"normal_daily_ai"`
			VIPDailyAI      int `json:"vip_daily_ai"`
			SVIPDailyAI     int `json:"svip_daily_ai"`
			NormalCoinPerAI int `json:"normal_coin_per_ai"`
			VIPCoinPerAI    int `json:"vip_coin_per_ai"`
			SVIPCoinPerAI   int `json:"svip_coin_per_ai"`
			LoginRateLimit    int `json:"login_rate_limit"`
			RegisterRateLimit int `json:"register_rate_limit"`
			AIRateLimit       int `json:"ai_rate_limit"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		var config model.QuotaConfig
		result := db.First(&config)
		if result.Error != nil {
			// 不存在则创建
			config = model.QuotaConfig{
				NormalDailyAI:   req.NormalDailyAI,
				VIPDailyAI:      req.VIPDailyAI,
				SVIPDailyAI:     req.SVIPDailyAI,
				NormalCoinPerAI: req.NormalCoinPerAI,
				VIPCoinPerAI:    req.VIPCoinPerAI,
				SVIPCoinPerAI:   req.SVIPCoinPerAI,
				LoginRateLimit:    req.LoginRateLimit,
				RegisterRateLimit: req.RegisterRateLimit,
				AIRateLimit:       req.AIRateLimit,
			}
			if err := db.Create(&config).Error; err != nil {
				c.JSON(http.StatusOK, gin.H{"code": 500, "message": "保存失败"})
				return
			}
		} else {
			// 更新
			if err := db.Model(&config).Updates(map[string]interface{}{
				"normal_daily_ai":   req.NormalDailyAI,
				"vip_daily_ai":      req.VIPDailyAI,
				"svip_daily_ai":     req.SVIPDailyAI,
				"normal_coin_per_ai": req.NormalCoinPerAI,
				"vip_coin_per_ai":    req.VIPCoinPerAI,
				"svip_coin_per_ai":   req.SVIPCoinPerAI,
				"login_rate_limit":    req.LoginRateLimit,
				"register_rate_limit": req.RegisterRateLimit,
				"ai_rate_limit":       req.AIRateLimit,
			}).Error; err != nil {
				c.JSON(http.StatusOK, gin.H{"code": 500, "message": "保存失败"})
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "保存成功"})
	}
}

// ==================== 听歌报告 ====================

// GetWeeklyReport 获取本周听歌报告
func GetWeeklyReport(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDVal, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "未登录"})
			return
		}
		userID := userIDVal.(uint)

		now := time.Now()
		// 计算本周起始（周一）
		weekday := int(now.Weekday())
		if weekday == 0 {
			weekday = 7
		}
		weekStart := time.Date(now.Year(), now.Month(), now.Day()-weekday+1, 0, 0, 0, 0, now.Location())
		weekEnd := weekStart.AddDate(0, 0, 7)

		// 查询本周播放历史
		var playHistories []model.PlayHistory
		db.Where("user_id = ? AND created_at >= ? AND created_at < ?", userID, weekStart, weekEnd).Find(&playHistories)

		totalPlays := int64(len(playHistories))

		// 统计播放时长（根据歌曲时长累加）
		var totalDuration int64
		songPlayCount := make(map[uint]int64)
		for _, ph := range playHistories {
			songPlayCount[ph.SongID]++
		}

		// 批量查询歌曲信息
		var songIDs []uint
		for songID := range songPlayCount {
			songIDs = append(songIDs, songID)
		}

		var songs []model.Song
		if len(songIDs) > 0 {
			db.Where("id IN ?", songIDs).Find(&songs)
		}

		// 计算总时长和最常听歌曲
		songMap := make(map[uint]model.Song)
		for _, song := range songs {
			songMap[song.ID] = song
			totalDuration += int64(song.Duration) * songPlayCount[song.ID]
		}

		// 找出最常听的歌曲
		var topSongID uint
		var topSongCount int64
		for songID, count := range songPlayCount {
			if count > topSongCount {
				topSongCount = count
				topSongID = songID
			}
		}

		type SongInfo struct {
			ID        uint   `json:"id"`
			Title     string `json:"title"`
			Singer    string `json:"singer"`
			Cover     string `json:"cover"`
			PlayCount int64  `json:"play_count"`
		}

		var topSong *SongInfo
		if topSongID > 0 {
			if song, ok := songMap[topSongID]; ok {
				topSong = &SongInfo{
					ID:        song.ID,
					Title:     song.Title,
					Singer:    song.Singer,
					Cover:     song.Cover,
					PlayCount: topSongCount,
				}
			}
		}

		// 统计最常听的风格
		styleCount := make(map[string]int64)
		for _, song := range songs {
			if song.Style != "" {
				styleCount[song.Style] += songPlayCount[song.ID]
			}
		}

		type StyleInfo struct {
			Style string `json:"style"`
			Count int64  `json:"count"`
		}

		var topStyles []StyleInfo
		for style, count := range styleCount {
			topStyles = append(topStyles, StyleInfo{Style: style, Count: count})
		}
		// 按播放次数排序
		for i := 0; i < len(topStyles); i++ {
			for j := i + 1; j < len(topStyles); j++ {
				if topStyles[j].Count > topStyles[i].Count {
					topStyles[i], topStyles[j] = topStyles[j], topStyles[i]
				}
			}
		}
		// 只返回前3个风格
		if len(topStyles) > 3 {
			topStyles = topStyles[:3]
		}

		// 统计每天的播放次数
		dailyPlays := make(map[string]int64)
		for _, ph := range playHistories {
			day := ph.CreatedAt.Format("2006-01-02")
			dailyPlays[day]++
		}

		type DailyPlay struct {
			Date  string `json:"date"`
			Count int64  `json:"count"`
		}

		var dailyPlayList []DailyPlay
		for i := 0; i < 7; i++ {
			day := weekStart.AddDate(0, 0, i)
			dateStr := day.Format("2006-01-02")
			dailyPlayList = append(dailyPlayList, DailyPlay{
				Date:  dateStr,
				Count: dailyPlays[dateStr],
			})
		}

		// 计算听歌天数
		listenDays := int64(len(dailyPlays))

		c.JSON(http.StatusOK, gin.H{
			"code": 0,
			"data": gin.H{
				"week_start":     weekStart.Format("2006-01-02"),
				"week_end":       weekEnd.Format("2006-01-02"),
				"total_plays":    totalPlays,
				"total_duration": totalDuration,
				"listen_days":    listenDays,
				"top_song":       topSong,
				"top_styles":     topStyles,
				"daily_plays":    dailyPlayList,
			},
			"message": "success",
		})
	}
}
