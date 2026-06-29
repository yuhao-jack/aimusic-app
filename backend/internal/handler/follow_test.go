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
	"github.com/yourname/aimusic-backend/pkg/utils"
)

func createFollowRouter() *gin.Engine {
	r := gin.Default()
	public := r.Group("/api/v1")
	{
		public.GET("/user/followers/:user_id", GetFollowers)
		public.GET("/user/following/:user_id", GetFollowing)
	}
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.POST("/user/follow/:target_id", FollowUser)
		private.POST("/user/unfollow/:target_id", UnfollowUser)
		private.GET("/user/follow/status", GetFollowStatus)
	}
	return r
}

func TestFollowUser(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createFollowRouter()

	// 创建两个测试用户
	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("normal follow", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/user/follow/%d", userID2), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, float64(0), resp["code"], "关注用户应成功")
	})

	t.Run("duplicate follow", func(t *testing.T) {
		// 先加一条关注记录
		follow := model.Follow{
			FollowerID:  userID1,
			FollowingID: userID2,
		}
		db.DB.Create(&follow)

		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/user/follow/%d", userID2), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "重复关注应失败")
	})

	t.Run("follow yourself", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/user/follow/%d", userID1), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "关注自己应失败")
	})

	t.Run("follow nonexistent user", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/follow/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "关注不存在的用户应失败")
	})

	t.Run("unauthorized follow", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/user/follow/%d", userID2), nil)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "未鉴权应失败")
	})
}

func TestUnfollowUser(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createFollowRouter()

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("normal unfollow", func(t *testing.T) {
		// 先创建关注关系
		follow := model.Follow{
			FollowerID:  userID1,
			FollowingID: userID2,
		}
		db.DB.Create(&follow)

		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/user/unfollow/%d", userID2), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, float64(0), resp["code"], "取消关注应成功")

		// 验证关注记录已删除
		var count int64
		db.DB.Unscoped().Model(&model.Follow{}).Where("follower_id = ? AND following_id = ?", userID1, userID2).Count(&count)
		assert.Equal(t, int64(0), count, "关注记录应已被硬删除")
	})

	t.Run("unfollow when not following", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/user/unfollow/%d", userID2), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "未关注时取关应失败")
	})
}

func TestGetFollowers(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createFollowRouter()

	userID1, _, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("get followers", func(t *testing.T) {
		// user1 关注 user2
		follow := model.Follow{FollowerID: userID1, FollowingID: userID2}
		db.DB.Create(&follow)

		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/user/followers/%d", userID2), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code, "获取粉丝列表应成功")
		assert.Equal(t, float64(1), resp.Data["total"], "应有1个粉丝")

		list := resp.Data["list"].([]interface{})
		assert.Len(t, list, 1)

		firstFollower := list[0].(map[string]interface{})
		assert.Equal(t, float64(userID1), firstFollower["user_id"])
	})

	t.Run("get followers of user with 0 followers", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/user/followers/%d", userID1), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code)
		assert.Equal(t, float64(0), resp.Data["total"], "应有0个粉丝")
	})

	t.Run("border case: invalid user_id", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/followers/abc", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "无效用户ID应失败")
	})
}

func TestGetFollowing(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createFollowRouter()

	userID1, _, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	t.Run("get following list", func(t *testing.T) {
		follow := model.Follow{FollowerID: userID1, FollowingID: userID2}
		db.DB.Create(&follow)

		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/user/following/%d", userID1), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code, "获取关注列表应成功")
		assert.Equal(t, float64(1), resp.Data["total"], "应有关注1人")

		list := resp.Data["list"].([]interface{})
		assert.Len(t, list, 1)

		firstFollowing := list[0].(map[string]interface{})
		assert.Equal(t, float64(userID2), firstFollowing["user_id"])
	})

	t.Run("get following list empty", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/user/following/%d", userID2), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code)
		assert.Equal(t, float64(0), resp.Data["total"], "应关注0人")
	})
}

func TestGetFollowStatus(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)
	defer CleanupTestDB()

	r := createFollowRouter()

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)
	// 创建第三个用户作为不关注的测试对象
	hashedPwd, _ := utils.HashPassword("123456")
	user3 := model.User{Username: "user3", Nickname: "User3", Email: "user3@example.com", Password: hashedPwd}
	db.DB.Create(&user3)

	t.Run("batch check follow status", func(t *testing.T) {
		// user1 关注 user2，但不关注 user3
		follow := model.Follow{FollowerID: userID1, FollowingID: userID2}
		db.DB.Create(&follow)

		req := httptest.NewRequest(http.MethodGet,
			fmt.Sprintf("/api/v1/user/follow/status?target_ids=%d,%d", userID2, user3.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp struct {
			Code int                    `json:"code"`
			Data map[string]interface{} `json:"data"`
		}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.Equal(t, 0, resp.Code, "查询关注状态应成功")

		statusMap := resp.Data["status"].(map[string]interface{})
		assert.Equal(t, true, statusMap[fmt.Sprintf("%d", userID2)], "已关注应返回true")
		assert.Equal(t, false, statusMap[fmt.Sprintf("%d", user3.ID)], "未关注应返回false")
	})

	t.Run("empty target_ids", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/follow/status", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "空target_ids应失败")
	})

	t.Run("unauthorized access", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet,
			fmt.Sprintf("/api/v1/user/follow/status?target_ids=%d,%d", userID2, user3.ID), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &resp)
		assert.NoError(t, err)
		assert.NotEqual(t, float64(0), resp["code"], "未鉴权应失败")
	})
}
