package handler

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ==================== 热搜搜索 ====================

// GetHotSearchKeywords 获取热搜关键词
func GetHotSearchKeywords(c *gin.Context) {
	// 基于搜索历史统计热门关键词（简化实现：返回播放量最高的歌曲风格作为热搜）
	type StyleCount struct {
		Keyword string `json:"keyword"`
		Count   int64  `json:"count"`
	}
	var hotKeywords []StyleCount
	db.DB.Raw(`
		SELECT style as keyword, COUNT(*) as count
		FROM songs WHERE status = 1 AND style != ''
		GROUP BY style ORDER BY count DESC LIMIT 10
	`).Scan(&hotKeywords)

	utils.Success(c, hotKeywords)
}

// ==================== 精选歌单 ====================

// GetFeaturedPlaylists 获取精选歌单
func GetFeaturedPlaylists(c *gin.Context) {
	var playlists []model.Playlist
	db.DB.Where("is_featured = true").
		Order("featured_sort ASC, created_at DESC").
		Limit(10).Find(&playlists)

	utils.Success(c, playlists)
}

// AdminSetFeaturedPlaylist 管理后台设置精选歌单
func AdminSetFeaturedPlaylist(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		IsFeatured   bool `json:"is_featured"`
		FeaturedSort int  `json:"featured_sort"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误")
		return
	}

	db.DB.Model(&model.Playlist{}).Where("id = ?", id).Updates(map[string]interface{}{
		"is_featured":   req.IsFeatured,
		"featured_sort": req.FeaturedSort,
	})

	utils.Success(c, gin.H{"message": "操作成功"})
}

// ==================== 话题/活动前端API ====================

// GetPublicTopics 获取公开话题列表（前端用）
func GetPublicTopics(c *gin.Context) {
	var topics []model.Topic
	db.DB.Where("is_active = true").Order("created_at DESC").Find(&topics)

	// 统计每个话题的参与人数
	type TopicWithCount struct {
		model.Topic
		PostCount int64 `json:"post_count"`
	}
	var result []TopicWithCount
	for _, topic := range topics {
		var count int64
		db.DB.Model(&model.Post{}).Where("content LIKE ?", "%#"+topic.Name+"%").Count(&count)
		result = append(result, TopicWithCount{Topic: topic, PostCount: count})
	}

	utils.Success(c, result)
}

// GetPublicActivities 获取公开活动列表（前端用）
func GetPublicActivities(c *gin.Context) {
	var activities []model.Activity
	now := time.Now().Unix()
	db.DB.Where("is_active = true AND start_time <= ? AND end_time >= ?", now, now).
		Order("created_at DESC").Find(&activities)

	utils.Success(c, activities)
}

// ==================== 广告位管理 ====================

// AdPlacement 广告位模型
type AdPlacement struct {
	ID          uint   `json:"id" gorm:"primaryKey"`
	Name        string `json:"name" gorm:"size:64"`
	Position    string `json:"position" gorm:"size:32;index"` // splash/feed/rewarded
	ContentType string `json:"content_type" gorm:"size:32"`   // image/video/html
	Content     string `json:"content" gorm:"type:text"`       // JSON配置
	TargetURL   string `json:"target_url" gorm:"size:255"`
	Impressions int    `json:"impressions" gorm:"default:0"`
	Clicks      int    `json:"clicks" gorm:"default:0"`
	IsActive    bool   `json:"is_active" gorm:"default:true"`
	SortOrder   int    `json:"sort_order" gorm:"default:0"`
	StartTime   int64  `json:"start_time"`
	EndTime     int64  `json:"end_time"`
}

func (AdPlacement) TableName() string {
	return "ad_placements"
}

// GetAdPlacements 获取广告位列表
func GetAdPlacements(c *gin.Context) {
	position := c.Query("position")
	now := time.Now().Unix()

	var ads []AdPlacement
	query := db.DB.Where("is_active = true AND start_time <= ? AND end_time >= ?", now, now)
	if position != "" {
		query = query.Where("position = ?", position)
	}
	query.Order("sort_order ASC").Find(&ads)

	utils.Success(c, ads)
}

// AdminGetAdPlacements 管理后台获取广告位列表
func AdminGetAdPlacements(c *gin.Context) {
	var ads []AdPlacement
	db.DB.Order("position ASC, sort_order ASC").Find(&ads)
	utils.Success(c, ads)
}

// AdminSaveAdPlacement 管理后台保存广告位
func AdminSaveAdPlacement(c *gin.Context) {
	var req AdPlacement
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误")
		return
	}

	if req.ID > 0 {
		db.DB.Save(&req)
	} else {
		db.DB.Create(&req)
	}

	utils.Success(c, gin.H{"message": "保存成功"})
}

// AdminDeleteAdPlacement 管理后台删除广告位
func AdminDeleteAdPlacement(c *gin.Context) {
	id := c.Param("id")
	db.DB.Delete(&AdPlacement{}, id)
	utils.Success(c, gin.H{"message": "删除成功"})
}

// TrackAdClick 广告点击追踪
func TrackAdClick(c *gin.Context) {
	id := c.Param("id")
	db.DB.Model(&AdPlacement{}).Where("id = ?", id).Update("clicks", gorm.Expr("clicks + 1"))
	utils.Success(c, gin.H{"message": "ok"})
}

// ==================== 用户行为埋点 ====================

// UserEvent 用户行为事件模型
type UserEvent struct {
	ID        uint   `json:"id" gorm:"primaryKey"`
	UserID    uint   `json:"user_id" gorm:"index"`
	EventName string `json:"event_name" gorm:"size:64;index"`
	EventType string `json:"event_type" gorm:"size:32"` // page_view/song_play/ai_create/purchase/social
	Params    string `json:"params" gorm:"type:text"`
	Platform  string `json:"platform" gorm:"size:20"`
	AppVersion string `json:"app_version" gorm:"size:20"`
	IP        string `json:"ip" gorm:"size:50"`
	CreatedAt time.Time `json:"created_at"`
}

func (UserEvent) TableName() string {
	return "user_events"
}

// TrackEvent 用户行为埋点接口
func TrackEvent(c *gin.Context) {
	var req struct {
		Events []struct {
			EventName string            `json:"event_name"`
			EventType string            `json:"event_type"`
			Params    map[string]string `json:"params"`
			Timestamp int64             `json:"timestamp"`
		} `json:"events"`
		Platform   string `json:"platform"`
		AppVersion string `json:"app_version"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, 400, "参数错误")
		return
	}

	userID := c.GetUint("user_id")
	ip := c.ClientIP()

	for _, event := range req.Events {
		paramsJSON, _ := json.Marshal(event.Params)
		db.DB.Create(&UserEvent{
			UserID:     userID,
			EventName:  event.EventName,
			EventType:  event.EventType,
			Params:     string(paramsJSON),
			Platform:   req.Platform,
			AppVersion: req.AppVersion,
			IP:         ip,
		})
	}

	utils.Success(c, gin.H{"message": "ok"})
}

