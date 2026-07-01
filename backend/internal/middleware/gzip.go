package middleware

import (
	"bytes"
	"compress/gzip"
	"io"
	"net/http"
	"strconv"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
)

// Gzip压缩中间件
// 对大于1KB的响应自动压缩

var gzipPool = sync.Pool{
	New: func() interface{} {
		return gzip.NewWriter(nil)
	},
}

// GzipResponseWriter 自定义响应写入器，支持Gzip压缩
type GzipResponseWriter struct {
	gin.ResponseWriter
	writer *gzip.Writer
	buf    *bytes.Buffer
}

// Write 写入响应数据
func (g *GzipResponseWriter) Write(data []byte) (int, error) {
	return g.writer.Write(data)
}

// WriteString 写入字符串响应数据
func (g *GzipResponseWriter) WriteString(s string) (int, error) {
	return g.writer.Write([]byte(s))
}

// Close 关闭Gzip写入器并刷新缓冲区
func (g *GzipResponseWriter) Close() error {
	if err := g.writer.Close(); err != nil {
		return err
	}
	// 将压缩后的数据写入原始响应
	g.ResponseWriter.Header().Set("Content-Length", strconv.Itoa(g.buf.Len()))
	_, err := g.ResponseWriter.Write(g.buf.Bytes())
	return err
}

// GzipMiddleware Gzip压缩中间件
func GzipMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查客户端是否支持Gzip压缩
		if !strings.Contains(c.Request.Header.Get("Accept-Encoding"), "gzip") {
			c.Next()
			return
		}

		// 检查请求方法，只对响应体进行压缩
		if c.Request.Method == http.MethodHead {
			c.Next()
			return
		}

		// 创建缓冲区和Gzip写入器
		buf := &bytes.Buffer{}
		writer := gzipPool.Get().(*gzip.Writer)
		writer.Reset(buf)
		defer gzipPool.Put(writer)

		// 创建自定义响应写入器
		gzipWriter := &GzipResponseWriter{
			ResponseWriter: c.Writer,
			writer:         writer,
			buf:            buf,
		}

		// 替换响应写入器
		c.Writer = gzipWriter

		// 设置响应头
		c.Header("Content-Encoding", "gzip")
		c.Header("Vary", "Accept-Encoding")

		// 处理请求
		c.Next()

		// 关闭Gzip写入器
		if err := gzipWriter.Close(); err != nil {
			// 如果压缩失败，返回原始响应
			c.Writer = gzipWriter.ResponseWriter
			c.Header("Content-Encoding", "")
			c.Header("Vary", "")
		}
	}
}

// ShouldCompress 判断是否应该压缩响应
func ShouldCompress(c *gin.Context) bool {
	// 检查Content-Type，只压缩文本类型的响应
	contentType := c.Writer.Header().Get("Content-Type")
	if contentType == "" {
		return true
	}

	// 压缩的Content-Type列表
	compressibleTypes := []string{
		"application/json",
		"application/javascript",
		"application/xml",
		"text/",
		"application/xhtml+xml",
		"application/rss+xml",
		"application/atom+xml",
		"image/svg+xml",
	}

	for _, t := range compressibleTypes {
		if strings.Contains(contentType, t) {
			return true
		}
	}

	return false
}

// GzipMiddlewareWithThreshold 带阈值的Gzip压缩中间件
// 只有当响应大小超过阈值时才进行压缩
func GzipMiddlewareWithThreshold(threshold int) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查客户端是否支持Gzip压缩
		if !strings.Contains(c.Request.Header.Get("Accept-Encoding"), "gzip") {
			c.Next()
			return
		}

		// 检查请求方法，只对响应体进行压缩
		if c.Request.Method == http.MethodHead {
			c.Next()
			return
		}

		// 检查Content-Type，只压缩文本类型的响应
		if !ShouldCompress(c) {
			c.Next()
			return
		}

		// 创建缓冲区和Gzip写入器
		buf := &bytes.Buffer{}
		writer := gzipPool.Get().(*gzip.Writer)
		writer.Reset(buf)
		defer gzipPool.Put(writer)

		// 创建自定义响应写入器
		gzipWriter := &GzipResponseWriter{
			ResponseWriter: c.Writer,
			writer:         writer,
			buf:            buf,
		}

		// 替换响应写入器
		c.Writer = gzipWriter

		// 设置响应头
		c.Header("Content-Encoding", "gzip")
		c.Header("Vary", "Accept-Encoding")

		// 处理请求
		c.Next()

		// 检查响应大小是否超过阈值
		if buf.Len() < threshold {
			// 响应太小，不压缩
			c.Writer = gzipWriter.ResponseWriter
			c.Header("Content-Encoding", "")
			c.Header("Vary", "")
			// 写入原始数据
			c.Writer.Write(buf.Bytes())
			return
		}

		// 关闭Gzip写入器
		if err := gzipWriter.Close(); err != nil {
			// 如果压缩失败，返回原始响应
			c.Writer = gzipWriter.ResponseWriter
			c.Header("Content-Encoding", "")
			c.Header("Vary", "")
		}
	}
}

// CompressData 压缩数据
func CompressData(data []byte) ([]byte, error) {
	buf := &bytes.Buffer{}
	writer := gzip.NewWriter(buf)
	
	_, err := writer.Write(data)
	if err != nil {
		return nil, err
	}
	
	if err := writer.Close(); err != nil {
		return nil, err
	}
	
	return buf.Bytes(), nil
}

// DecompressData 解压数据
func DecompressData(data []byte) ([]byte, error) {
	reader, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, err
	}
	defer reader.Close()
	
	return io.ReadAll(reader)
}