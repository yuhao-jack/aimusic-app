package middleware

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// RateLimit 限流中间件
// keyFunc: 从请求中提取限流key（如user_id或IP）
// maxRequests: 窗口内最大请求数
// window: 时间窗口
func RateLimit(keyFunc func(*gin.Context) string, maxRequests int, window time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := keyFunc(c)
		redisKey := fmt.Sprintf("rate_limit:%s", key)

		// 使用Redis滑动窗口
		now := time.Now().UnixMilli()
		windowStart := now - window.Milliseconds()

		// 移除窗口外的记录
		db.Redis.ZRemRangeByScore(db.Ctx, redisKey, "0", fmt.Sprintf("%d", windowStart))

		// 统计窗口内请求数
		count := db.Redis.ZCard(db.Ctx, redisKey).Val()

		if count >= int64(maxRequests) {
			utils.Fail(c, http.StatusTooManyRequests, "请求过于频繁，请稍后再试")
			c.Abort()
			return
		}

		// 添加当前请求
		db.Redis.ZAdd(db.Ctx, redisKey, &redis.Z{Score: float64(now), Member: fmt.Sprintf("%d:%d", now, count)})
		db.Redis.Expire(db.Ctx, redisKey, window)

		c.Next()
	}
}

// IPLimitByIP 基于IP的限流key函数
func IPLimitByIP(c *gin.Context) string {
	return c.ClientIP()
}

// UserLimitByUserID 基于用户ID的限流key函数
func UserLimitByUserID(c *gin.Context) string {
	userID, exists := c.Get("user_id")
	if !exists {
		return c.ClientIP()
	}
	return fmt.Sprintf("%v", userID)
}

// PhoneLimitByPhone 基于手机号的限流key函数（从请求体提取）
func PhoneLimitByPhone(c *gin.Context) string {
	// 尝试从query参数获取
	phone := c.Query("phone")
	if phone == "" {
		// 尝试从form参数获取
		phone = c.PostForm("phone")
	}
	if phone == "" {
		return c.ClientIP()
	}
	return phone
}
