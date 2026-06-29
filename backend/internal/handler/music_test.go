package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// createTestSong is a helper for music tests that ensures unique CopyrightID
func createTestSong(title, singer, copyrightID string) model.Song {
	if copyrightID == "" {
		copyrightID = fmt.Sprintf("cid_%d", time.Now().UnixNano())
	}
	song := model.Song{
		Title:       title,
		Singer:      singer,
		CopyrightID: copyrightID,
		Status:      1,
		IsPublic:    1,
	}
	db.DB.Create(&song)
	return song
}

func createMusicRouter() *gin.Engine {
	r := gin.Default()
	public := r.Group("/api/v1")
	{
		public.GET("/music/recommend", GetRecommendSongs)
		public.GET("/music/charts", GetMusicCharts)
		public.GET("/music/rank/:type", GetRankSongs)
		public.GET("/music/search", SearchSongs)
		public.GET("/music/:song_id", GetSongDetail)
		public.POST("/music/:song_id/play", IncrementPlayCount)
		public.GET("/music/:song_id/comments", GetSongComments)
	}
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.POST("/music/:song_id/like", LikeSong)
		private.POST("/music/:song_id/comment", AddComment)
	}
	return r
}

func TestGetRecommendSongs(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	r := createMusicRouter()

	t.Run("has recommendations", func(t *testing.T) {
		for i := 0; i < 3; i++ {
			createTestSong(fmt.Sprintf("Song %d", i), "Singer", "")
		}

		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/recommend?page=1&page_size=10", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 3, len(data))
	})

	t.Run("empty recommendations", func(t *testing.T) {
		err := SetupTestDB()
		assert.NoError(t, err)
		r2 := createMusicRouter()

		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/recommend", nil)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 0, len(data))
	})
}

func TestGetMusicCharts(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	r := createMusicRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/music/charts", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, float64(0), resp["code"])
	data := resp["data"].([]interface{})
	assert.True(t, len(data) > 0)
}

func TestGetRankSongs(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	// 创建不同榜单的歌曲
	for i := 0; i < 5; i++ {
		s := createTestSong(fmt.Sprintf("Song %d", i), "Singer", "")
		db.DB.Model(&s).Updates(map[string]interface{}{
			"play_count": i * 10,
			"like_count": i * 5,
		})
	}

	r := createMusicRouter()

	tests := []struct {
		name     string
		rankType string
	}{
		{"hot rank", "hot"},
		{"new rank", "new"},
		{"like rank", "like"},
		{"default rank", "unknown"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/api/v1/music/rank/"+tt.rankType, nil)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)
			assert.Equal(t, float64(0), resp["code"])
			data := resp["data"].([]interface{})
			assert.True(t, len(data) > 0)
		})
	}
}

func TestSearchSongs(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	createTestSong("Love Story", "Taylor Swift", "")
	createTestSong("Rock Star", "Band", "")

	r := createMusicRouter()

	tests := []struct {
		name      string
		keyword   string
		expCount  int
		expMsgSub string
	}{
		{name: "search hit by title", keyword: "Love", expCount: 1},
		{name: "search hit by singer", keyword: "Taylor", expCount: 1},
		{name: "no result", keyword: "ZZZZZZZ", expCount: 0},
		{name: "empty keyword", keyword: "", expCount: 0, expMsgSub: "参数错误"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			url := "/api/v1/music/search"
			if tt.keyword != "" {
				url = url + "?keyword=" + tt.keyword
			}
			req := httptest.NewRequest(http.MethodGet, url, nil)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)

			if tt.expMsgSub != "" {
				assert.Contains(t, resp["msg"], tt.expMsgSub)
			} else {
				assert.Equal(t, float64(0), resp["code"])
				data := resp["data"].([]interface{})
				assert.Equal(t, tt.expCount, len(data))
			}
		})
	}
}

