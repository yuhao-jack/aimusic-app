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

func createVoiceRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.GET("/voice-clones", GetVoiceClones)
		private.GET("/voice-clones/:id", GetVoiceClone)
		private.POST("/voice-clones", CreateVoiceClone)
		private.PUT("/voice-clones/:id", UpdateVoiceClone)
		private.DELETE("/voice-clones/:id", DeleteVoiceClone)
	}
	return r
}

func TestGetVoiceClones(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createVoiceRouter()

	t.Run("empty list", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/voice-clones", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 0, len(list))
	})

	t.Run("has voice clones", func(t *testing.T) {
		// create some voice clones
		db.DB.Create(&model.VoiceClone{
			UserID:    userID,
			Name:      "Voice 1",
			VoiceType: "cloned",
			Status:    "completed",
		})
		db.DB.Create(&model.VoiceClone{
			UserID:    userID,
			Name:      "Voice 2",
			VoiceType: "original",
			Status:    "completed",
		})

		req := httptest.NewRequest(http.MethodGet, "/api/v1/voice-clones", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 2, len(list))
		assert.Equal(t, float64(2), data["total"])
	})
}

func TestGetVoiceClone(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	// create a voice clone
	voice := model.VoiceClone{
		UserID:    userID,
		Name:      "My Voice",
		VoiceType: "cloned",
		Status:    "completed",
	}
	db.DB.Create(&voice)

	r := createVoiceRouter()

	t.Run("existing voice", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/voice-clones/%d", voice.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, "My Voice", data["name"])
		assert.Equal(t, "completed", data["status"])
	})

	t.Run("non-existent voice", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/voice-clones/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "音色不存在")
	})

	t.Run("other user's voice", func(t *testing.T) {
		_, token2, _ := SetupSecondUser()

		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/voice-clones/%d", voice.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		// should not find because voice belongs to userID, not token2's user
		assert.Equal(t, float64(404), resp["code"])
	})
}

func TestCreateVoiceClone(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createVoiceRouter()

	t.Run("create voice clone", func(t *testing.T) {
		body := map[string]interface{}{
			"name":        "New Voice",
			"description": "My new voice clone",
			"audio_url":   "https://example.com/audio.wav",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/voice-clones", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, "New Voice", data["name"])
		assert.Equal(t, "pending", data["status"])

		// verify in DB
		var count int64
		db.DB.Model(&model.VoiceClone{}).Where("user_id = ? AND name = ?", userID, "New Voice").Count(&count)
		assert.Equal(t, int64(1), count)
	})

	t.Run("missing required params", func(t *testing.T) {
		body := map[string]interface{}{
			"description": "Missing name and audio_url",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/voice-clones", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

func TestUpdateVoiceClone(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	voice := model.VoiceClone{
		UserID:      userID,
		Name:        "Original Name",
		Description: "Original description",
		VoiceType:   "cloned",
		Status:      "completed",
	}
	db.DB.Create(&voice)

	r := createVoiceRouter()

	t.Run("update name", func(t *testing.T) {
		body := map[string]interface{}{
			"name": "Updated Name",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, fmt.Sprintf("/api/v1/voice-clones/%d", voice.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.VoiceClone
		db.DB.First(&updated, voice.ID)
		assert.Equal(t, "Updated Name", updated.Name)
	})

	t.Run("update description", func(t *testing.T) {
		body := map[string]interface{}{
			"description": "Updated description",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, fmt.Sprintf("/api/v1/voice-clones/%d", voice.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.VoiceClone
		db.DB.First(&updated, voice.ID)
		assert.Equal(t, "Updated description", updated.Description)
	})

	t.Run("update non-existent", func(t *testing.T) {
		body := map[string]interface{}{
			"name": "Nope",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/voice-clones/99999", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "音色不存在")
	})
}

func TestDeleteVoiceClone(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	voice := model.VoiceClone{
		UserID:    userID,
		Name:      "To Delete",
		VoiceType: "cloned",
		Status:    "completed",
	}
	db.DB.Create(&voice)

	r := createVoiceRouter()

	t.Run("delete existing voice", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/voice-clones/%d", voice.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify deleted
		var count int64
		db.DB.Model(&model.VoiceClone{}).Where("id = ?", voice.ID).Count(&count)
		assert.Equal(t, int64(0), count)
	})

	t.Run("delete non-existent", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/voice-clones/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "音色不存在")
	})

	t.Run("delete other's voice", func(t *testing.T) {
		voice2 := model.VoiceClone{
			UserID:    userID,
			Name:      "Another",
			VoiceType: "cloned",
			Status:    "completed",
		}
		db.DB.Create(&voice2)

		_, token2, _ := SetupSecondUser()
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/voice-clones/%d", voice2.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		// The delete query is scoped to user, so it returns 404 since no match
		assert.Equal(t, float64(404), resp["code"])
	})
}
