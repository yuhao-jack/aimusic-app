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

// optionalAuthMiddleware extracts user_id from the Authorization header if present,
// but does not reject requests without it. This matches the real app's behavior
// where GetPlaylistDetail works for public playlists without login.
func optionalAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" {
			// testParseToken expects the full "Bearer xxx" format
			claims, err := testParseToken(authHeader)
			if err == nil {
				c.Set("user_id", claims.UserID)
				c.Set("phone", claims.Phone)
			}
		}
		c.Next()
	}
}

func createPlaylistRouter() *gin.Engine {
	r := gin.Default()
	public := r.Group("/api/v1")
	{
		public.GET("/playlist/recommend", GetRecommendPlaylists)
		public.GET("/playlist/:playlist_id", optionalAuthMiddleware(), GetPlaylistDetail)
	}
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.GET("/playlist/list", GetUserPlaylists)
		private.POST("/playlist/create", CreatePlaylist)
		private.PUT("/playlist/:playlist_id", UpdatePlaylist)
		private.DELETE("/playlist/:playlist_id", DeletePlaylist)
		private.POST("/playlist/:playlist_id/add", AddSongToPlaylist)
		private.DELETE("/playlist/:playlist_id/song/:song_id", RemoveSongFromPlaylist)
		private.POST("/playlist/:playlist_id/like", LikePlaylist)
	}
	return r
}

