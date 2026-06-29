package middleware

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// CheckBan 用户封禁状态检查中间件
// 在JWTAuth之后检查用户是否被封禁
func CheckBan() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			c.Next()
			return
		}

		// 使用原生SQL查询，避免GORM日志刷屏
		var count int64
		now := time.Now().Unix()
		db.DB.Raw("SELECT COUNT(*) FROM user_bans WHERE user_id = ? AND deleted_at IS NULL AND (expire_at IS NULL OR expire_at > ?)", userID, now).Scan(&count)

		if count > 0 {
			// 存在有效封禁记录，查询详情
			var ban model.UserBan
			db.DB.Where("user_id = ? AND (expire_at IS NULL OR expire_at > ?)", userID, now).
				Order("created_at DESC").
				First(&ban)

			banTypeDesc := "封禁"
			if ban.BanType == 1 {
				banTypeDesc = "禁言"
			}
			utils.Fail(c, http.StatusForbidden, "账号已被"+banTypeDesc+": "+ban.Reason)
			c.Abort()
			return
		}

		c.Next()
	}
}
