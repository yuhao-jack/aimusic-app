package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

func createHistoryRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.GET("/play-history", GetPlayHistory)
		private.POST("/play-history", AddPlayHistory)
		private.DELETE("/play-history", ClearPlayHistory)
		private.DELETE("/play-history/:id", RemovePlayHistoryItem)
	}
	return r
}

func TestGetPlayHistory(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createHistoryRouter()

	t.Run("has history", func(t *testing.T) {
		// create some songs
		song1 := CreateTestSong(userID)
		song2 := CreateTestSong(userID)

		// create play history records
		now := time.Now().UnixMilli()
		db.DB.Create(&model.PlayHistory{
			UserID:   userID,
			SongID:   song1.ID,
			PlayedAt: now,
		})
		db.DB.Create(&model.PlayHistory{
			UserID:   userID,
			SongID:   song2.ID,
			PlayedAt: now + 1000,
		})

		req := httptest.NewRequest(http.MethodGet, "/api/v1/play-history?page=1&page_size=20", nil)
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

	t.Run("empty history", func(t *testing.T) {
		err := SetupTestDB()
		assert.NoError(t, err)
		_, token2, _ := SetupAuthTest()
		r2 := createHistoryRouter()

		req := httptest.NewRequest(http.MethodGet, "/api/v1/play-history", nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		// data can be nil or a map with empty list
		if data, ok := resp["data"].(map[string]interface{}); ok {
			if list, ok := data["list"].([]interface{}); ok {
				assert.Equal(t, 0, len(list))
			}
		}
	})
}

func TestAddPlayHistory(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	song := CreateTestSong(userID)

	r := createHistoryRouter()

	t.Run("add new history", func(t *testing.T) {
		body := map[string]interface{}{
			"song_id": song.ID,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/play-history", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify in DB
		var count int64
		db.DB.Model(&model.PlayHistory{}).Where("user_id = ? AND song_id = ?", userID, song.ID).Count(&count)
		assert.True(t, count > 0)
	})

	t.Run("repeat add - creates new record", func(t *testing.T) {
		body := map[string]interface{}{
			"song_id": song.ID,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/play-history", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify there are now 2 records (AddPlayHistory doesn't deduplicate in DB)
		var count int64
		db.DB.Model(&model.PlayHistory{}).Where("user_id = ? AND song_id = ?", userID, song.ID).Count(&count)
		assert.Equal(t, int64(2), count)
	})

	t.Run("missing params", func(t *testing.T) {
		body := map[string]interface{}{}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/play-history", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

func TestClearPlayHistory(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	// add some history records
	song := CreateTestSong(userID)
	db.DB.Create(&model.PlayHistory{
		UserID:   userID,
		SongID:   song.ID,
		PlayedAt: time.Now().UnixMilli(),
	})

	r := createHistoryRouter()

	t.Run("clear all history", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/play-history", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify cleared
		var count int64
		db.DB.Model(&model.PlayHistory{}).Where("user_id = ?", userID).Count(&count)
		assert.Equal(t, int64(0), count)
	})
}

func TestRemovePlayHistoryItem(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	song := CreateTestSong(userID)

	// create a history record
	history := model.PlayHistory{
		UserID:   userID,
		SongID:   song.ID,
		PlayedAt: time.Now().UnixMilli(),
	}
	db.DB.Create(&history)

	r := createHistoryRouter()

	t.Run("remove existing item", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/play-history/%d", history.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify removed
		var count int64
		db.DB.Model(&model.PlayHistory{}).Where("id = ?", history.ID).Count(&count)
		assert.Equal(t, int64(0), count)
	})

	t.Run("remove non-existent item", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/play-history/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		// Delete with 0 rows affected still returns success (no error)
		assert.Equal(t, float64(0), resp["code"])
	})
}
