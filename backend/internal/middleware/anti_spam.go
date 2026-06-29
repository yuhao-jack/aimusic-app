package middleware

import (
	"fmt"
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

const (
	// 短时间请求阈值（每分钟）
	spamRequestThreshold = 60
	// 同一IP不同账号登录阈值
	ipLoginThreshold = 5
	// 检测时间窗口
	spamWindow = 10 * time.Minute
)

// AntiSpam 防刷检测中间件
// 检测异常行为并记录告警
func AntiSpam() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		userID, _ := c.Get("user_id")

		// 检测同一用户短时间大量请求
		if userID != nil {
			checkUserRequestSpam(c, userID.(uint), ip)
		}

		// 检测同一IP大量不同账号登录（仅对登录接口生效）
		if isLoginRequest(c) {
			checkIPLoginSpam(c, ip)
		}

		c.Next()
	}
}

// checkUserRequestSpam 检测用户请求频率异常
func checkUserRequestSpam(c *gin.Context, userID uint, ip string) {
	redisKey := fmt.Sprintf("spam:user:%d", userID)

	// 增加请求计数
	count, _ := db.Redis.Incr(db.Ctx, redisKey).Result()
	if count == 1 {
		db.Redis.Expire(db.Ctx, redisKey, spamWindow)
	}

	// 超过阈值，记录告警
	if count > int64(spamRequestThreshold) {
		alertKey := fmt.Sprintf("alert:user_spam:%d", userID)
		// 防止重复告警（同一用户10分钟内只告警一次）
		if db.Redis.SetNX(db.Ctx, alertKey, 1, 10*time.Minute).Val() {
			createSystemAlert(model.AlertTypeRateLimit, 2, fmt.Sprintf("%d", userID),
				fmt.Sprintf("用户%d在%s内请求%d次，疑似刷接口", userID, spamWindow, count))
			log.Printf("[防刷告警] 用户%d IP:%s 请求频率异常: %d次/%v", userID, ip, count, spamWindow)
		}
	}
}

// checkIPLoginSpam 检测同一IP大量不同账号登录
func checkIPLoginSpam(c *gin.Context, ip string) {
	redisKey := fmt.Sprintf("spam:ip_login:%s", ip)

	// 记录本次登录的用户标识
	phone := c.PostForm("phone")
	if phone == "" {
		phone = c.Query("phone")
	}
	if phone == "" {
		return
	}

	// 使用Set记录不同账号
	db.Redis.SAdd(db.Ctx, redisKey, phone)
	db.Redis.Expire(db.Ctx, redisKey, spamWindow)

	// 统计不同账号数量
	count := db.Redis.SCard(db.Ctx, redisKey).Val()

	if count > int64(ipLoginThreshold) {
		alertKey := fmt.Sprintf("alert:ip_login_spam:%s", ip)
		if db.Redis.SetNX(db.Ctx, alertKey, 1, 10*time.Minute).Val() {
			createSystemAlert(model.AlertTypeIPAbuse, 3, ip,
				fmt.Sprintf("IP:%s 在%s内尝试登录%d个不同账号，疑似撞库攻击", ip, spamWindow, count))
			log.Printf("[防刷告警] IP:%s 登录不同账号数量异常: %d个/%v", ip, count, spamWindow)
		}
	}
}

// isLoginRequest 判断是否为登录请求
func isLoginRequest(c *gin.Context) bool {
	path := c.Request.URL.Path
	return path == "/api/v1/user/login" ||
		path == "/api/v1/user/login/phone" ||
		path == "/api/v1/user/login/oauth"
}

// createSystemAlert 创建系统告警记录
func createSystemAlert(alertType string, level int8, target, message string) {
	alert := model.SystemAlert{
		Type:    alertType,
		Level:   level,
		Target:  target,
		Message: message,
	}
	// 异步写入，不阻塞请求
	go func() {
		if err := db.DB.Create(&alert).Error; err != nil {
			log.Printf("[告警记录失败] %v", err)
		}
	}()
}
