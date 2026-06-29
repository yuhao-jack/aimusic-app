package middleware

import (
	"bytes"
	"io"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// AdminAuditLog 管理操作日志中间件
// 自动记录POST/PUT/DELETE操作到admin_operation_logs表
func AdminAuditLog() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只记录写操作
		method := c.Request.Method
		if method != "POST" && method != "PUT" && method != "DELETE" {
			c.Next()
			return
		}

		// 读取请求体（需要重置）
		var bodyBytes []byte
		if c.Request.Body != nil {
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

		// 构建操作描述
		action := method + " " + c.Request.URL.Path

		// 创建操作日志
		log := model.AdminOperationLog{
			AdminID:   adminID,
			AdminName: adminUsername,
			Action:    action,
			Path:      c.Request.URL.Path,
			IP:        c.ClientIP(),
		}

		// 异步写入日志，不阻塞响应
		go func() {
			_ = start // 避免未使用变量警告
			db.DB.Create(&log)
		}()
	}
}
