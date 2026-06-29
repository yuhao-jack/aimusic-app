package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"golang.org/x/crypto/bcrypt"
)

// SensitiveActionConfig 敏感操作配置
type SensitiveActionConfig struct {
	// LargeCoinThreshold 大额音币消费阈值
	LargeCoinThreshold int
	// RequirePasswordForDelete 删除操作是否需要密码确认
	RequirePasswordForDelete bool
	// RequirePasswordForPasswordChange 修改密码是否需要旧密码
	RequirePasswordForPasswordChange bool
}

// DefaultSensitiveActionConfig 默认敏感操作配置
func DefaultSensitiveActionConfig() SensitiveActionConfig {
	return SensitiveActionConfig{
		LargeCoinThreshold:               100, // 消费超过100音币需要确认
		RequirePasswordForDelete:         true,
		RequirePasswordForPasswordChange: true,
	}
}

// RequirePasswordConfirm 密码确认中间件
// 用于删除账号等敏感操作，要求输入密码确认
func RequirePasswordConfirm() gin.HandlerFunc {
	return RequirePasswordConfirmWithConfig(DefaultSensitiveActionConfig())
}

// RequirePasswordConfirmWithConfig 使用自定义配置的密码确认中间件
func RequirePasswordConfirmWithConfig(cfg SensitiveActionConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !cfg.RequirePasswordForDelete {
			c.Next()
			return
		}

		// 从请求头或请求体获取密码
		password := c.GetHeader("X-Confirm-Password")
		if password == "" {
			// 尝试从请求体获取
			var req struct {
				ConfirmPassword string `json:"confirm_password"`
			}
			if err := c.ShouldBindJSON(&req); err == nil {
				password = req.ConfirmPassword
			}
		}

		if password == "" {
			utils.Fail(c, http.StatusBadRequest, "敏感操作需要密码确认")
			c.Abort()
			return
		}

		// 获取当前用户ID
		userID, exists := c.Get("user_id")
		if !exists {
			utils.Fail(c, http.StatusUnauthorized, "未登录")
			c.Abort()
			return
		}

		// 查询用户密码
		var user model.User
		if err := db.DB.Select("password").First(&user, userID).Error; err != nil {
			utils.Fail(c, http.StatusInternalServerError, "查询用户信息失败")
			c.Abort()
			return
		}

		// 验证密码
		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
			utils.Fail(c, http.StatusForbidden, "密码错误")
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireOldPassword 旧密码验证中间件
// 用于修改密码操作，要求输入旧密码
func RequireOldPassword() gin.HandlerFunc {
	return RequireOldPasswordWithConfig(DefaultSensitiveActionConfig())
}

// RequireOldPasswordWithConfig 使用自定义配置的旧密码验证中间件
func RequireOldPasswordWithConfig(cfg SensitiveActionConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !cfg.RequirePasswordForPasswordChange {
			c.Next()
			return
		}

		// 读取请求体
		bodyBytes, err := io.ReadAll(c.Request.Body)
		if err != nil {
			utils.Fail(c, http.StatusBadRequest, "读取请求体失败")
			c.Abort()
			return
		}
		// 重置请求体
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

		// 解析请求体获取旧密码
		var req struct {
			OldPassword string `json:"old_password"`
		}
		if err := json.Unmarshal(bodyBytes, &req); err != nil {
			utils.Fail(c, http.StatusBadRequest, "请求格式错误")
			c.Abort()
			return
		}

		if req.OldPassword == "" {
			utils.Fail(c, http.StatusBadRequest, "请输入旧密码")
			c.Abort()
			return
		}

		// 获取当前用户ID
		userID, exists := c.Get("user_id")
		if !exists {
			utils.Fail(c, http.StatusUnauthorized, "未登录")
			c.Abort()
			return
		}

		// 查询用户密码
		var user model.User
		if err := db.DB.Select("password").First(&user, userID).Error; err != nil {
			utils.Fail(c, http.StatusInternalServerError, "查询用户信息失败")
			c.Abort()
			return
		}

		// 验证旧密码
		if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.OldPassword)); err != nil {
			utils.Fail(c, http.StatusForbidden, "旧密码错误")
			c.Abort()
			return
		}

		c.Next()
	}
}

// CheckLargeCoinConsumption 大额音币消费确认中间件
// 消费超过阈值时需要额外确认
func CheckLargeCoinConsumption() gin.HandlerFunc {
	return CheckLargeCoinConsumptionWithConfig(DefaultSensitiveActionConfig())
}

// CheckLargeCoinConsumptionWithConfig 使用自定义配置的大额音币消费确认中间件
func CheckLargeCoinConsumptionWithConfig(cfg SensitiveActionConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 读取请求体
		bodyBytes, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.Next()
			return
		}
		// 重置请求体
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

		// 解析请求体获取音币消费数量
		var req struct {
			Coins        int  `json:"coins"`
			ConfirmLarge bool `json:"confirm_large"` // 前端确认标记
		}
		if err := json.Unmarshal(bodyBytes, &req); err != nil {
			c.Next()
			return
		}

		// 检查是否超过阈值
		if req.Coins > cfg.LargeCoinThreshold && !req.ConfirmLarge {
			utils.Fail(c, http.StatusPaymentRequired, "大额音币消费需要确认")
			c.Abort()
			return
		}

		c.Next()
	}
}

// VerifyCoinBalance 音币余额验证中间件
// 确保用户有足够的音币进行操作
func VerifyCoinBalance() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取当前用户ID
		userID, exists := c.Get("user_id")
		if !exists {
			c.Next()
			return
		}

		// 读取请求体
		bodyBytes, err := io.ReadAll(c.Request.Body)
		if err != nil {
			c.Next()
			return
		}
		// 重置请求体
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

		// 解析请求体获取需要的音币数量
		var req struct {
			Coins int `json:"coins"`
		}
		if err := json.Unmarshal(bodyBytes, &req); err != nil || req.Coins <= 0 {
			c.Next()
			return
		}

		// 查询用户音币余额
		var user model.User
		if err := db.DB.Select("coins").First(&user, userID).Error; err != nil {
			utils.Fail(c, http.StatusInternalServerError, "查询用户信息失败")
			c.Abort()
			return
		}

		if user.Coins < req.Coins {
			utils.Fail(c, http.StatusPaymentRequired, "音币余额不足")
			c.Abort()
			return
		}

		c.Next()
	}
}
