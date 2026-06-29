package middleware

import (
	"time"
	"github.com/gin-gonic/gin"
	"log"
)

// Logger 日志中间件
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method
		
		c.Next()
		
		latency := time.Since(start)
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()
		
		log.Printf("[%s] %s %s %d %s", method, path, clientIP, statusCode, latency)
	}
}

// Recovery 异常捕获中间件
func Recovery() gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		log.Printf("panic recovered: %v", recovered)
		c.JSON(500, gin.H{
			"code": 500,
			"msg":  "服务器内部错误",
		})
		c.AbortWithStatus(500)
	})
}
