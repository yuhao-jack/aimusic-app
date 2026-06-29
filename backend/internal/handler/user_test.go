package handler

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// testParseToken parses a Bearer token and returns claims
func testParseToken(authHeader string) (*jwtClaims, error) {
	if authHeader == "" {
		return nil, fmt.Errorf("empty auth header")
	}
	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || parts[0] != "Bearer" {
		return nil, fmt.Errorf("invalid auth format")
	}
	tokenStr := parts[1]
	claims := &jwtClaims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.AppConfig.JWT.Secret), nil
	})
	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}
	return claims, nil
}

type jwtClaims struct {
	UserID uint   `json:"user_id"`
	Phone  string `json:"phone"`
	jwt.RegisteredClaims
}

// authMiddleware creates a gin middleware that validates JWT
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		auth := c.GetHeader("Authorization")
		claims, err := testParseToken(auth)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"code": 401, "msg": "未携带认证信息"})
			return
		}
		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Next()
	}
}

// createTestPost creates a test post in DB
func createTestPost(userID uint, content string) model.Post {
	post := model.Post{
		UserID:  userID,
		Content: content,
		Images:  "[]",
	}
	db.DB.Create(&post)
	return post
}

func createUserRouter() *gin.Engine {
	r := gin.Default()
	public := r.Group("/api/v1")
	{
		public.POST("/user/register", RegisterByPassword)
		public.POST("/user/login", LoginByPassword)
		public.POST("/user/send-reset-code", SendResetCode)
		public.POST("/user/reset-password", ResetPassword)
		public.POST("/user/login-phone", LoginByPhone)
		public.POST("/user/login-oauth", LoginByOAuth)
		public.POST("/user/refresh-token", RefreshToken)
	}
	private := r.Group("/api/v1")
	private.Use(authMiddleware())
	{
		private.GET("/user/info", GetUserInfo)
		private.PUT("/user/info", UpdateUserInfo)
		private.GET("/user/works", GetUserWorks)
		private.GET("/user/likes", GetUserLikes)
		private.POST("/user/update-profile", UpdateUserProfile)
	}
	return r
}

