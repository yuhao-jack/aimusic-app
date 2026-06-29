
package utils

import (
	"github.com/yourname/aimusic-backend/pkg/config"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// GenerateAdminToken 生成管理员JWT token
func GenerateAdminToken(adminID uint, username string) (string, error) {
	claims := jwt.MapClaims{
		"admin_id":  adminID,
		"username":  username,
		"is_admin":  true,
		"expires_at": time.Now().Add(time.Hour * 24 * 7).Unix(), // 7天过期
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(config.AppConfig.JWT.Secret))
}
