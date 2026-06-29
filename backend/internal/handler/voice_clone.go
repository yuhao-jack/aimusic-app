package handler

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
)

// GetVoiceClones 获取用户的音色列表
func GetVoiceClones(c *gin.Context) {
	userID := c.GetUint("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	offset := (page - 1) * pageSize

	var voices []model.VoiceClone
	var total int64

	db.DB.Model(&model.VoiceClone{}).Where("user_id = ?", userID).Count(&total)
	err := db.DB.Where("user_id = ?", userID).Order("created_at DESC").Limit(pageSize).Offset(offset).Find(&voices).Error

	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	utils.Success(c, gin.H{
		"list":  voices,
		"total": total,
		"page":  page,
	})
}

// GetVoiceClone 获取单个音色详情
func GetVoiceClone(c *gin.Context) {
	userID := c.GetUint("user_id")
	voiceIDStr := c.Param("id")
	voiceID, err := strconv.ParseUint(voiceIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "音色ID错误")
		return
	}

	var voice model.VoiceClone
	err = db.DB.Where("id = ? AND user_id = ?", voiceID, userID).First(&voice).Error
	if err != nil {
		utils.Fail(c, http.StatusNotFound, "音色不存在")
		return
	}

	utils.Success(c, voice)
}

// CreateVoiceClone 创建音色克隆任务
func CreateVoiceClone(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		AudioURL    string `json:"audio_url" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 创建音色克隆任务
	voice := model.VoiceClone{
		UserID:      userID,
		Name:        req.Name,
		Description: req.Description,
		VoiceType:   "cloned",
		Status:      "pending",
		Progress:    0,
		AudioURL:    req.AudioURL,
	}

	if err := db.DB.Create(&voice).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "创建失败")
		return
	}

	// 将任务推入Redis Stream，由后台消费者处理
	err := db.Redis.XAdd(db.Ctx, &redis.XAddArgs{
		Stream: "voice_clone_tasks",
		Values: map[string]interface{}{
			"task_id":   fmt.Sprintf("%d", voice.ID),
			"user_id":   fmt.Sprintf("%d", userID),
			"audio_url": voice.AudioURL,
		},
	}).Err()
	if err != nil {
		// Redis推送失败不影响任务创建，消费者可后续重试
		log.Printf("推送音色克隆任务到Redis失败: %v", err)
	}

	utils.Success(c, voice)
}

// UpdateVoiceClone 更新音色信息
func UpdateVoiceClone(c *gin.Context) {
	userID := c.GetUint("user_id")
	voiceIDStr := c.Param("id")
	voiceID, err := strconv.ParseUint(voiceIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "音色ID错误")
		return
	}

	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	var voice model.VoiceClone
	err = db.DB.Where("id = ? AND user_id = ?", voiceID, userID).First(&voice).Error
	if err != nil {
		utils.Fail(c, http.StatusNotFound, "音色不存在")
		return
	}

	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}

	if len(updates) > 0 {
		if err := db.DB.Model(&voice).Updates(updates).Error; err != nil {
			utils.Fail(c, http.StatusInternalServerError, "更新失败")
			return
		}
	}

	utils.Success(c, voice)
}

// DeleteVoiceClone 删除音色
func DeleteVoiceClone(c *gin.Context) {
	userID := c.GetUint("user_id")
	voiceIDStr := c.Param("id")
	voiceID, err := strconv.ParseUint(voiceIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "音色ID错误")
		return
	}

	result := db.DB.Where("id = ? AND user_id = ?", voiceID, userID).Delete(&model.VoiceClone{})
	if result.Error != nil {
		utils.Fail(c, http.StatusInternalServerError, "删除失败")
		return
	}
	if result.RowsAffected == 0 {
		utils.Fail(c, http.StatusNotFound, "音色不存在")
		return
	}

	utils.Success(c, nil)
}
