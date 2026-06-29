
package middleware

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

type Claims struct {
	UserID uint   `json:"user_id"`
	Phone  string `json:"phone"`
	IP     string `json:"ip,omitempty"` // Token绑定IP（可选）
	jwt.RegisteredClaims
}

// RefreshClaims 刷新令牌的Claims，包含type标识
type RefreshClaims struct {
	UserID uint   `json:"user_id"`
	Phone  string `json:"phone"`
	Type   string `json:"type"` // 标识为 "refresh"
	jwt.RegisteredClaims
}

// TokenSecurityConfig Token安全配置
type TokenSecurityConfig struct {
	// EnableIPBinding 是否启用Token绑定IP
	EnableIPBinding bool
	// MaxUsageCount Token最大使用次数（0表示不限制）
	MaxUsageCount int
	// UsageWindow 使用次数统计时间窗口
	UsageWindow time.Duration
	// EnableAnomalyDetection 是否启用异常登录检测
	EnableAnomalyDetection bool
	// MaxDifferentIPs 同一用户最大不同IP数（异常检测阈值）
	MaxDifferentIPs int
	// IPCheckWindow IP检查时间窗口
	IPCheckWindow time.Duration
}

// DefaultTokenSecurityConfig 默认Token安全配置
func DefaultTokenSecurityConfig() TokenSecurityConfig {
	return TokenSecurityConfig{
		EnableIPBinding:        false, // 默认不启用IP绑定（移动端IP会变化）
		MaxUsageCount:          10000, // 单个Token最大使用10000次
		UsageWindow:            24 * time.Hour,
		EnableAnomalyDetection: true,
		MaxDifferentIPs:        5, // 24小时内最多5个不同IP
		IPCheckWindow:          24 * time.Hour,
	}
}

// JWTAuth JWT鉴权中间件（安全增强版）
// 1. Token绑定IP（可选）
// 2. Token使用次数限制
// 3. 异常登录检测
func JWTAuth() gin.HandlerFunc {
	return JWTAuthWithConfig(DefaultTokenSecurityConfig())
}

// JWTAuthWithConfig 使用自定义配置的JWT鉴权中间件
func JWTAuthWithConfig(cfg TokenSecurityConfig) gin.HandlerFunc {
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

		clientIP := c.ClientIP()

		// 1. IP绑定检查（可选）
		if cfg.EnableIPBinding && claims.IP != "" && claims.IP != clientIP {
			utils.Fail(c, http.StatusUnauthorized, "Token与当前IP不匹配")
			c.Abort()
			return
		}

		// 2. Token使用次数限制
		if cfg.MaxUsageCount > 0 {
			usageKey := fmt.Sprintf("token_usage:%d:%s", claims.UserID, tokenStr[:16])
			count, _ := db.Redis.Incr(db.Ctx, usageKey).Result()
			if count == 1 {
				db.Redis.Expire(db.Ctx, usageKey, cfg.UsageWindow)
			}
			if count > int64(cfg.MaxUsageCount) {
				utils.Fail(c, http.StatusUnauthorized, "Token使用次数超限，请重新登录")
				c.Abort()
				return
			}
		}

		// 3. 异常登录检测
		if cfg.EnableAnomalyDetection {
			go checkAnomalyLogin(claims.UserID, clientIP, cfg)
		}

		// 将用户信息存入上下文
		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Next()
	}
}

// checkAnomalyLogin 检测异常登录（异步执行，不阻塞请求）
func checkAnomalyLogin(userID uint, clientIP string, cfg TokenSecurityConfig) {
	// 使用Redis Set记录用户登录IP
	ipKey := fmt.Sprintf("login_ips:%d", userID)
	added, _ := db.Redis.SAdd(db.Ctx, ipKey, clientIP).Result()
	if added > 0 {
		// 新IP，设置过期时间
		db.Redis.Expire(db.Ctx, ipKey, cfg.IPCheckWindow)
	}

	// 统计不同IP数量
	ipCount := db.Redis.SCard(db.Ctx, ipKey).Val()

	if ipCount > int64(cfg.MaxDifferentIPs) {
		// 触发告警
		alertKey := fmt.Sprintf("alert:anomaly_login:%d", userID)
		// 防止重复告警（1小时内只告警一次）
		if db.Redis.SetNX(db.Ctx, alertKey, 1, 1*time.Hour).Val() {
			alert := model.SystemAlert{
				Type:    "anomaly_login",
				Level:   2,
				Target:  fmt.Sprintf("%d", userID),
				Message: fmt.Sprintf("用户%d在%v内使用%d个不同IP登录，疑似账号被盗", userID, cfg.IPCheckWindow, ipCount),
			}
			go func() {
				if err := db.DB.Create(&alert).Error; err != nil {
					log.Printf("[异常登录告警记录失败] %v", err)
				}
			}()
			log.Printf("[异常登录检测] 用户ID:%d IP:%s 不同IP数:%d", userID, clientIP, ipCount)
		}
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

// GenerateTokenWithIP 生成绑定IP的JWT令牌
func GenerateTokenWithIP(userID uint, phone, clientIP string) (string, error) {
	expireTime := time.Now().Add(time.Duration(config.AppConfig.JWT.ExpireHours) * time.Hour)
	claims := Claims{
		UserID: userID,
		Phone:  phone,
		IP:     clientIP,
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

// GenerateTokenPairWithIP 生成绑定IP的令牌对
func GenerateTokenPairWithIP(userID uint, phone, clientIP string) (accessToken, refreshToken string, err error) {
	// 生成 access_token（绑定IP）
	accessExpire := time.Now().Add(time.Duration(config.AppConfig.JWT.ExpireHours) * time.Hour)
	accessClaims := Claims{
		UserID: userID,
		Phone:  phone,
		IP:     clientIP,
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

	// 生成 refresh_token（不绑定IP，因为IP可能变化）
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

// InvalidateUserTokens 使用户所有Token失效（通过Redis标记）
func InvalidateUserTokens(userID uint) {
	key := fmt.Sprintf("token_invalid:%d", userID)
	// 设置标记，JWT中间件可检查此标记
	db.Redis.Set(db.Ctx, key, 1, 24*time.Hour)
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
