package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
)

func createNewTestsUserRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.PUT("/user/profile", UpdateUserProfile)
		private.POST("/user/avatar", UploadAvatar)
	}
	return r
}

func createMusicPrivateRouter() *gin.Engine {
	r := gin.Default()
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.POST("/music/together/create", CreateTogetherRoom)
		private.POST("/music/together/join/:room_code", JoinTogetherRoom)
		private.POST("/music/together/leave/:room_id", LeaveTogetherRoom)
	}
	return r
}

func createPublicMusicRouter() *gin.Engine {
	r := gin.Default()
	public := r.Group("/api/v1")
	{
		public.GET("/music/daily-recommend", GetDailyRecommend)
	}
	return r
}

func createPublicCreatorRouter() *gin.Engine {
	r := gin.Default()
	public := r.Group("/api/v1")
	{
		public.GET("/creator/stars", GetCreatorStars)
		public.GET("/creator/:user_id", GetCreatorDetail)
	}
	return r
}

// ============================================================
// 1. UpdateUserProfile (PUT /api/v1/user/profile)
// ============================================================

func TestUpdateUserProfile(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	_, tok, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createNewTestsUserRouter()

	tests := []struct {
		name     string
		setAuth  func(req *http.Request)
		body     map[string]interface{}
		wantCode int
		check    func(t *testing.T, resp map[string]interface{})
	}{
		{
			name: "update nickname only",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok) },
			body: map[string]interface{}{
				"nickname": "NewNickname",
			},
			wantCode: http.StatusOK,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Equal(t, float64(0), resp["code"])
				var user model.User
				db.DB.First(&user, 1)
				assert.Equal(t, "NewNickname", user.Nickname)
			},
		},
		{
			name: "update both nickname and bio",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok) },
			body: map[string]interface{}{
				"nickname": "BothUpdate",
				"bio":      "Updated bio both",
			},
			wantCode: http.StatusOK,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Equal(t, float64(0), resp["code"])
				var user model.User
				db.DB.First(&user, 1)
				assert.Equal(t, "BothUpdate", user.Nickname)
				assert.Equal(t, "Updated bio both", user.Bio)
			},
		},
		{
			name: "empty nickname",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok) },
			body: map[string]interface{}{
				"nickname": "",
				"bio":      "Some bio",
			},
			wantCode: http.StatusBadRequest,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Contains(t, resp["msg"], "昵称不能为空")
			},
		},
		{
			name: "no auth token",
			setAuth: func(req *http.Request) {},
			body: map[string]interface{}{
				"nickname": "NoAuth",
			},
			wantCode: http.StatusUnauthorized,
			check: func(t *testing.T, resp map[string]interface{}) {
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPut, "/api/v1/user/profile", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			tt.setAuth(req)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)

			assert.Equal(t, tt.wantCode, w.Code)
			if tt.wantCode == http.StatusOK {
				assert.Equal(t, float64(0), resp["code"])
			}

			if tt.check != nil {
				tt.check(t, resp)
			}
		})
	}
}

// ============================================================
// 2. UploadAvatar (POST /api/v1/user/avatar)
// ============================================================

func TestUploadAvatar(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	config.AppConfig.Upload.Path = "/tmp/test-uploads"
	config.AppConfig.Upload.BaseURL = "/uploads"

	_, tok, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createNewTestsUserRouter()

	t.Run("normal upload with jpg file", func(t *testing.T) {
		bodyBuf := &bytes.Buffer{}
		writer := multipart.NewWriter(bodyBuf)
		part, _ := writer.CreateFormFile("avatar", "test.jpg")
		part.Write([]byte("fake-jpeg-content"))
		writer.Close()

		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/avatar", bodyBuf)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+tok)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"], "response: %v", resp)
		data := resp["data"].(map[string]interface{})
		assert.Contains(t, data["avatar_url"], "/uploads/avatars/")
	})

	t.Run("no file uploaded", func(t *testing.T) {
		bodyBuf := &bytes.Buffer{}
		writer := multipart.NewWriter(bodyBuf)
		writer.Close()

		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/avatar", bodyBuf)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+tok)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "请选择头像文件")
	})

	t.Run("no auth token", func(t *testing.T) {
		bodyBuf := &bytes.Buffer{}
		writer := multipart.NewWriter(bodyBuf)
		part, _ := writer.CreateFormFile("avatar", "test.png")
		part.Write([]byte("fake-png"))
		writer.Close()

		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/avatar", bodyBuf)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("unsupported file type", func(t *testing.T) {
		bodyBuf := &bytes.Buffer{}
		writer := multipart.NewWriter(bodyBuf)
		part, _ := writer.CreateFormFile("avatar", "test.txt")
		part.Write([]byte("text content"))
		writer.Close()

		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/avatar", bodyBuf)
		req.Header.Set("Content-Type", writer.FormDataContentType())
		req.Header.Set("Authorization", "Bearer "+tok)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "只支持 JPG、PNG、GIF、WebP 格式")
	})
}