func TestGetUserPlaylists(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createPlaylistRouter()

	t.Run("has playlists", func(t *testing.T) {
		db.DB.Create(&model.Playlist{
			UserID: userID,
			Name:   "My Playlist 1",
		})
		db.DB.Create(&model.Playlist{
			UserID: userID,
			Name:   "My Playlist 2",
		})

		req := httptest.NewRequest(http.MethodGet, "/api/v1/playlist/list", nil)
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

	t.Run("empty playlists", func(t *testing.T) {
		_, token2, _ := SetupSecondUser()

		req := httptest.NewRequest(http.MethodGet, "/api/v1/playlist/list", nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		list := data["list"].([]interface{})
		assert.Equal(t, 0, len(list))
	})
}

func TestCreatePlaylist(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createPlaylistRouter()

	t.Run("create playlist", func(t *testing.T) {
		body := map[string]interface{}{
			"name":        "My New Playlist",
			"description": "A cool playlist",
			"is_public":   1,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/playlist/create", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, "My New Playlist", data["name"])

		var count int64
		db.DB.Model(&model.Playlist{}).Where("user_id = ? AND name = ?", userID, "My New Playlist").Count(&count)
		assert.Equal(t, int64(1), count)
	})

	t.Run("missing name", func(t *testing.T) {
		body := map[string]interface{}{
			"description": "No name",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/playlist/create", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

func TestUpdatePlaylist(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	playlist := model.Playlist{
		UserID:      userID,
		Name:        "Old Name",
		Description: "Old description",
		IsPublic:    0,
	}
	db.DB.Create(&playlist)

	r := createPlaylistRouter()

	t.Run("update name and description", func(t *testing.T) {
		body := map[string]interface{}{
			"name":        "New Name",
			"description": "New description",
			"is_public":   1,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, fmt.Sprintf("/api/v1/playlist/%d", playlist.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.Playlist
		db.DB.First(&updated, playlist.ID)
		assert.Equal(t, "New Name", updated.Name)
		assert.Equal(t, "New description", updated.Description)
		assert.Equal(t, int8(1), updated.IsPublic)
	})

	t.Run("update non-existent", func(t *testing.T) {
		body := map[string]interface{}{
			"name": "Nope",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/playlist/99999", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "歌单不存在")
	})

	t.Run("update other's playlist - forbidden", func(t *testing.T) {
		_, token2, _ := SetupSecondUser()

		body := map[string]interface{}{
			"name": "Hacked Name",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, fmt.Sprintf("/api/v1/playlist/%d", playlist.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(403), resp["code"])
		assert.Contains(t, resp["msg"], "无权修改")
	})
}

func TestDeletePlaylist(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	playlist := model.Playlist{
		UserID: userID,
		Name:   "To Delete",
	}
	db.DB.Create(&playlist)

	// Add some songs and likes for cascade delete test
	song := CreateTestSong(userID)
	db.DB.Create(&model.PlaylistSong{
		PlaylistID: playlist.ID,
		SongID:     song.ID,
	})
	db.DB.Create(&model.PlaylistLike{
		PlaylistID: playlist.ID,
		UserID:     userID,
	})

	r := createPlaylistRouter()

	t.Run("delete own playlist", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/playlist/%d", playlist.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		// verify cascade deleted
		var count int64
		db.DB.Model(&model.Playlist{}).Where("id = ?", playlist.ID).Count(&count)
		assert.Equal(t, int64(0), count)

		var songCount int64
		db.DB.Model(&model.PlaylistSong{}).Where("playlist_id = ?", playlist.ID).Count(&songCount)
		assert.Equal(t, int64(0), songCount)

		var likeCount int64
		db.DB.Model(&model.PlaylistLike{}).Where("playlist_id = ?", playlist.ID).Count(&likeCount)
		assert.Equal(t, int64(0), likeCount)
	})

	t.Run("delete non-existent", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, "/api/v1/playlist/99999", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
	})

	t.Run("delete other's playlist - forbidden", func(t *testing.T) {
		p2 := model.Playlist{
			UserID: userID,
			Name:   "Another",
		}
		db.DB.Create(&p2)

		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/playlist/%d", p2.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(403), resp["code"])
		assert.Contains(t, resp["msg"], "无权删除")
	})
}

func TestAddSongToPlaylist(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	playlist := model.Playlist{
		UserID: userID,
		Name:   "My Playlist",
	}
	db.DB.Create(&playlist)
	song := CreateTestSong(userID)

	r := createPlaylistRouter()

	t.Run("add song to own playlist", func(t *testing.T) {
		body := map[string]interface{}{
			"song_id": song.ID,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/playlist/%d/add", playlist.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.Playlist
		db.DB.First(&updated, playlist.ID)
		assert.Equal(t, 1, updated.SongCount)
	})

	t.Run("duplicate song", func(t *testing.T) {
		body := map[string]interface{}{
			"song_id": song.ID,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/playlist/%d/add", playlist.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(400), resp["code"])
		assert.Contains(t, resp["msg"], "歌曲已在歌单中")
	})

	t.Run("add to other's playlist - forbidden", func(t *testing.T) {
		body := map[string]interface{}{
			"song_id": song.ID,
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/playlist/%d/add", playlist.ID), bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(403), resp["code"])
		assert.Contains(t, resp["msg"], "无权修改")
	})
}

func TestRemoveSongFromPlaylist(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	playlist := model.Playlist{
		UserID:    userID,
		Name:      "My Playlist",
		SongCount: 2,
	}
	db.DB.Create(&playlist)
	song1 := CreateTestSong(userID)
	song2 := CreateTestSong(userID)

	db.DB.Create(&model.PlaylistSong{
		PlaylistID: playlist.ID,
		SongID:     song1.ID,
	})
	db.DB.Create(&model.PlaylistSong{
		PlaylistID: playlist.ID,
		SongID:     song2.ID,
	})

	r := createPlaylistRouter()

	t.Run("remove song from own playlist", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/playlist/%d/song/%d", playlist.ID, song1.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.Playlist
		db.DB.First(&updated, playlist.ID)
		assert.Equal(t, 1, updated.SongCount)
	})

	t.Run("remove from other's playlist - forbidden", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, fmt.Sprintf("/api/v1/playlist/%d/song/%d", playlist.ID, song2.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(403), resp["code"])
	})
}

func TestLikePlaylist(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	playlist := model.Playlist{
		UserID: userID,
		Name:   "Liked Playlist",
	}
	db.DB.Create(&playlist)

	r := createPlaylistRouter()

	t.Run("like playlist", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/playlist/%d/like", playlist.ID), nil)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, true, data["liked"])

		var updated model.Playlist
		db.DB.First(&updated, playlist.ID)
		assert.Equal(t, 1, updated.LikeCount)
	})

	t.Run("unlike playlist", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/playlist/%d/like", playlist.ID), nil)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, false, data["liked"])

		var updated model.Playlist
		db.DB.First(&updated, playlist.ID)
		assert.Equal(t, 0, updated.LikeCount)
	})

	t.Run("like by someone else", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, fmt.Sprintf("/api/v1/playlist/%d/like", playlist.ID), nil)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, true, data["liked"])

		var updated model.Playlist
		db.DB.First(&updated, playlist.ID)
		assert.Equal(t, 1, updated.LikeCount)
	})
}

func TestGetPlaylistDetail(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	publicPlaylist := model.Playlist{
		UserID:   userID,
		Name:     "Public Playlist",
		IsPublic: 1,
	}
	db.DB.Create(&publicPlaylist)

	privatePlaylist := model.Playlist{
		UserID:   userID,
		Name:     "Private Playlist",
		IsPublic: 0,
	}
	db.DB.Create(&privatePlaylist)

	r := createPlaylistRouter()

	t.Run("public playlist no auth required", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/playlist/%d", publicPlaylist.ID), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("private playlist without auth", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/playlist/%d", privatePlaylist.ID), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "不可访问")
	})

	t.Run("private playlist with owner auth", func(t *testing.T) {
		// Use private router with authMiddleware to set user_id
		r2 := gin.Default()
		privateGroup := r2.Group("/api/v1")
		privateGroup.Use(authMiddleware())
		{
			privateGroup.GET("/playlist/owner/:playlist_id", GetPlaylistDetail)
		}

		req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/v1/playlist/owner/%d", privatePlaylist.ID), nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		t.Logf("private playlist owner auth response: %v", string(w.Body.Bytes()))
		assert.Equal(t, float64(0), resp["code"], "Owner should access their private playlist")
		t.Logf("resp[data] type: %T, value: %v", resp["data"], resp["data"])
		data, dataOk := resp["data"].(map[string]interface{})
		if assert.True(t, dataOk, "data should be a map") {
			pl, plOk := data["playlist"].(map[string]interface{})
			if assert.True(t, plOk, "data.playlist should be a map") {
				assert.Equal(t, "Private Playlist", pl["name"])
			}
		}
	})

	t.Run("non-existent playlist", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/playlist/99999", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(404), resp["code"])
		assert.Contains(t, resp["msg"], "歌单不存在")
	})
}

func TestGetRecommendPlaylists(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	r := createPlaylistRouter()

	t.Run("has recommendations", func(t *testing.T) {
		db.DB.Create(&model.Playlist{
			UserID:    1,
			Name:      "Pop Hits",
			IsPublic:  1,
			LikeCount: 100,
		})
		db.DB.Create(&model.Playlist{
			UserID:    1,
			Name:      "Rock Classics",
			IsPublic:  1,
			LikeCount: 50,
		})

		req := httptest.NewRequest(http.MethodGet, "/api/v1/playlist/recommend", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 2, len(data))
	})

	t.Run("empty recommendations", func(t *testing.T) {
		err := SetupTestDB()
		assert.NoError(t, err)
		r2 := createPlaylistRouter()

		req := httptest.NewRequest(http.MethodGet, "/api/v1/playlist/recommend", nil)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 0, len(data))
	})
}
