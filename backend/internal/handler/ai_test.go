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
	"github.com/yourname/aimusic-backend/pkg/ai"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// mockAIService implements ai.AIService for testing
type mockAIService struct {
	generateLyricFn func(prompt, style, emotion, lang string) (string, error)
	optimizeLyricFn func(lyric, style string) (string, error)
	generateSongFn  func(lyric, style, emotion, voiceID string, duration int, title string) (string, error)
	getProgressFn   func(taskID string) (*ai.SongGenerationProgress, error)
}

func (m *mockAIService) GenerateLyric(prompt, style, emotion, lang string) (string, error) {
	if m.generateLyricFn != nil {
		return m.generateLyricFn(prompt, style, emotion, lang)
	}
	return "Generated lyric for " + prompt, nil
}

func (m *mockAIService) OptimizeLyric(lyric, style string) (string, error) {
	if m.optimizeLyricFn != nil {
		return m.optimizeLyricFn(lyric, style)
	}
	return "Optimized: " + lyric, nil
}

func (m *mockAIService) GenerateSong(lyric, style, emotion, voiceID string, duration int, title string) (string, error) {
	if m.generateSongFn != nil {
		return m.generateSongFn(lyric, style, emotion, voiceID, duration, title)
	}
	return "task_123", nil
}

func (m *mockAIService) GetSongGenerationProgress(taskID string) (*ai.SongGenerationProgress, error) {
	if m.getProgressFn != nil {
		return m.getProgressFn(taskID)
	}
	return &ai.SongGenerationProgress{
		Status:   "completed",
		Progress: 100,
		AudioURL: "https://example.com/audio.mp3",
	}, nil
}

func createAIRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.POST("/ai/lyric/generate", GenerateLyric)
		private.POST("/ai/lyric/optimize", OptimizeLyric)
		private.POST("/ai/song/generate", GenerateSong)
		private.GET("/ai/task/:task_id/progress", GetTaskProgress)
	}
	return r
}

func TestGenerateLyric(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	// 给测试用户添加音币
	db.DB.Model(&model.User{}).Where("id = ?", userID).Update("coins", 100)

	// 初始化mock AI service
	mock := &mockAIService{
		generateLyricFn: func(prompt, style, emotion, lang string) (string, error) {
			return "这是关于爱情的一首流行歌词...", nil
		},
	}
	InitAIService(mock)

	r := createAIRouter()

	t.Run("normal generation", func(t *testing.T) {
		body := map[string]interface{}{
			"prompt":  "爱情",
			"style":   "流行",
			"emotion": "开心",
			"lang":    "zh",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/lyric/generate", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Contains(t, data["lyric"].(string), "爱情")
		assert.Equal(t, "爱情", data["prompt"])
	})

	t.Run("empty prompt", func(t *testing.T) {
		body := map[string]interface{}{
			"style":   "流行",
			"emotion": "开心",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/lyric/generate", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})

	t.Run("no auth token", func(t *testing.T) {
		body := map[string]interface{}{
			"prompt":  "test",
			"style":   "pop",
			"emotion": "happy",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/lyric/generate", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, 401, w.Code)
	})
}

func TestOptimizeLyric(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	_, token, err := SetupAuthTest()
	assert.NoError(t, err)

	mock := &mockAIService{
		optimizeLyricFn: func(lyric, style string) (string, error) {
			return "优化后的歌词：" + lyric, nil
		},
	}
	InitAIService(mock)

	r := createAIRouter()

	t.Run("normal optimization", func(t *testing.T) {
		body := map[string]interface{}{
			"lyric": "这是原始歌词内容",
			"style": "流行",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/lyric/optimize", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, "这是原始歌词内容", data["original_lyric"])
		assert.NotEmpty(t, data["optimized_lyric"])
	})

	t.Run("empty lyric", func(t *testing.T) {
		body := map[string]interface{}{
			"style": "流行",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/lyric/optimize", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

func TestGenerateSong(t *testing.T) {
	t.Skip("GenerateSong requires Redis which is not available in unit tests")

	err := SetupTestDB()
	assert.NoError(t, err)

	_, token, err := SetupAuthTest()
	assert.NoError(t, err)

	mock := &mockAIService{
		generateSongFn: func(lyric, style, emotion, voiceID string, duration int, title string) (string, error) {
			return "mock_task_id_456", nil
		},
	}
	InitAIService(mock)

	r := createAIRouter()

	t.Run("normal song generation", func(t *testing.T) {
		body := map[string]interface{}{
			"lyric":   "测试歌词",
			"style":   "流行",
			"emotion": "开心",
			"title":   "测试歌曲",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/song/generate", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.NotEmpty(t, data["task_id"])
		assert.Contains(t, data["message"].(string), "已提交")
	})

	t.Run("missing params", func(t *testing.T) {
		body := map[string]interface{}{
			"lyric": "test",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/song/generate", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

func TestGetTaskProgress(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	mock := &mockAIService{}
	InitAIService(mock)

	// 创建DB中的任务
	task := model.AsyncTask{
		TaskType: 1,
		UserID:   userID,
		Status:   model.TaskStatusRunning,
		Progress: 50,
	}
	db.DB.Create(&task)

	// 另一个用户的任务（不可访问）
	otherTask := model.AsyncTask{
		TaskType: 1,
		UserID:   999,
		Status:   model.TaskStatusRunning,
		Progress: 30,
	}
	db.DB.Create(&otherTask)

	r := createAIRouter()

	t.Run("existing task", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/ai/task/%d/progress", task.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, float64(task.ID), data["task_id"])
		assert.Equal(t, float64(50), data["progress"])
	})

	t.Run("non-existent task", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/ai/task/99999/progress", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "任务不存在")
	})

	t.Run("other user's task", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/ai/task/%d/progress", otherTask.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		// otherTask's user_id != userID, so should not find
		assert.Equal(t, float64(404), resp["code"])
	})
}

func TestGetTaskProgressNoAuth(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	r := gin.Default()
	r.GET("/api/v1/ai/task/:task_id/progress", GetTaskProgress)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ai/task/1/progress", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	// Without auth, c.GetUint("user_id") returns 0, so DB query scoped to user_id=0 won't find anything
	assert.Equal(t, float64(404), resp["code"])
}