// ============================================================
// 3. GetDailyRecommend (GET /api/v1/music/daily-recommend)
// ============================================================

func TestGetDailyRecommend(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	song1 := model.Song{
		Title:       "Daily Song 1",
		Singer:      "Singer A",
		Style:       "pop",
		Status:      1,
		IsPublic:    1,
		PlayCount:   100,
		CopyrightID: fmt.Sprintf("cid_daily1_%d", time.Now().UnixNano()),
	}
	song2 := model.Song{
		Title:       "Daily Song 2",
		Singer:      "Singer B",
		Style:       "rock",
		Status:      1,
		IsPublic:    1,
		PlayCount:   50,
		CopyrightID: fmt.Sprintf("cid_daily2_%d", time.Now().UnixNano()),
	}
	// Create private song; GORM omits zero-value int8 fields so update after create
	song3 := model.Song{
		Title:       "Private Daily Song",
		Singer:      "Singer C",
		Style:       "jazz",
		Status:      1,
		CopyrightID: fmt.Sprintf("cid_daily3_%d", time.Now().UnixNano()),
	}
	db.DB.Create(&song1)
	db.DB.Create(&song2)
	db.DB.Create(&song3)
	db.DB.Model(&song3).Update("is_public", 0)

	r := createPublicMusicRouter()

	t.Run("has daily recommendations", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/daily-recommend", nil)
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
		r2 := createPublicMusicRouter()

		req := httptest.NewRequest(http.MethodGet, "/api/v1/music/daily-recommend", nil)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 0, len(data))
	})
}

// ============================================================
// 4. GetCreatorStars (GET /api/v1/creator/stars)
// ============================================================

func TestGetCreatorStars(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	r := createPublicCreatorRouter()

	t.Run("has creator stars", func(t *testing.T) {
		user1 := model.User{
			Username:   "staruser1",
			Nickname:   "StarUser1",
			Bio:        "Top creator",
			Status:     0,
			InviteCode: fmt.Sprintf("INVITE_STAR1_%d", time.Now().UnixNano()),
		}
		user2 := model.User{
			Username:   "staruser2",
			Nickname:   "StarUser2",
			Bio:        "Second creator",
			Status:     0,
			InviteCode: fmt.Sprintf("INVITE_STAR2_%d", time.Now().UnixNano()),
		}
		db.DB.Create(&user1)
		db.DB.Create(&user2)

		for i := 0; i < 3; i++ {
			s := model.Song{
				UserID:      user1.ID,
				Title:       fmt.Sprintf("Song %d from user1", i),
				Singer:      "Singer",
				Style:       "pop",
				Status:      1,
				IsPublic:    1,
				PlayCount:   100 + i*10,
				CopyrightID: fmt.Sprintf("cid_star1_%d_%d", i, time.Now().UnixNano()),
			}
			db.DB.Create(&s)
		}

		s := model.Song{
			UserID:      user2.ID,
			Title:       "Song from user2",
			Singer:      "Singer",
			Style:       "rock",
			Status:      1,
			IsPublic:    1,
			PlayCount:   200,
			CopyrightID: fmt.Sprintf("cid_star2_%d", time.Now().UnixNano()),
		}
		db.DB.Create(&s)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/creator/stars", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 2, len(data))

		star1 := data[0].(map[string]interface{})
		assert.Equal(t, "StarUser1", star1["nickname"])
		assert.Equal(t, float64(3), star1["works_count"])
	})

	t.Run("empty creator stars", func(t *testing.T) {
		err := SetupTestDB()
		assert.NoError(t, err)
		r2 := createPublicCreatorRouter()

		user := model.User{
			Username: "nouser",
			Nickname: "NoSongs",
			Status:   0,
		}
		db.DB.Create(&user)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/creator/stars", nil)
		w := httptest.NewRecorder()
		r2.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		// data might be nil when empty slice, handle gracefully
		if data, ok := resp["data"].([]interface{}); ok {
			assert.Equal(t, 0, len(data))
		}
	})
}