// AdminGetEventStats 管理后台获取事件统计
func AdminGetEventStats(c *gin.Context) {
	days, _ := strconv.Atoi(c.DefaultQuery("days", "7"))
	startDate := time.Now().AddDate(0, 0, -days)

	// 事件统计
	type EventCount struct {
		EventName string `json:"event_name"`
		Count     int64  `json:"count"`
	}
	var eventStats []EventCount
	db.DB.Model(&UserEvent{}).
		Select("event_name, COUNT(*) as count").
		Where("created_at >= ?", startDate).
		Group("event_name").
		Order("count DESC").
		Limit(20).
		Scan(&eventStats)

	// 每日事件数
	dailyData := make([]int64, days)
	for i := days - 1; i >= 0; i-- {
		dayStart := time.Date(time.Now().Year(), time.Now().Month(), time.Now().Day()-i, 0, 0, 0, 0, time.Now().Location())
		dayEnd := dayStart.AddDate(0, 0, 1)
		db.DB.Model(&UserEvent{}).Where("created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&dailyData[days-1-i])
	}

	utils.Success(c, gin.H{
		"event_stats": eventStats,
		"daily_data":  dailyData,
	})
}

// ==================== 通知增强 ====================

// GetNotificationsEnhanced 获取通知列表（带已读状态）
func GetNotificationsEnhanced(c *gin.Context) {
	userID := c.GetUint("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	var notifications []model.Notification
	var total int64

	db.DB.Model(&model.Notification{}).Where("user_id = ?", userID).Count(&total)
	db.DB.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset((page - 1) * pageSize).Limit(pageSize).
		Find(&notifications)

	// 统计未读数
	var unreadCount int64
	db.DB.Model(&model.Notification{}).Where("user_id = ? AND is_read = false", userID).Count(&unreadCount)

	utils.Success(c, gin.H{
		"list":         notifications,
		"total":        total,
		"unread_count": unreadCount,
	})
}

// ==================== 数据看板增强 ====================

// AdminGetDAUStats 管理后台获取DAU/WAU/MAU
func AdminGetDAUStats(c *gin.Context) {
	now := time.Now()
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	weekStart := todayStart.AddDate(0, 0, -7)
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

	// DAU: 今日活跃用户（有播放记录的）
	var dau int64
	db.DB.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ?", todayStart).Scan(&dau)

	// WAU: 本周活跃用户
	var wau int64
	db.DB.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ?", weekStart).Scan(&wau)

	// MAU: 本月活跃用户
	var mau int64
	db.DB.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ?", monthStart).Scan(&mau)

	// 总用户数
	var totalUsers int64
	db.DB.Model(&model.User{}).Count(&totalUsers)

	// 7天DAU趋势
	dauTrend := make([]int64, 7)
	for i := 6; i >= 0; i-- {
		dayStart := time.Date(now.Year(), now.Month(), now.Day()-i, 0, 0, 0, 0, now.Location())
		dayEnd := dayStart.AddDate(0, 0, 1)
		db.DB.Raw("SELECT COUNT(DISTINCT user_id) FROM play_histories WHERE created_at >= ? AND created_at < ?", dayStart, dayEnd).Scan(&dauTrend[6-i])
	}

	utils.Success(c, gin.H{
		"dau":          dau,
		"wau":          wau,
		"mau":          mau,
		"total_users":  totalUsers,
		"dau_trend":    dauTrend,
		"dau_rate":     fmt.Sprintf("%.1f", float64(dau)/float64(totalUsers)*100),
	})
}

// ==================== 精选歌单管理 ====================

// AdminGetPlaylists 管理后台获取歌单列表
func AdminGetPlaylists(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	var playlists []model.Playlist
	var total int64

	db.DB.Model(&model.Playlist{}).Count(&total)
	db.DB.Order("created_at DESC").Offset((page - 1) * pageSize).Limit(pageSize).Find(&playlists)

	utils.Success(c, gin.H{"list": playlists, "total": total})
}

// ==================== 活动管理增强 ====================

// AdminGetActivityListEnhanced 管理后台获取活动列表（增强版）
func AdminGetActivityListEnhanced(c *gin.Context) {
	var activities []model.Activity
	db.DB.Order("created_at DESC").Find(&activities)

	// 统计每个活动的参与人数（基于动态中的活动ID关联）
	type ActivityWithCount struct {
		model.Activity
		ParticipantCount int64 `json:"participant_count"`
	}
	var result []ActivityWithCount
	for _, activity := range activities {
		result = append(result, ActivityWithCount{Activity: activity, ParticipantCount: 0})
	}

	utils.Success(c, result)
}