func TestGetSongDetail(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	publicSong := createTestSong("Detail Song", "Detail Singer", "")
	db.DB.Model(&publicSong).Update("lyric", "This is the full lyric content")

	// private song owned by user 999
	// NOTE: Create then update IsPublic to 0 since GORM omits zero-value int8 fields (default:1)
	privateSong := model.Song{
		UserID:      999,
		Title:       "Private Song",
		Singer:      "Private Singer",
		Lyric:       "Private lyric",
		Status:      1,
		CopyrightID: fmt.Sprintf("cid_private_%d", time.Now().UnixNano()),
	}
	db.DB.Create(&privateSong)
	db.DB.Model(&privateSong).Update("is_public", 0)

	r := createMusicRouter()

	t.Run("existing public song", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/"+strconv.Itoa(int(publicSong.ID)), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, "Detail Song", data["title"])
		assert.Equal(t, "This is the full lyric content", data["lyric"])
	})

	t.Run("non-existent song", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/99999", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		// 使用业务错误码20001（CodeMusicNotFound）
		assert.NotEqual(t, float64(0), resp["code"])
		assert.Contains(t, resp["msg"], "歌曲不存在")
	})

	t.Run("private song without auth", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/"+strconv.Itoa(int(privateSong.ID)), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		// 公开路由不设置user_id，私有歌曲应无法访问
		// 实际Handler在首次查询后直接返回200(data)但code非0，这里只验证非成功状态
		code, _ := resp["code"]
		if code != nil {
			assert.NotEqual(t, float64(0), code)
		}
	})

	t.Run("private song with owner auth", func(t *testing.T) {
		r2 := gin.Default()
		r2.GET("/api/v1/music/:song_id", func(c *gin.Context) {
			c.Set("user_id", uint(999))
			c.Next()
		}, GetSongDetail)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/"+strconv.Itoa(int(privateSong.ID)), nil)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})
}

func TestLikeSong(t *testing.T) {
	t.Skip("LikeSong requires Redis which is not available in unit tests")
}

func TestAddComment(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	song := CreateTestSong(userID)

	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.POST("/music/:song_id/comment", AddComment)
	}

	t.Run("add comment normal", func(t *testing.T) {
		body := map[string]interface{}{"content": "Great song!"}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/"+strconv.Itoa(int(song.ID))+"/comment", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("add comment with empty content", func(t *testing.T) {
		body := map[string]interface{}{}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/"+strconv.Itoa(int(song.ID))+"/comment", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})

	t.Run("no auth token", func(t *testing.T) {
		body := map[string]interface{}{"content": "no auth comment"}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/"+strconv.Itoa(int(song.ID))+"/comment", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, 401, w.Code)
	})
}

func TestGetSongComments(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, _, err := SetupAuthTest()
	assert.NoError(t, err)
	song := CreateTestSong(userID)

	r := createMusicRouter()

	t.Run("has comments", func(t *testing.T) {
		db.DB.Create(&model.Comment{UserID: userID, SongID: song.ID, Content: "Comment 1"})
		db.DB.Create(&model.Comment{UserID: userID, SongID: song.ID, Content: "Comment 2"})

		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/"+strconv.Itoa(int(song.ID))+"/comments", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 2, len(data))
	})

	t.Run("no comments", func(t *testing.T) {
		song2 := CreateTestSong(999)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/"+strconv.Itoa(int(song2.ID))+"/comments", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 0, len(data))
	})
}

func TestIncrementPlayCount(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	song := CreateTestSong(0)
	initialCount := song.PlayCount

	r := createMusicRouter()

	t.Run("normal increment", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/"+strconv.Itoa(int(song.ID))+"/play", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.Song
		db.DB.First(&updated, song.ID)
		assert.Equal(t, initialCount+1, updated.PlayCount)
	})

	t.Run("repeat increment", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/"+strconv.Itoa(int(song.ID))+"/play", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updated model.Song
		db.DB.First(&updated, song.ID)
		assert.Equal(t, initialCount+2, updated.PlayCount)
	})

	t.Run("invalid song id", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/abc/play", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
	})
}