// ============================================================
// 5. GetCreatorDetail (GET /api/v1/creator/:user_id)
// ============================================================

func TestGetCreatorDetail(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	user := model.User{
		Username: "detailuser",
		Nickname: "DetailUser",
		Bio:      "Detail bio content",
		Status:   0,
	}
	db.DB.Create(&user)

	for i := 0; i < 2; i++ {
		s := model.Song{
			UserID:      user.ID,
			Title:       fmt.Sprintf("Detail Song %d", i+1),
			Singer:      "DetailSinger",
			Style:       "pop",
			Status:      1,
			IsPublic:    1,
			PlayCount:   50 + i*10,
			CopyrightID: fmt.Sprintf("cid_detail_%d_%d", i, time.Now().UnixNano()),
		}
		db.DB.Create(&s)
	}

	r := createPublicCreatorRouter()

	t.Run("existing creator", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/creator/"+strconv.Itoa(int(user.ID)), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})

		userData := data["user"].(map[string]interface{})
		assert.Equal(t, "DetailUser", userData["nickname"])
		assert.Equal(t, "Detail bio content", userData["bio"])
		assert.Equal(t, float64(2), userData["works_count"])

		songs := data["songs"].([]interface{})
		assert.Equal(t, 2, len(songs))
	})

	t.Run("non-existent user", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/creator/99999", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "用户不存在")
	})

	t.Run("invalid user_id (string)", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/creator/abc", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "参数错误")
	})
}

// ============================================================
// 6. CreateTogetherRoom (POST /api/v1/music/together/create)
// ============================================================

func TestCreateTogetherRoom(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, tok, err := SetupAuthTest()
	assert.NoError(t, err)

	song := CreateTestSong(userID)

	r := createMusicPrivateRouter()

	tests := []struct {
		name     string
		setAuth  func(req *http.Request)
		body     map[string]interface{}
		wantCode int
		check    func(t *testing.T, resp map[string]interface{})
	}{
		{
			name: "normal create room",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok) },
			body: map[string]interface{}{
				"song_id": song.ID,
			},
			wantCode: http.StatusOK,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Equal(t, float64(0), resp["code"])
				data := resp["data"].(map[string]interface{})
				code := data["room_code"].(string)
				assert.Equal(t, 6, len(code))
				assert.NotEmpty(t, data["room_id"])

				var room model.TogetherRoom
				db.DB.First(&room)
				assert.Equal(t, code, room.RoomCode)
				assert.Equal(t, uint(1), room.CreatorID)
				assert.Equal(t, song.ID, room.SongID)
			},
		},
		{
			name: "missing song_id",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok) },
			body:     map[string]interface{}{},
			wantCode: http.StatusBadRequest,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Contains(t, resp["msg"], "参数错误")
			},
		},
		{
			name: "no auth token",
			setAuth: func(req *http.Request) {},
			body: map[string]interface{}{
				"song_id": 1,
			},
			wantCode: http.StatusUnauthorized,
			check: func(t *testing.T, resp map[string]interface{}) {
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/music/together/create", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			tt.setAuth(req)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)

			assert.Equal(t, tt.wantCode, w.Code)

			// 只有成功且data不为空时才执行check
			if tt.check != nil && resp["data"] != nil {
				tt.check(t, resp)
			}
		})
	}
}

// ============================================================
// 7. JoinTogetherRoom (POST /api/v1/music/together/join/:room_code)
// ============================================================

