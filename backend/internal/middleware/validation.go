package middleware

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"reflect"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

const (
	// MaxRequestBodySize 最大请求体大小：1MB
	MaxRequestBodySize = 1 << 20
	// MaxStringFieldLength 字符串字段最大长度
	MaxStringFieldLength = 10000
	// MaxNumberValue 数字字段最大值
	MaxNumberValue = 1 << 31
	// MinNumberValue 数字字段最小值
	MinNumberValue = -(1 << 31)
)

// ValidationConfig 验证配置
type ValidationConfig struct {
	// MaxBodySize 请求体最大字节数
	MaxBodySize int64
	// MaxStringLen 字符串字段最大长度
	MaxStringLen int
	// MaxNumber 数字字段最大值
	MaxNumber float64
	// MinNumber 数字字段最小值
	MinNumber float64
}

// DefaultValidationConfig 默认验证配置
func DefaultValidationConfig() ValidationConfig {
	return ValidationConfig{
		MaxBodySize:  MaxRequestBodySize,
		MaxStringLen: MaxStringFieldLength,
		MaxNumber:    float64(MaxNumberValue),
		MinNumber:    float64(MinNumberValue),
	}
}

// InputValidation 全局输入验证中间件
// 1. 限制请求体大小（默认1MB）
// 2. 验证字符串字段长度
// 3. 验证数字字段范围
func InputValidation() gin.HandlerFunc {
	return InputValidationWithConfig(DefaultValidationConfig())
}

// InputValidationWithConfig 使用自定义配置的输入验证中间件
func InputValidationWithConfig(cfg ValidationConfig) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只验证包含请求体的方法
		method := c.Request.Method
		if method != "POST" && method != "PUT" && method != "PATCH" {
			c.Next()
			return
		}

		// 跳过文件上传接口（Content-Type 为 multipart/form-data）
		contentType := c.GetHeader("Content-Type")
		if strings.HasPrefix(contentType, "multipart/form-data") {
			c.Next()
			return
		}

		// 1. 限制请求体大小
		if c.Request.ContentLength > cfg.MaxBodySize {
			utils.Fail(c, http.StatusRequestEntityTooLarge,
				fmt.Sprintf("请求体过大，最大允许%d字节", cfg.MaxBodySize))
			c.Abort()
			return
		}

		// 读取请求体并限制大小
		bodyBytes, err := io.ReadAll(io.LimitReader(c.Request.Body, cfg.MaxBodySize+1))
		if err != nil {
			utils.Fail(c, http.StatusBadRequest, "读取请求体失败")
			c.Abort()
			return
		}

		// 检查实际大小是否超限
		if int64(len(bodyBytes)) > cfg.MaxBodySize {
			utils.Fail(c, http.StatusRequestEntityTooLarge,
				fmt.Sprintf("请求体过大，最大允许%d字节", cfg.MaxBodySize))
			c.Abort()
			return
		}

		// 重置请求体供后续处理器读取
		c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

		// 空请求体跳过验证
		if len(bodyBytes) == 0 {
			c.Next()
			return
		}

		// 2. 解析并验证JSON字段
		var data interface{}
		if err := json.Unmarshal(bodyBytes, &data); err != nil {
			// JSON解析失败，交由后续绑定器处理（可能不是JSON格式）
			c.Next()
			return
		}

		// 递归验证字段
		if err := validateFields(data, cfg); err != nil {
			utils.Fail(c, http.StatusBadRequest, err.Error())
			c.Abort()
			return
		}

		c.Next()
	}
}

// validateFields 递归验证JSON字段
func validateFields(data interface{}, cfg ValidationConfig) error {
	switch v := data.(type) {
	case map[string]interface{}:
		for key, val := range v {
			if err := validateFieldValue(key, val, cfg); err != nil {
				return err
			}
		}
	case []interface{}:
		for i, item := range v {
			if err := validateFields(item, cfg); err != nil {
				return fmt.Errorf("索引%d: %w", i, err)
			}
		}
	}
	return nil
}

// validateFieldValue 验证单个字段值
func validateFieldValue(fieldName string, value interface{}, cfg ValidationConfig) error {
	if value == nil {
		return nil
	}

	switch v := value.(type) {
	case string:
		// 字符串长度检查
		if len(v) > cfg.MaxStringLen {
			return fmt.Errorf("字段'%s'长度超过限制，最大允许%d个字符", fieldName, cfg.MaxStringLen)
		}
	case float64:
		// JSON数字统一解析为float64
		if v > cfg.MaxNumber || v < cfg.MinNumber {
			return fmt.Errorf("字段'%s'数值超出范围[%.0f, %.0f]", fieldName, cfg.MinNumber, cfg.MaxNumber)
		}
	case json.Number:
		// 处理json.Number类型
		f, err := v.Float64()
		if err == nil && (f > cfg.MaxNumber || f < cfg.MinNumber) {
			return fmt.Errorf("字段'%s'数值超出范围[%.0f, %.0f]", fieldName, cfg.MinNumber, cfg.MaxNumber)
		}
	case map[string]interface{}:
		// 递归验证嵌套对象
		return validateFields(v, cfg)
	case []interface{}:
		// 递归验证数组
		return validateFields(v, cfg)
	case bool:
		// 布尔值无需验证
	default:
		// 使用反射处理其他类型
		rv := reflect.ValueOf(v)
		if rv.Kind() == reflect.String && rv.Len() > cfg.MaxStringLen {
			return fmt.Errorf("字段'%s'长度超过限制", fieldName)
		}
	}

	return nil
}
