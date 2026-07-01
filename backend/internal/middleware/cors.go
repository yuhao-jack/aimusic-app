package middleware

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/pkg/config"
)

// CORSConfig CORS配置
type CORSConfig struct {
	// AllowedOrigins 允许的源列表，为空时使用配置文件或默认值
	AllowedOrigins []string
	// AllowedMethods 允许的HTTP方法
	AllowedMethods []string
	// AllowedHeaders 允许的请求头
	AllowedHeaders []string
	// ExposeHeaders 暴露给前端的响应头
	ExposeHeaders []string
	// AllowCredentials 是否允许携带凭证
	AllowCredentials bool
	// MaxAge 预检请求缓存时间（秒）
	MaxAge int
}

// DefaultCORSConfig 默认CORS配置
func DefaultCORSConfig() CORSConfig {
	// 默认允许的来源（当配置文件未设置时使用）
	defaultOrigins := []string{
		"http://localhost:3000", // Vue管理后台
		"http://localhost:8080", // 开发环境
		"http://localhost:5173", // Vite开发服务器
	}

	// 优先从配置文件读取允许的来源列表
	origins := defaultOrigins
	if len(config.AppConfig.CORS.AllowedOrigins) > 0 {
		origins = config.AppConfig.CORS.AllowedOrigins
	}

	return CORSConfig{
		AllowedOrigins: origins,
		AllowedMethods: []string{
			"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH",
		},
		AllowedHeaders: []string{
			"Origin", "X-Requested-With", "Content-Type", "Accept", "Authorization",
		},
		ExposeHeaders: []string{
			"Content-Length", "Content-Type",
		},
		AllowCredentials: true,
		MaxAge:           86400, // 24小时
	}
}

// Cors 跨域中间件（安全增强版）
// 1. 限制允许的Origin（不再使用通配符*）
// 2. 限制允许的Methods
// 3. 限制允许的Headers
func Cors() gin.HandlerFunc {
	return CorsWithConfig(DefaultCORSConfig())
}

// CorsWithConfig 使用自定义配置的CORS中间件
func CorsWithConfig(cfg CORSConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		method := c.Request.Method
		origin := c.Request.Header.Get("Origin")

		if origin == "" {
			// 非CORS请求，直接放行
			if method == "OPTIONS" {
				c.AbortWithStatus(http.StatusNoContent)
				return
			}
			c.Next()
			return
		}

		// 检查Origin是否在允许列表中
		if !isOriginAllowed(origin, cfg.AllowedOrigins) {
			// 不允许的Origin，不设置CORS头，浏览器会拒绝
			if method == "OPTIONS" {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
			c.Next()
			return
		}

		// 设置CORS响应头
		c.Header("Access-Control-Allow-Origin", origin)
		c.Header("Access-Control-Allow-Methods", strings.Join(cfg.AllowedMethods, ", "))
		c.Header("Access-Control-Allow-Headers", strings.Join(cfg.AllowedHeaders, ", "))
		c.Header("Access-Control-Expose-Headers", strings.Join(cfg.ExposeHeaders, ", "))

		if cfg.AllowCredentials {
			c.Header("Access-Control-Allow-Credentials", "true")
		}

		if cfg.MaxAge > 0 {
			c.Header("Access-Control-Max-Age", strconv.Itoa(cfg.MaxAge))
		}

		// 预检请求直接返回
		if method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// isOriginAllowed 检查Origin是否在允许列表中
func isOriginAllowed(origin string, allowedOrigins []string) bool {
	// 从配置文件读取额外的允许源
	extraOrigins := getExtraAllowedOrigins()
	allOrigins := append(allowedOrigins, extraOrigins...)

	for _, allowed := range allOrigins {
		if allowed == "*" {
			return true
		}
		if allowed == origin {
			return true
		}
		// 支持通配符匹配，如 *.example.com
		if strings.HasPrefix(allowed, "*.") {
			suffix := allowed[1:] // .example.com
			if strings.HasSuffix(origin, suffix) {
				return true
			}
		}
	}
	return false
}

// getExtraAllowedOrigins 从配置文件获取额外的允许源
func getExtraAllowedOrigins() []string {
	// 动态管理的源由 dynamicOrigins 维护，此处不再单独读取
	return []string{}
}

// 为了兼容性，保留IsOriginAllowed导出函数
var IsOriginAllowed = isOriginAllowed

// GetConfiguredOrigins 获取当前配置的允许源（供管理后台查看）
func GetConfiguredOrigins() []string {
	cfg := DefaultCORSConfig()
	extra := getExtraAllowedOrigins()
	return append(cfg.AllowedOrigins, extra...)
}

// 动态管理允许的源（用于管理后台配置）
var dynamicOrigins []string

// AddAllowedOrigin 动态添加允许的源
func AddAllowedOrigin(origin string) {
	for _, o := range dynamicOrigins {
		if o == origin {
			return
		}
	}
	dynamicOrigins = append(dynamicOrigins, origin)
}

// RemoveAllowedOrigin 动态移除允许的源
func RemoveAllowedOrigin(origin string) {
	for i, o := range dynamicOrigins {
		if o == origin {
			dynamicOrigins = append(dynamicOrigins[:i], dynamicOrigins[i+1:]...)
			return
		}
	}
}

// GetDynamicOrigins 获取动态添加的源
func GetDynamicOrigins() []string {
	return dynamicOrigins
}

// CorsWithDynamicOrigins 使用动态源管理的CORS中间件
func CorsWithDynamicOrigins() gin.HandlerFunc {
	cfg := DefaultCORSConfig()
	return func(c *gin.Context) {
		method := c.Request.Method
		origin := c.Request.Header.Get("Origin")

		if origin == "" {
			if method == "OPTIONS" {
				c.AbortWithStatus(http.StatusNoContent)
				return
			}
			c.Next()
			return
		}

		// 合并静态和动态源
		allOrigins := append(cfg.AllowedOrigins, dynamicOrigins...)
		if !isOriginAllowed(origin, allOrigins) {
			if method == "OPTIONS" {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
			c.Next()
			return
		}

		c.Header("Access-Control-Allow-Origin", origin)
		c.Header("Access-Control-Allow-Methods", strings.Join(cfg.AllowedMethods, ", "))
		c.Header("Access-Control-Allow-Headers", strings.Join(cfg.AllowedHeaders, ", "))
		c.Header("Access-Control-Expose-Headers", strings.Join(cfg.ExposeHeaders, ", "))

		if cfg.AllowCredentials {
			c.Header("Access-Control-Allow-Credentials", "true")
		}

		if cfg.MaxAge > 0 {
			c.Header("Access-Control-Max-Age", strconv.Itoa(cfg.MaxAge))
		}

		if method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// GetCORSConfig 获取当前CORS配置（供管理接口使用）
func GetCORSConfig() map[string]interface{} {
	cfg := DefaultCORSConfig()
	return map[string]interface{}{
		"allowed_origins":    cfg.AllowedOrigins,
		"dynamic_origins":    dynamicOrigins,
		"allowed_methods":    cfg.AllowedMethods,
		"allowed_headers":    cfg.AllowedHeaders,
		"expose_headers":     cfg.ExposeHeaders,
		"allow_credentials":  cfg.AllowCredentials,
		"max_age":            cfg.MaxAge,
	}
}