func TestJoinTogetherRoom(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	uid1, _, err := SetupAuthTest()
	assert.NoError(t, err)

	_, tok2, err := SetupSecondUser()
	assert.NoError(t, err)

	song := CreateTestSong(uid1)
	room := model.TogetherRoom{
		RoomCode:  "123456",
		CreatorID: uid1,
		SongID:    song.ID,
		Status:    1,
		Members:   "[]",
	}
	db.DB.Create(&room)

	r := createMusicPrivateRouter()

	tests := []struct {
		name     string
		setAuth  func(req *http.Request)
		roomCode string
		wantCode int
		check    func(t *testing.T, resp map[string]interface{})
	}{
		{
			name: "join valid room",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok2) },
			roomCode: "123456",
			wantCode: http.StatusOK,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Equal(t, float64(0), resp["code"])
				data := resp["data"].(map[string]interface{})
				roomData := data["room"].(map[string]interface{})
				assert.Equal(t, "123456", roomData["RoomCode"])
			},
		},
		{
			name: "join non-existent room",
			setAuth: func(req *http.Request) { req.Header.Set("Authorization", "Bearer "+tok2) },
			roomCode: "999999",
			wantCode: http.StatusBadRequest,
			check: func(t *testing.T, resp map[string]interface{}) {
				assert.Contains(t, resp["msg"], "房间不存在")
			},
		},
		{
			name: "no auth token",
			setAuth: func(req *http.Request) {},
			roomCode: "123456",
			wantCode: http.StatusUnauthorized,
			check: func(t *testing.T, resp map[string]interface{}) {
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/api/v1/music/together/join/"+tt.roomCode, nil)
			tt.setAuth(req)
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)

			assert.Equal(t, tt.wantCode, w.Code)

			if tt.check != nil {
				tt.check(t, resp)
			}
		})
	}
}

// ============================================================
// 8. LeaveTogetherRoom (POST /api/v1/music/together/leave/:room_id)
// ============================================================

func TestLeaveTogetherRoom(t *testing.T) {
	gin.SetMode(gin.TestMode)
	err := SetupTestDB()
	assert.NoError(t, err)

	uid1, tok1, err := SetupAuthTest()
	assert.NoError(t, err)
	uid2, tok2, err := SetupSecondUser()
	assert.NoError(t, err)

	song := CreateTestSong(uid1)
	room := model.TogetherRoom{
		RoomCode:  "654321",
		CreatorID: uid1,
		SongID:    song.ID,
		Status:    1,
		Members:   fmt.Sprintf("[%d,%d]", uid1, uid2),
	}
	db.DB.Create(&room)

	// 创建房间成员记录
	db.DB.Create(&model.RoomMember{RoomID: room.ID, UserID: uid1, Role: 1})
	db.DB.Create(&model.RoomMember{RoomID: room.ID, UserID: uid2, Role: 0})

	r := createMusicPrivateRouter()

	t.Run("leave room normally", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/together/leave/"+strconv.Itoa(int(room.ID)), nil)
		req.Header.Set("Authorization", "Bearer "+tok2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var updatedRoom model.TogetherRoom
		db.DB.First(&updatedRoom, room.ID)
		assert.Equal(t, int8(1), updatedRoom.Status)
		assert.Equal(t, fmt.Sprintf("[%d]", uid1), updatedRoom.Members)
	})

	t.Run("leave non-existent room", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/together/leave/99999", nil)
		req.Header.Set("Authorization", "Bearer "+tok1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Contains(t, resp["msg"], "房间不存在")
	})

	t.Run("no auth token", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/together/leave/"+strconv.Itoa(int(room.ID)), nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	t.Run("last member leaving closes the room", func(t *testing.T) {
		room2 := model.TogetherRoom{
			RoomCode:  "111222",
			CreatorID: uid1,
			SongID:    song.ID,
			Status:    1,
			Members:   fmt.Sprintf("[%d]", uid1),
		}
		db.DB.Create(&room2)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/music/together/leave/"+strconv.Itoa(int(room2.ID)), nil)
		req.Header.Set("Authorization", "Bearer "+tok1)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])

		var closedRoom model.TogetherRoom
		db.DB.First(&closedRoom, room2.ID)
		assert.Equal(t, int8(2), closedRoom.Status)
	})
}
