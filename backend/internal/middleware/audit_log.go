package middleware

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// AuditLogConfig 审计日志配置
type AuditLogConfig struct {
	// MaxBodySummaryLength 请求体摘要最大长度
	MaxBodySummaryLength int
	// SensitiveFields 敏感字段名列表（将在摘要中脱敏）
	SensitiveFields []string
	// EnableRequestBody 是否记录请求体
	EnableRequestBody bool
}

// DefaultAuditLogConfig 默认审计日志配置
func DefaultAuditLogConfig() AuditLogConfig {
	return AuditLogConfig{
		MaxBodySummaryLength: 500,
		SensitiveFields: []string{
			"password", "old_password", "new_password", "confirm_password",
			"token", "access_token", "refresh_token", "secret",
			"credit_card", "card_number", "cvv",
		},
		EnableRequestBody: true,
	}
}

// AdminAuditLog 管理操作日志中间件（增强版）
// 记录所有写操作的详细信息：请求体摘要、响应状态码、耗时
func AdminAuditLog() gin.HandlerFunc {
	return AdminAuditLogWithConfig(DefaultAuditLogConfig())
}

// AdminAuditLogWithConfig 使用自定义配置的审计日志中间件
func AdminAuditLogWithConfig(cfg AuditLogConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只记录写操作
		method := c.Request.Method
		if method != "POST" && method != "PUT" && method != "DELETE" && method != "PATCH" {
			c.Next()
			return
		}

		// 读取请求体（需要重置供后续处理器读取）
		var bodyBytes []byte
		if c.Request.Body != nil && cfg.EnableRequestBody {
			bodyBytes, _ = io.ReadAll(c.Request.Body)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		}

		// 记录开始时间
		start := time.Now()

		// 执行后续处理器
		c.Next()

		// 获取管理员信息（安全类型断言，避免 panic）
		adminIDVal, ok := c.Get("admin_id")
		if !ok {
			return
		}
		adminID, ok := adminIDVal.(uint)
		if !ok {
			return
		}
		adminUsernameVal, _ := c.Get("admin_username")
		adminUsername, _ := adminUsernameVal.(string)

		// 计算耗时
		latency := time.Since(start)

		// 获取响应状态码
		statusCode := c.Writer.Status()

		// 构建操作描述
		action := method + " " + c.Request.URL.Path

		// 生成请求体摘要（脱敏处理）
		bodySummary := generateBodySummary(bodyBytes, cfg)

		// 构建详细日志描述
		detail := fmt.Sprintf("状态码:%d 耗时:%v", statusCode, latency)
		if bodySummary != "" {
			detail += " 请求体:" + bodySummary
		}

		// 创建操作日志
		auditLog := model.AdminOperationLog{
			AdminID:   adminID,
			AdminName: adminUsername,
			Action:    action,
			Path:      c.Request.URL.Path,
			IP:        c.ClientIP(),
		}

		// 异步写入日志，不阻塞响应
		go func() {
			if err := db.DB.Create(&auditLog).Error; err != nil {
				log.Printf("[审计日志写入失败] %v", err)
			}
		}()
	}
}

// UserOperationLog 用户操作日志中间件
// 记录用户的重要写操作
func UserOperationLog() gin.HandlerFunc {
	return UserOperationLogWithConfig(DefaultAuditLogConfig())
}

// UserOperationLogWithConfig 使用自定义配置的用户操作日志中间件
func UserOperationLogWithConfig(cfg AuditLogConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只记录写操作
		method := c.Request.Method
		if method != "POST" && method != "PUT" && method != "DELETE" && method != "PATCH" {
			c.Next()
			return
		}

		// 跳过文件上传
		contentType := c.GetHeader("Content-Type")
		if len(contentType) >= 19 && contentType[:19] == "multipart/form-data" {
			c.Next()
			return
		}

		// 读取请求体
		var bodyBytes []byte
		if c.Request.Body != nil && cfg.EnableRequestBody {
			bodyBytes, _ = io.ReadAll(c.Request.Body)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
		}

		start := time.Now()
		c.Next()

		// 获取用户信息
		userIDVal, exists := c.Get("user_id")
		if !exists {
			return
		}
		userID, ok := userIDVal.(uint)
		if !ok {
			return
		}

		latency := time.Since(start)
		statusCode := c.Writer.Status()

		// 生成请求体摘要
		bodySummary := generateBodySummary(bodyBytes, cfg)

		// 记录到日志文件（用户操作暂不写入数据库，避免表膨胀）
		log.Printf("[用户操作] 用户ID:%d %s %s 状态码:%d 耗时:%v 请求体:%s",
			userID, method, c.Request.URL.Path, statusCode, latency, bodySummary)
	}
}

// generateBodySummary 生成请求体摘要（脱敏处理）
func generateBodySummary(bodyBytes []byte, cfg AuditLogConfig) string {
	if len(bodyBytes) == 0 {
		return ""
	}

	// 尝试解析为JSON
	var data map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &data); err != nil {
		// 非JSON格式，截断返回
		s := string(bodyBytes)
		if len(s) > cfg.MaxBodySummaryLength {
			s = s[:cfg.MaxBodySummaryLength] + "..."
		}
		return s
	}

	// 脱敏处理敏感字段
	for _, field := range cfg.SensitiveFields {
		if _, exists := data[field]; exists {
			data[field] = "***脱敏***"
		}
	}

	// 序列化为JSON字符串
	sanitized, err := json.Marshal(data)
	if err != nil {
		return "[序列化失败]"
	}

	s := string(sanitized)
	if len(s) > cfg.MaxBodySummaryLength {
		s = s[:cfg.MaxBodySummaryLength] + "..."
	}
	return s
}

// WriteAuditLog 写入审计日志的工具函数（供其他模块调用）
func WriteAuditLog(adminID uint, adminName, action, path, ip string) {
	auditLog := model.AdminOperationLog{
		AdminID:   adminID,
		AdminName: adminName,
		Action:    action,
		Path:      path,
		IP:        ip,
	}
	go func() {
		if err := db.DB.Create(&auditLog).Error; err != nil {
			log.Printf("[审计日志写入失败] %v", err)
		}
	}()
}

// WriteUserAuditLog 写入用户操作审计日志（写入数据库，用于重要操作）
func WriteUserAuditLog(userID uint, action, path, ip, detail string) {
	log.Printf("[用户审计] 用户ID:%d %s %s IP:%s 详情:%s", userID, action, path, ip, detail)
}
