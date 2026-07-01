package handler

import (
	"net/http"
	"strconv"
	"time"
	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
)

// GetPlayHistory 获取播放历史
func GetPlayHistory(c *gin.Context) {
	userID := c.GetUint("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	offset := (page - 1) * pageSize

	// 查询播放历史，按播放时间倒序，去重（同一首歌只显示最近一次）
	var histories []model.PlayHistory
	err := db.DB.Raw(`
		SELECT ph.* 
		FROM play_histories ph
		INNER JOIN (
			SELECT song_id, MAX(played_at) as max_played_at
			FROM play_histories
			WHERE user_id = ?
			GROUP BY song_id
		) t ON ph.song_id = t.song_id AND ph.played_at = t.max_played_at
		WHERE ph.user_id = ?
		ORDER BY ph.played_at DESC
		LIMIT ? OFFSET ?
	`, userID, userID, pageSize, offset).Scan(&histories).Error

	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	// 获取歌曲详情
	var songIDs []uint
	for _, h := range histories {
		songIDs = append(songIDs, h.SongID)
	}

	var songs []model.Song
	if len(songIDs) > 0 {
		err = db.DB.Where("id IN ?", songIDs).Find(&songs).Error
		if err != nil {
			utils.Fail(c, http.StatusInternalServerError, "查询歌曲失败")
			return
		}
	}

	// 构建songID到song的映射
	songMap := make(map[uint]model.Song)
	for _, s := range songs {
		songMap[s.ID] = s
	}

	// 组装结果
	var result []map[string]interface{}
	for _, h := range histories {
		if song, ok := songMap[h.SongID]; ok {
			result = append(result, map[string]interface{}{
				"id":         h.ID,
				"song":       song,
				"played_at":  h.PlayedAt,
				"created_at": h.CreatedAt,
			})
		}
	}

	utils.Success(c, gin.H{
		"list":  result,
		"total": len(result),
	})
}

// AddPlayHistory 添加播放历史
func AddPlayHistory(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		SongID uint `json:"song_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 添加播放历史
	history := model.PlayHistory{
		UserID:   userID,
		SongID:   req.SongID,
		PlayedAt: time.Now().Unix(),
	}

	if err := db.DB.Create(&history).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "添加失败")
		return
	}

	utils.Success(c, nil)
}

// ClearPlayHistory 清空播放历史
func ClearPlayHistory(c *gin.Context) {
	userID := c.GetUint("user_id")

	if err := db.DB.Where("user_id = ?", userID).Delete(&model.PlayHistory{}).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "清空失败")
		return
	}

	utils.Success(c, nil)
}

// RemovePlayHistoryItem 删除单个播放历史
func RemovePlayHistoryItem(c *gin.Context) {
	userID := c.GetUint("user_id")
	historyIDStr := c.Param("id")
	historyID, err := strconv.ParseUint(historyIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "历史记录ID错误")
		return
	}

	if err := db.DB.Where("id = ? AND user_id = ?", historyID, userID).Delete(&model.PlayHistory{}).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "删除失败")
		return
	}

	utils.Success(c, nil)
}
