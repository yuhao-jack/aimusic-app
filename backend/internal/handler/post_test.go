package handler

import (
	"bytes"
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

func createPostRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		post := private.Group("/post")
		{
			post.POST("/create", CreatePost)
			post.GET("/list", GetPostList)
			post.GET("/:post_id", GetPostDetail)
			post.DELETE("/:post_id", DeletePost)
			post.POST("/:post_id/like", LikePost)
			post.POST("/:post_id/comment", AddPostComment)
			post.GET("/:post_id/comments", GetPostComments)
			post.DELETE("/comment/:comment_id", DeletePostComment)
		}
		// user posts
		private.GET("/user/:user_id/posts", GetUserPostList)
	}
	return r
}

func TestCreatePost(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	_, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createPostRouter()

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int
		checkMsg string
	}{
		{
			name: "text only post",
			body: map[string]interface{}{
				"content": "This is a test post",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "post with images",
			body: map[string]interface{}{
				"content": "Post with images",
				"images":  []string{"https://example.com/img1.jpg", "https://example.com/img2.jpg"},
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "empty content",
			body: map[string]interface{}{
				"content": "",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/post/create", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			req.Header.Set("Authorization", "Bearer "+token)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)
			assert.Contains(t, resp["msg"].(string), tt.checkMsg)
		})
	}
}

func TestGetPostList(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	// create multiple posts
	for i := 0; i < 5; i++ {
		createTestPost(userID, fmt.Sprintf("Post content %d", i))
	}

	r := createPostRouter()

	t.Run("paginated list", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/post/list?page=1&page_size=3", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		total := data["total"].(float64)
		assert.Equal(t, 3, len(list))
		assert.Equal(t, float64(5), total)
	})

	t.Run("empty list", func(t *testing.T) {
		err := SetupTestDB()
		assert.NoError(t, err)
		_, token2, _ := SetupAuthTest()
		r2 := createPostRouter()

		req := httptest.NewRequest(http.MethodGet, "/api/v1/post/list?page=1&page_size=10", nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 0, len(list))
	})
}

func TestGetUserPostList(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	userID2, _, err := SetupSecondUser()
	assert.NoError(t, err)

	// user 1 creates posts
	for i := 0; i < 3; i++ {
		createTestPost(userID1, fmt.Sprintf("User1 post %d", i))
	}
	// user 2 creates posts
	for i := 0; i < 2; i++ {
		createTestPost(userID2, fmt.Sprintf("User2 post %d", i))
	}

	r := createPostRouter()

	t.Run("own posts", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/user/%d/posts", userID1), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 3, len(list))
	})

	t.Run("other user's posts", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/user/%d/posts", userID2), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 2, len(list))
	})
}

func TestGetPostDetail(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	post := createTestPost(userID, "Detail post content")

	r := createPostRouter()

	t.Run("existing post", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/post/%d", post.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("non-existent post", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/post/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "动态不存在")
	})
}

func TestDeletePost(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID1, token1, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	post := createTestPost(userID1, "Post to delete")

	r := createPostRouter()

	t.Run("delete own post", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/post/%d", post.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("delete other's post - forbidden", func(t *testing.T) {
		post2 := createTestPost(userID1, "Another post")

		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/post/%d", post2.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(403), resp["code"])
		assert.Contains(t, resp["msg"], "只能删除自己")
	})

	t.Run("delete non-existent post", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/post/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
	})
}

func TestLikePost(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	post := createTestPost(userID, "Post for like testing")

	r := createPostRouter()

	t.Run("like post", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/post/%d/like", post.ID), nil)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		// data should have liked: true
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, true, data["liked"])

		// verify DB
		var updated model.Post
		db.DB.First(&updated, post.ID)
		assert.Equal(t, 1, updated.LikeCount)
	})

	t.Run("unlike post", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/post/%d/like", post.ID), nil)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, false, data["liked"])

		var updated model.Post
		db.DB.First(&updated, post.ID)
		assert.Equal(t, 0, updated.LikeCount)
	})

	t.Run("like by different user", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/post/%d/like", post.ID), nil)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, true, data["liked"])

		var updated model.Post
		db.DB.First(&updated, post.ID)
		assert.Equal(t, 1, updated.LikeCount)
	})
}

func TestAddPostComment(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	post := createTestPost(userID, "Post for comments")

	r := createPostRouter()

	t.Run("add comment normal", func(t *testing.T) {
		body := map[string]interface{}{
			"content": "Nice post!",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/post/%d/comment", post.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify comment count
		var updated model.Post
		db.DB.First(&updated, post.ID)
		assert.Equal(t, 1, updated.CommentCount)
	})

	t.Run("nested reply", func(t *testing.T) {
		// first add a parent comment
		var parentComment model.PostComment
		db.DB.Where("post_id = ?", post.ID).First(&parentComment)

		body := map[string]interface{}{
			"content":   "Reply to comment",
			"parent_id": parentComment.ID,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/post/%d/comment", post.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("empty content", func(t *testing.T) {
		body := map[string]interface{}{
			"content": "",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/post/%d/comment", post.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

func TestGetPostComments(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	post := createTestPost(userID, "Post for comment listing")

	r := createPostRouter()

	t.Run("has comments", func(t *testing.T) {
		// add 2 comments directly
		db.DB.Create(&model.PostComment{
			PostID:  post.ID,
			UserID:  userID,
			Content: "Comment 1",
		})
		db.DB.Create(&model.PostComment{
			PostID:  post.ID,
			UserID:  userID,
			Content: "Comment 2",
		})

		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/post/%d/comments", post.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 2, len(list))
	})

	t.Run("no comments", func(t *testing.T) {
		post2 := createTestPost(userID, "Post with no comments")

		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/post/%d/comments", post2.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		total := data["total"].(float64)
		assert.Equal(t, 0, len(list))
		assert.Equal(t, float64(0), total)
	})
}

func TestDeletePostComment(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	post := createTestPost(userID, "Post for comment delete")

	r := createPostRouter()

	t.Run("delete own comment", func(t *testing.T) {
		// create a comment
		comment := model.PostComment{
			PostID:  post.ID,
			UserID:  userID,
			Content: "My comment",
		}
		db.DB.Create(&comment)

		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/post/comment/%d", comment.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("delete other's comment - forbidden", func(t *testing.T) {
		comment := model.PostComment{
			PostID:  post.ID,
			UserID:  userID,
			Content: "Another comment",
		}
		db.DB.Create(&comment)

		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/post/comment/%d", comment.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(403), resp["code"])
		assert.Contains(t, resp["msg"], "只能删除自己")
	})

	t.Run("delete non-existent comment", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/post/comment/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "评论不存在")
	})
}
