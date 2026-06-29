package handler

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// CreateNotification 创建通知（辅助函数）
func CreateNotification(userID, actorID uint, actionType, targetType string, targetID uint, content string) {
	// 不给自己的操作发送通知
	if userID == actorID {
		return
	}

	notification := model.Notification{
		UserID:     userID,
		ActorID:    actorID,
		ActionType: actionType,
		TargetType: targetType,
		TargetID:   targetID,
		Content:    content,
		IsRead:     0,
	}
	if err := db.DB.Create(&notification).Error; err != nil {
		log.Printf("创建通知失败: user_id=%d, actor_id=%d, err=%v", userID, actorID, err)
	}
}

// GetNotifications 获取通知列表（分页，最新在前）
// GET /api/v1/notifications (需要鉴权)
func GetNotifications(c *gin.Context) {
	userID := c.GetUint("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	offset := (page - 1) * pageSize

	var notifications []model.Notification
	var total int64

	db.DB.Model(&model.Notification{}).Where("user_id = ?", userID).Count(&total)
	err := db.DB.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).Find(&notifications).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取通知失败")
		return
	}

	// 获取触发者的用户信息
	var actorIDs []uint
	for _, n := range notifications {
		actorIDs = append(actorIDs, n.ActorID)
	}

	type ActorInfo struct {
		ID       uint   `json:"id"`
		Nickname string `json:"nickname"`
		Avatar   string `json:"avatar"`
	}

	var actorMap = make(map[uint]ActorInfo)
	if len(actorIDs) > 0 {
		var users []model.User
		db.DB.Select("id, nickname, avatar").Where("id IN ?", actorIDs).Find(&users)
		for _, u := range users {
			actorMap[u.ID] = ActorInfo{
				ID:       u.ID,
				Nickname: u.Nickname,
				Avatar:   u.Avatar,
			}
		}
	}

	type NotificationWithActor struct {
		model.Notification
		Actor ActorInfo `json:"actor"`
	}

	var result []NotificationWithActor
	for _, n := range notifications {
		actor := actorMap[n.ActorID]
		result = append(result, NotificationWithActor{
			Notification: n,
			Actor:        actor,
		})
	}

	utils.Success(c, gin.H{
		"list":      result,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// MarkNotificationRead 标记单条通知已读
// PUT /api/v1/notifications/:id/read (需要鉴权)
func MarkNotificationRead(c *gin.Context) {
	userID := c.GetUint("user_id")
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "通知ID错误")
		return
	}

	var notification model.Notification
	if err := db.DB.Where("id = ? AND user_id = ?", id, userID).First(&notification).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "通知不存在")
		return
	}

	if err := db.DB.Model(&notification).Update("is_read", 1).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "标记已读失败")
		return
	}

	utils.Success(c, nil)
}

// MarkAllRead 全部标记已读
// PUT /api/v1/notifications/read-all (需要鉴权)
func MarkAllRead(c *gin.Context) {
	userID := c.GetUint("user_id")

	if err := db.DB.Model(&model.Notification{}).Where("user_id = ? AND is_read = 0", userID).Update("is_read", 1).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "标记全部已读失败")
		return
	}

	utils.Success(c, nil)
}

// GetUnreadCount 获取未读通知数量
// GET /api/v1/notifications/unread-count (需要鉴权)
func GetUnreadCount(c *gin.Context) {
	userID := c.GetUint("user_id")

	var count int64
	db.DB.Model(&model.Notification{}).Where("user_id = ? AND is_read = 0", userID).Count(&count)

	utils.Success(c, gin.H{
		"unread_count": count,
	})
}
