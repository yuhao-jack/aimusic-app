
package middleware

import (
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID uint   `json:"user_id"`
	Phone  string `json:"phone"`
	jwt.RegisteredClaims
}

// RefreshClaims 刷新令牌的Claims，包含type标识
type RefreshClaims struct {
	UserID uint   `json:"user_id"`
	Phone  string `json:"phone"`
	Type   string `json:"type"` // 标识为 "refresh"
	jwt.RegisteredClaims
}

// JWTAuth JWT鉴权中间件
func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.Request.Header.Get("Authorization")
		if authHeader == "" {
			utils.Fail(c, http.StatusUnauthorized, "未携带认证信息")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if !(len(parts) == 2 && parts[0] == "Bearer") {
			utils.Fail(c, http.StatusUnauthorized, "认证信息格式错误")
			c.Abort()
			return
		}

		tokenStr := parts[1]
		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.AppConfig.JWT.Secret), nil
		})

		if err != nil || !token.Valid {
			utils.Fail(c, http.StatusUnauthorized, "认证已过期或无效")
			c.Abort()
			return
		}

		// 将用户信息存入上下文
		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Next()
	}
}

// GenerateToken 生成JWT令牌（保留兼容）
func GenerateToken(userID uint, phone string) (string, error) {
	expireTime := time.Now().Add(time.Duration(config.AppConfig.JWT.ExpireHours) * time.Hour)
	claims := Claims{
		UserID: userID,
		Phone:  phone,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expireTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "aimusic-app",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(config.AppConfig.JWT.Secret))
}

// GenerateTokenPair 生成 access_token + refresh_token 双令牌
// access_token 使用配置中的 expire_hours（默认24小时）
// refresh_token 使用配置中的 refresh_expire_hours（默认7天），包含 type: "refresh" 标识
func GenerateTokenPair(userID uint, phone string) (accessToken, refreshToken string, err error) {
	// 生成 access_token
	accessExpire := time.Now().Add(time.Duration(config.AppConfig.JWT.ExpireHours) * time.Hour)
	accessClaims := Claims{
		UserID: userID,
		Phone:  phone,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(accessExpire),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "aimusic-app",
		},
	}
	accessJWT := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
	accessToken, err = accessJWT.SignedString([]byte(config.AppConfig.JWT.Secret))
	if err != nil {
		return "", "", err
	}

	// 生成 refresh_token，使用 RefreshClaims 包含 type 标识
	refreshHours := config.AppConfig.JWT.RefreshExpireHours
	if refreshHours <= 0 {
		refreshHours = 168 // 默认7天
	}
	refreshExpire := time.Now().Add(time.Duration(refreshHours) * time.Hour)
	refreshClaims := RefreshClaims{
		UserID: userID,
		Phone:  phone,
		Type:   "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(refreshExpire),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "aimusic-app",
		},
	}
	refreshJWT := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshToken, err = refreshJWT.SignedString([]byte(config.AppConfig.JWT.Secret))
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

// ParseRefreshToken 解析并验证 refresh_token，返回 claims
func ParseRefreshToken(tokenStr string) (*RefreshClaims, error) {
	claims := &RefreshClaims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return []byte(config.AppConfig.JWT.Secret), nil
	})
	if err != nil || !token.Valid {
		return nil, jwt.ErrSignatureInvalid
	}
	// 验证 type 必须为 "refresh"
	if claims.Type != "refresh" {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}

// AdminJWTAuth 管理员JWT鉴权中间件
func AdminJWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.Request.Header.Get("Authorization")
		if authHeader == "" {
			utils.Fail(c, http.StatusUnauthorized, "未携带认证信息")
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if !(len(parts) == 2 && parts[0] == "Bearer") {
			utils.Fail(c, http.StatusUnauthorized, "认证信息格式错误")
			c.Abort()
			return
		}

		tokenStr := parts[1]
		claims := jwt.MapClaims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.AppConfig.JWT.Secret), nil
		})

		if err != nil || !token.Valid {
			utils.Fail(c, http.StatusUnauthorized, "认证已过期或无效")
			c.Abort()
			return
		}

		isAdmin, ok := claims["is_admin"].(bool)
		if !ok || !isAdmin {
			utils.Fail(c, http.StatusUnauthorized, "不是管理员权限")
			c.Abort()
			return
		}

		adminID, _ := claims["admin_id"].(float64)
		username, _ := claims["username"].(string)
		c.Set("admin_id", uint(adminID))
		c.Set("admin_username", username)
		c.Next()
	}
}