func TestRegisterByPassword(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	r := createUserRouter()

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int
		checkMsg string
	}{
		{
			name: "normal registration",
			body: map[string]interface{}{
				"username": "newuser",
				"email":    "new@example.com",
				"password": "123456",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "duplicate username",
			body: map[string]interface{}{
				"username": "newuser",
				"email":    "other@example.com",
				"password": "123456",
			},
			wantCode: 200,
			checkMsg: "用户名已存在",
		},
		{
			name: "duplicate email",
			body: map[string]interface{}{
				"username": "otheruser",
				"email":    "new@example.com",
				"password": "123456",
			},
			wantCode: 200,
			checkMsg: "邮箱已被注册",
		},
		{
			name: "missing params",
			body: map[string]interface{}{
				"username": "abc",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
		{
			name: "password too short",
			body: map[string]interface{}{
				"username": "shortpwd",
				"email":    "short@example.com",
				"password": "123",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
		{
			name: "invalid email",
			body: map[string]interface{}{
				"username": "bademail",
				"email":    "notanemail",
				"password": "123456",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/user/register", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			err := json.Unmarshal(w.Body.Bytes(), &resp)
			assert.NoError(t, err)
			if tt.checkMsg == "success" {
				assert.Equal(t, float64(0), resp["code"])
			}
			assert.Contains(t, resp["msg"], tt.checkMsg)
		})
	}
}

func TestLoginByPassword(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	// create a normal user
	hashedPwd, _ := utils.HashPassword("correctpwd")
	user := model.User{
		Username:   "loginuser",
		Email:      "login@example.com",
		Password:   hashedPwd,
		Status:     0,
		InviteCode: fmt.Sprintf("INVITE_LOGIN_%d", time.Now().UnixNano()),
	}
	db.DB.Create(&user)

	// create a locked user
	hashedPwd2, _ := utils.HashPassword("anypwd")
	lockedUser := model.User{
		Username:   "lockeduser",
		Email:      "locked@example.com",
		Password:   hashedPwd2,
		Status:     1, // locked
		InviteCode: fmt.Sprintf("INVITE_LOCKED_%d", time.Now().UnixNano()),
	}
	db.DB.Create(&lockedUser)

	r := createUserRouter()

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int // expected HTTP code
		checkMsg string
	}{
		{
			name: "correct password by username",
			body: map[string]interface{}{
				"username": "loginuser",
				"password": "correctpwd",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "correct password by email",
			body: map[string]interface{}{
				"username": "login@example.com",
				"password": "correctpwd",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "wrong password",
			body: map[string]interface{}{
				"username": "loginuser",
				"password": "wrongpassword",
			},
			wantCode: 401,
			checkMsg: "用户名或密码错误",
		},
		{
			name: "non-existent user",
			body: map[string]interface{}{
				"username": "nobody",
				"password": "anypwd",
			},
			wantCode: 401,
			checkMsg: "用户名或密码错误",
		},
		{
			name: "locked user",
			body: map[string]interface{}{
				"username": "lockeduser",
				"password": "anypwd",
			},
			wantCode: 403,
			checkMsg: "账号已被禁用",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/user/login", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)

			if tt.wantCode == 200 {
				assert.Equal(t, float64(0), resp["code"])
				assert.Equal(t, "success", resp["msg"])
			} else {
				assert.Equal(t, float64(tt.wantCode), resp["code"])
				assert.Contains(t, resp["msg"], tt.checkMsg)
			}
		})
	}
}

func TestLoginByPhone(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	phone := "13800138000"
	db.DB.Create(&model.User{
		Username: "phoneuser138",
		Phone:    &phone,
		Nickname: "PhoneUser",
		Status:   0,
	})

	r := gin.Default()
	r.POST("/api/v1/user/login-phone", LoginByPhone)

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int
		checkMsg string
	}{
		{
			name: "correct code existing user",
			body: map[string]interface{}{
				"phone": "13800138000",
				"code":  "123456",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "correct code new user auto-register",
			body: map[string]interface{}{
				"phone": "13900139000",
				"code":  "123456",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "wrong verification code",
			body: map[string]interface{}{
				"phone": "13800138000",
				"code":  "000000",
			},
			wantCode: 200,
			checkMsg: "验证码错误",
		},
		{
			name: "missing params",
			body: map[string]interface{}{
				"phone": "13800138000",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/user/login-phone", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)
			// 安全地检查msg字段
			if msg, ok := resp["msg"].(string); ok {
				assert.Contains(t, msg, tt.checkMsg)
			}
		})
	}
}

func TestLoginByOAuth(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	openID := "wechat_open_id_123"
	db.DB.Create(&model.User{
		Username: "oauthuser",
		OpenID:   &openID,
		Nickname: "OAuthUser",
		Status:   0,
	})

	r := gin.Default()
	r.POST("/api/v1/user/login-oauth", LoginByOAuth)

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int
		checkMsg string
	}{
		{
			name: "new oauth user",
			body: map[string]interface{}{
				"open_id":  "new_oauth_id",
				"platform": "wechat",
				"nickname": "NewOAuth",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "existing oauth user",
			body: map[string]interface{}{
				"open_id":  "wechat_open_id_123",
				"platform": "wechat",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "missing open_id",
			body: map[string]interface{}{
				"platform": "wechat",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/user/login-oauth", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)
			assert.Contains(t, resp["msg"].(string), tt.checkMsg)
		})
	}
}

func TestSendResetCode(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	user := model.User{
		Username: "resetuser",
		Email:    "reset@example.com",
		Status:   0,
	}
	db.DB.Create(&user)

	r := createUserRouter()

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int
		checkMsg string
	}{
		{
			name: "valid email",
			body: map[string]interface{}{
				"email": "reset@example.com",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "unregistered email",
			body: map[string]interface{}{
				"email": "unknown@example.com",
			},
			wantCode: 200,
			checkMsg: "该邮箱未注册",
		},
		{
			name: "missing email param",
			body:     map[string]interface{}{},
			wantCode: 200,
			checkMsg: "参数错误",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/user/send-reset-code", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)
			// 安全地检查msg字段
			if msg, ok := resp["msg"].(string); ok {
				assert.Contains(t, msg, tt.checkMsg)
			}
		})
	}
}

func TestResetPassword(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	hashedPwd, _ := utils.HashPassword("oldpassword")
	user := model.User{
		Username: "pwdresetuser",
		Email:    "pwdreset@example.com",
		Password: hashedPwd,
		Status:   0,
	}
	db.DB.Create(&user)

	r := createUserRouter()

	tests := []struct {
		name     string
		body     map[string]interface{}
		wantCode int
		checkMsg string
	}{
		{
			name: "correct reset",
			body: map[string]interface{}{
				"email":        "pwdreset@example.com",
				"code":         "123456",
				"new_password": "newpassword123",
			},
			wantCode: 200,
			checkMsg: "success",
		},
		{
			name: "wrong verification code",
			body: map[string]interface{}{
				"email":        "pwdreset@example.com",
				"code":         "000000",
				"new_password": "newpassword123",
			},
			wantCode: 200,
			checkMsg: "验证码错误",
		},
		{
			name: "unregistered email",
			body: map[string]interface{}{
				"email":        "unknown@example.com",
				"code":         "123456",
				"new_password": "newpassword123",
			},
			wantCode: 200,
			checkMsg: "该邮箱未注册",
		},
		{
			name: "missing params",
			body: map[string]interface{}{
				"email": "pwdreset@example.com",
			},
			wantCode: 200,
			checkMsg: "参数错误",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonBody, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/user/reset-password", bytes.NewBuffer(jsonBody))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()
			r.ServeHTTP(w, req)

			var resp map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &resp)
			// 安全地检查msg字段
			if msg, ok := resp["msg"].(string); ok {
				assert.Contains(t, msg, tt.checkMsg)
			}
		})
	}
}

func TestGetUserInfo(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)

	// create some works
	_ = CreateTestSong(userID)

	r := createUserRouter()

	t.Run("logged in user info", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/info", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.Equal(t, "TestUser", data["nickname"])
		// works count should be > 0
		assert.Equal(t, float64(1), data["works_count"])
	})

	t.Run("no auth token", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/info", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, 401, w.Code)
	})
}

