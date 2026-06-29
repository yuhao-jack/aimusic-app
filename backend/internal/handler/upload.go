package handler

import (
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// UploadFile 通用文件上传接口
func UploadFile(c *gin.Context) {
	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "请选择文件")
		return
	}

	// 检查文件大小 (限制 10MB)
	const maxFileSize = 10 * 1024 * 1024
	if file.Size > maxFileSize {
		utils.Fail(c, http.StatusBadRequest, "文件大小不能超过10MB")
		return
	}

	// 检查文件类型
	ext := filepath.Ext(file.Filename)
	ext = strings.ToLower(ext)
	allowedExts := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
		".mp3":  true,
		".wav":  true,
		".m4a":  true,
	}
	if !allowedExts[ext] {
		utils.Fail(c, http.StatusBadRequest, "不支持的文件类型")
		return
	}

	// 生成新的文件名
	newFileName := uuid.New().String() + ext

	// 按日期分目录存储
	now := time.Now()
	datePath := now.Format("2006/01/02")
	uploadDir := filepath.Join(config.AppConfig.Upload.Path, datePath)

	// 创建目录
	if err := utils.EnsureDir(uploadDir); err != nil {
		utils.Fail(c, http.StatusInternalServerError, "创建目录失败")
		return
	}

	// 保存文件
	dstPath := filepath.Join(uploadDir, newFileName)
	if err := c.SaveUploadedFile(file, dstPath); err != nil {
		utils.Fail(c, http.StatusInternalServerError, "保存文件失败")
		return
	}

	// 返回文件访问 URL
	fileURL := config.AppConfig.Upload.BaseURL + "/" + datePath + "/" + newFileName

	utils.Success(c, gin.H{
		"url":  fileURL,
		"name": newFileName,
		"size": file.Size,
	})
}
