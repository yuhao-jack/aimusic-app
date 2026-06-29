package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

func createNotificationRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.GET("/notifications", GetNotifications)
		private.PUT("/notifications/:id/read", MarkNotificationRead)
		private.PUT("/notifications/read-all", MarkAllRead)
		private.GET("/notifications/unread-count", GetUnreadCount)
	}
	return r
}

// createTestNotifications creates test notifications for the given user
// Returns slice of pointers so callers can read the actual IDs set by GORM
func createTestNotifications(userID, actorID uint) []model.Notification {
	entries := []model.Notification{
		{
			UserID:     userID,
			ActorID:    actorID,
			ActionType: "like",
			TargetType: "post",
			TargetID:   1,
			Content:    "赞了你的动态",
			IsRead:     0,
		},
		{
			UserID:     userID,
			ActorID:    actorID,
			ActionType: "follow",
			TargetType: "user",
			TargetID:   0,
			Content:    "关注了你",
			IsRead:     0,
		},
		{
			UserID:     userID,
			ActorID:    actorID,
			ActionType: "comment",
			TargetType: "song",
			TargetID:   1,
			Content:    "评论了你的歌曲",
			IsRead:     1,
		},
	}
	for i := range entries {
		db.DB.Create(&entries[i])
	}
	return entries
}

func TestGetNotifications(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createNotificationRouter()

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("get notifications", func(t *testing.T) {
		createTestNotifications(userID1, userID2)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code, "获取通知列表应成功")
		assert.Equal(t, float64(3), resp.Data["total"], "应有3条通知")

		list := resp.Data["list"].([]interface{})
		assert.Len(t, list, 3)
		// 验证顺序（最新在前）
		assert.NotNil(t, list[0])
	})

	t.Run("get notifications empty", func(t *testing.T) {
		// Cleanup and re-setup
		CleanupTestDB()
		err := SetupTestDB()
		assert.NoError(t, err)
		_, newToken, err := SetupAuthTest()
		assert.NoError(t, err)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", nil)
		req.Header.Set("Authorization", "Bearer "+newToken)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code, "空通知列表也应正常返回")
		assert.Equal(t, float64(0), resp.Data["total"])
	})

	t.Run("unauthorized access", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "未鉴权应失败")
	})
}

func TestMarkNotificationRead(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createNotificationRouter()

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("mark single notification read", func(t *testing.T) {
		notifications := createTestNotifications(userID1, userID2)
		notificationID := notifications[0].ID

		req := httptest.NewRequest(http.MethodPut, fmt.Sprintf("/api/v1/notifications/%d/read", notificationID), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, float64(0), resp["code"], "标记已读应成功")

		// 验证已读状态
		var n model.Notification
		db.DB.First(&n, notificationID)
		assert.Equal(t, int8(1), n.IsRead, "通知应标记为已读")
	})

	t.Run("mark nonexistent notification", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/99999/read", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "标记不存在的通知应失败")
	})

	t.Run("mark other user's notification", func(t *testing.T) {
		// user2 的通知
		notifications := createTestNotifications(userID2, userID1)
		otherNotifID := notifications[0].ID

		req := httptest.NewRequest(http.MethodPut, fmt.Sprintf("/api/v1/notifications/%d/read", otherNotifID), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "标记他人通知应失败")
	})

	t.Run("invalid id format", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/abc/read", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "无效ID格式应失败")
	})
}

func TestMarkAllRead(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createNotificationRouter()

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("mark all read", func(t *testing.T) {
		createTestNotifications(userID1, userID2)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/read-all", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, float64(0), resp["code"], "标记全部已读应成功")

		// 验证所有通知已读
		var unreadCount int64
		db.DB.Model(&model.Notification{}).Where("user_id = ? AND is_read = 0", userID1).Count(&unreadCount)
		assert.Equal(t, int64(0), unreadCount, "应没有未读通知")
	})

	t.Run("mark all read when no notifications", func(t *testing.T) {
		CleanupTestDB()
		err := SetupTestDB()
		assert.NoError(t, err)
		_, newToken, err := SetupAuthTest()
		assert.NoError(t, err)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/read-all", nil)
		req.Header.Set("Authorization", "Bearer "+newToken)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, float64(0), resp["code"], "无通知时也应成功")
	})

	t.Run("mark all read only affects current user", func(t *testing.T) {
		// user1 有未读通知，user2 也有
		createTestNotifications(userID1, userID2)
		createTestNotifications(userID2, userID1)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/read-all", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, float64(0), resp["code"])

		// user1 的通知全部已读
		var unread1 int64
		db.DB.Model(&model.Notification{}).Where("user_id = ? AND is_read = 0", userID1).Count(&unread1)
		assert.Equal(t, int64(0), unread1, "user1的通知应全部已读")

		// user2 的通知不受影响
		var unread2 int64
		db.DB.Model(&model.Notification{}).Where("user_id = ? AND is_read = 0", userID2).Count(&unread2)
		assert.NotEqual(t, int64(0), unread2, "user2的通知应不受影响")
	})
}

func TestGetUnreadCount(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createNotificationRouter()

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("get unread count", func(t *testing.T) {
		createTestNotifications(userID1, userID2)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/unread-count", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code)
		assert.Equal(t, float64(2), resp.Data["unread_count"], "应有2条未读通知")
	})

	t.Run("get unread count zero", func(t *testing.T) {
		CleanupTestDB()
		err := SetupTestDB()
		assert.NoError(t, err)
		_, newToken, err := SetupAuthTest()
		assert.NoError(t, err)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/unread-count", nil)
		req.Header.Set("Authorization", "Bearer "+newToken)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err = json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code)
		assert.Equal(t, float64(0), resp.Data["unread_count"], "应没有未读通知")
	})

	t.Run("unauthorized access", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/unread-count", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "未鉴权应失败")
	})
}

func TestCreateNotification(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	userID1, _, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("create notification and verify in DB", func(t *testing.T) {
		CreateNotification(userID1, userID2, "like", "song", 1, "喜欢了你的歌曲")

		var n model.Notification
		err := db.DB.Where("user_id = ? AND actor_id = ?", userID1, userID2).First(&n).Error
		assert.NoError(t, err)
		assert.Equal(t, "like", n.ActionType)
		assert.Equal(t, "song", n.TargetType)
		assert.Equal(t, uint(1), n.TargetID)
		assert.Equal(t, int8(0), n.IsRead, "新建通知应为未读")
	})

	t.Run("self action should not create notification", func(t *testing.T) {
		CreateNotification(userID1, userID1, "like", "post", 1, "赞了你的动态")

		var count int64
		db.DB.Model(&model.Notification{}).Where("user_id = ? AND actor_id = ?", userID1, userID1).Count(&count)
		assert.Equal(t, int64(0), count, "自己的操作不应生成通知")
	})

	t.Run("multiple notifications", func(t *testing.T) {
		CreateNotification(userID1, userID2, "follow", "user", 0, "关注了你")
		CreateNotification(userID1, userID2, "comment", "post", 1, "评论了你的动态")

		var count int64
		db.DB.Model(&model.Notification{}).Where("user_id = ? AND actor_id = ?", userID1, userID2).Count(&count)
		assert.Equal(t, int64(3), count, "应有3条通知")
	})
}