func TestUpdateUserInfo(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	_, token, err := SetupAuthTest()
	assert.NoError(t, err)

	r := createUserRouter()

	t.Run("update with auth", func(t *testing.T) {
		body := map[string]interface{}{
			"nickname": "NewNick",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/user/info", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
	})

	t.Run("no auth token", func(t *testing.T) {
		body := map[string]interface{}{
			"nickname": "NoAuth",
		}
		jsonBody, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPut, "/api/v1/user/info", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, 401, w.Code)
	})
}

func TestGetUserWorks(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	// create works for user 1
	CreateTestSong(userID)

	r := createUserRouter()

	t.Run("user has works", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/works", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 1, len(data))
	})

	t.Run("user has no works", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/works", nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 0, len(data))
	})
}

func TestGetUserLikes(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	userID, token, err := SetupAuthTest()
	assert.NoError(t, err)
	_, token2, err := SetupSecondUser()
	assert.NoError(t, err)

	song := CreateTestSong(userID)
	db.DB.Create(&model.Like{
		UserID:   userID,
		TargetID: song.ID,
		LikeType: "song",
	})

	r := createUserRouter()

	t.Run("user has likes", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/likes", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 1, len(data))
	})

	t.Run("user has no likes", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/user/likes", nil)
		req.Header.Set("Authorization", "Bearer "+token2)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].([]interface{})
		assert.Equal(t, 0, len(data))
	})
}

func TestRefreshToken(t *testing.T) {
	err := SetupTestDB()
	assert.NoError(t, err)

	// 创建测试用户
	_, _, err = SetupAuthTest()
	assert.NoError(t, err)

	r := createUserRouter()

	t.Run("refresh success", func(t *testing.T) {
		// 先登录获取 refresh_token
		loginBody := `{"username":"testuser","password":"123456"}`
		loginReq := httptest.NewRequest(http.MethodPost, "/api/v1/user/login", strings.NewReader(loginBody))
		loginReq.Header.Set("Content-Type", "application/json")
		loginW := httptest.NewRecorder()
		r.ServeHTTP(loginW, loginReq)

		var loginResp map[string]interface{}
		json.Unmarshal(loginW.Body.Bytes(), &loginResp)
		loginData := loginResp["data"].(map[string]interface{})
		refreshToken := loginData["refresh_token"].(string)

		// 使用 refresh_token 刷新
		refreshBody := `{"refresh_token":"` + refreshToken + `"}`
		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/refresh-token", strings.NewReader(refreshBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(0), resp["code"])
		data := resp["data"].(map[string]interface{})
		assert.NotEmpty(t, data["token"])
		assert.NotEmpty(t, data["refresh_token"])
	})

	t.Run("invalid refresh token", func(t *testing.T) {
		refreshBody := `{"refresh_token":"invalid_token"}`
		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/refresh-token", strings.NewReader(refreshBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		var resp map[string]interface{}
		json.Unmarshal(w.Body.Bytes(), &resp)
		assert.Equal(t, float64(401), resp["code"])
	})

	t.Run("missing refresh token", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/user/refresh-token", strings.NewReader("{}"))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)

		assert.Equal(t, 400, w.Code)
	})
}
