package handler

import (
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
)

// GetMVs 获取用户的MV列表
func GetMVs(c *gin.Context) {
	userID := c.GetUint("user_id")
	var mvs []model.MV
	err := db.DB.Where("user_id = ?", userID).Order("created_at DESC").Find(&mvs).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}
	utils.Success(c, mvs)
}

// CreateMV 创建MV生成任务
func CreateMV(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req struct {
		SongID   uint   `json:"song_id" binding:"required"`
		Name     string `json:"name" binding:"required"`
		Template string `json:"template"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}
	mv := model.MV{
		UserID:   userID,
		SongID:   req.SongID,
		Name:     req.Name,
		Template: req.Template,
		Status:   "pending",
	}
	if err := db.DB.Create(&mv).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "创建失败")
		return
	}
	utils.Success(c, mv)
}

// DeleteMV 删除MV
func DeleteMV(c *gin.Context) {
	userID := c.GetUint("user_id")
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数格式错误")
		return
	}
	result := db.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&model.MV{})
	if result.RowsAffected == 0 {
		utils.Fail(c, http.StatusNotFound, "MV不存在")
		return
	}
	utils.Success(c, nil)
}
