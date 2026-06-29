package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// CreateDiary 创建音乐日记
func CreateDiary(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		Content  string `json:"content" binding:"required"`
		Mood     string `json:"mood"`
		SongID   uint   `json:"song_id"`
		IsPublic bool   `json:"is_public"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "请输入日记内容")
		return
	}

	diary := model.MusicDiary{
		UserID:   userID,
		Content:  req.Content,
		Mood:     req.Mood,
		SongID:   req.SongID,
		IsPublic: req.IsPublic,
	}

	// 如果关联了歌曲，获取歌曲信息
	if req.SongID > 0 {
		var song model.Song
		if err := db.DB.First(&song, req.SongID).Error; err == nil {
			diary.SongTitle = song.Title
			diary.SongCover = song.Cover
		}
	}

	if err := db.DB.Create(&diary).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "发布失败")
		return
	}

	utils.Success(c, diary)
}

// GetDiaryList 获取日记列表
func GetDiaryList(c *gin.Context) {
	userID := c.GetUint("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var diaries []model.MusicDiary
	var total int64

	db.DB.Model(&model.MusicDiary{}).Where("user_id = ?", userID).Count(&total)
	db.DB.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).
		Find(&diaries)

	utils.Success(c, gin.H{
		"list":  diaries,
		"total": total,
	})
}

// DeleteDiary 删除日记
func DeleteDiary(c *gin.Context) {
	userID := c.GetUint("user_id")
	diaryID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "ID格式错误")
		return
	}

	var diary model.MusicDiary
	if err := db.DB.First(&diary, diaryID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "日记不存在")
		return
	}

	if diary.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "无权删除")
		return
	}

	db.DB.Delete(&diary)
	utils.Success(c, nil)
}
