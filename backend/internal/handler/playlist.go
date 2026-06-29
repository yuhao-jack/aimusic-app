package handler

import (
	"fmt"
	"net/http"
	"strconv"
	"time"
	"encoding/json"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
)

// GetUserPlaylists 获取用户歌单
func GetUserPlaylists(c *gin.Context) {
	userID := c.GetUint("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	offset := (page - 1) * pageSize

	var playlists []model.Playlist
	err := db.DB.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).Find(&playlists).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	// 查询真实总数，而非当前页记录数
	var total int64
	db.DB.Model(&model.Playlist{}).Where("user_id = ?", userID).Count(&total)

	utils.Success(c, gin.H{
		"list":  playlists,
		"total": total,
	})
}

// GetPlaylistDetail 获取歌单详情
func GetPlaylistDetail(c *gin.Context) {
	playlistIDStr := c.Param("playlist_id")
	playlistID, err := strconv.ParseUint(playlistIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌单ID错误")
		return
	}

	var playlist model.Playlist
	if err := db.DB.First(&playlist, playlistID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "歌单不存在")
		return
	}

	// 如果是私有歌单，检查是否是作者本人
	if playlist.IsPublic != 1 {
		userIDVal, exists := c.Get("user_id")
		if !exists {
			utils.Fail(c, http.StatusForbidden, "歌单不可访问")
			return
		}
		userID, ok := userIDVal.(uint)
		if !ok || userID != playlist.UserID {
			utils.Fail(c, http.StatusForbidden, "歌单不可访问")
			return
		}
	}

	// 获取歌单中的歌曲
	var playlistSongs []model.PlaylistSong
	err = db.DB.Where("playlist_id = ?", playlistID).
		Order("sort_order ASC, created_at ASC").Find(&playlistSongs).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询歌单歌曲失败")
		return
	}

	// 获取歌曲详情
	var songIDs []uint
	for _, ps := range playlistSongs {
		songIDs = append(songIDs, ps.SongID)
	}

	var songs []model.Song
	if len(songIDs) > 0 {
		err = db.DB.Where("id IN ?", songIDs).Find(&songs).Error
		if err != nil {
			utils.Fail(c, http.StatusInternalServerError, "查询歌曲失败")
			return
		}
	}

	utils.Success(c, gin.H{
		"playlist": playlist,
		"songs":    songs,
	})
}

// CreatePlaylist 创建歌单
func CreatePlaylist(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		IsPublic    int8   `json:"is_public"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	playlist := model.Playlist{
		UserID:      userID,
		Name:        req.Name,
		Description: req.Description,
		IsPublic:    req.IsPublic,
	}

	if err := db.DB.Create(&playlist).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "创建歌单失败")
		return
	}

	utils.Success(c, playlist)
}

// UpdatePlaylist 更新歌单
func UpdatePlaylist(c *gin.Context) {
	userID := c.GetUint("user_id")
	playlistIDStr := c.Param("playlist_id")
	playlistID, err := strconv.ParseUint(playlistIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌单ID错误")
		return
	}

	var playlist model.Playlist
	if err := db.DB.First(&playlist, playlistID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "歌单不存在")
		return
	}

	// 检查是否是歌单作者
	if playlist.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "无权修改此歌单")
		return
	}

	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		IsPublic    *int8  `json:"is_public"`
		Cover       string `json:"cover"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}
	if req.IsPublic != nil {
		updates["is_public"] = *req.IsPublic
	}
	if req.Cover != "" {
		updates["cover"] = req.Cover
	}

	if len(updates) > 0 {
		if err := db.DB.Model(&playlist).Updates(updates).Error; err != nil {
			utils.Fail(c, http.StatusInternalServerError, "更新歌单失败")
			return
		}
	}

	utils.Success(c, playlist)
}

// DeletePlaylist 删除歌单
func DeletePlaylist(c *gin.Context) {
	userID := c.GetUint("user_id")
	playlistIDStr := c.Param("playlist_id")
	playlistID, err := strconv.ParseUint(playlistIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌单ID错误")
		return
	}

	var playlist model.Playlist
	if err := db.DB.First(&playlist, playlistID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "歌单不存在")
		return
	}

	// 检查是否是歌单作者
	if playlist.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "无权删除此歌单")
		return
	}

	// 事务删除
	err = db.DB.Transaction(func(tx *gorm.DB) error {
		// 删除歌单歌曲关联
		if err := tx.Where("playlist_id = ?", playlistID).Delete(&model.PlaylistSong{}).Error; err != nil {
			return err
		}
		// 删除歌单点赞
		if err := tx.Where("playlist_id = ?", playlistID).Delete(&model.PlaylistLike{}).Error; err != nil {
			return err
		}
		// 删除歌单
		if err := tx.Delete(&playlist).Error; err != nil {
			return err
		}
		return nil
	})

	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "删除歌单失败")
		return
	}

	utils.Success(c, nil)
}

// AddSongToPlaylist 添加歌曲到歌单
func AddSongToPlaylist(c *gin.Context) {
	userID := c.GetUint("user_id")
	playlistIDStr := c.Param("playlist_id")
	playlistID, err := strconv.ParseUint(playlistIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌单ID错误")
		return
	}

	var req struct {
		SongID uint `json:"song_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	var playlist model.Playlist
	if err := db.DB.First(&playlist, playlistID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "歌单不存在")
		return
	}

	// 检查是否是歌单作者
	if playlist.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "无权修改此歌单")
		return
	}

	// 检查歌曲是否已存在
	var existing model.PlaylistSong
	err = db.DB.Where("playlist_id = ? AND song_id = ?", playlistID, req.SongID).First(&existing).Error
	if err == nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲已在歌单中")
		return
	}

	// 获取当前最大排序
	var maxSortOrder int
	db.DB.Model(&model.PlaylistSong{}).Where("playlist_id = ?", playlistID).
		Select("COALESCE(MAX(sort_order), 0)").Scan(&maxSortOrder)

	// 添加歌曲到歌单
	playlistSong := model.PlaylistSong{
		PlaylistID: uint(playlistID),
		SongID:     req.SongID,
		SortOrder:  maxSortOrder + 1,
	}

	// 使用事务保证添加歌曲和更新计数的原子性
	tx := db.DB.Begin()

	if err := tx.Create(&playlistSong).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "添加歌曲失败")
		return
	}

	// 更新歌单歌曲数量
	if err := tx.Model(&playlist).UpdateColumn("song_count", gorm.Expr("song_count + 1")).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "添加歌曲失败")
		return
	}

	tx.Commit()

	utils.Success(c, nil)
}

// RemoveSongFromPlaylist 从歌单移除歌曲
func RemoveSongFromPlaylist(c *gin.Context) {
	userID := c.GetUint("user_id")
	playlistIDStr := c.Param("playlist_id")
	playlistID, err := strconv.ParseUint(playlistIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌单ID错误")
		return
	}

	songIDStr := c.Param("song_id")
	songID, err := strconv.ParseUint(songIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲ID错误")
		return
	}

	var playlist model.Playlist
	if err := db.DB.First(&playlist, playlistID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "歌单不存在")
		return
	}

	// 检查是否是歌单作者
	if playlist.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "无权修改此歌单")
		return
	}

	// 使用事务保证移除歌曲和更新计数的原子性
	tx := db.DB.Begin()

	// 删除歌单歌曲关联
	result := tx.Where("playlist_id = ? AND song_id = ?", playlistID, songID).Delete(&model.PlaylistSong{})
	if result.Error != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "移除歌曲失败")
		return
	}

	if result.RowsAffected > 0 {
		// 更新歌单歌曲数量
		if err := tx.Model(&playlist).UpdateColumn("song_count", gorm.Expr("CASE WHEN song_count > 0 THEN song_count - 1 ELSE 0 END")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "移除歌曲失败")
			return
		}
	}

	tx.Commit()

	utils.Success(c, nil)
}

// GetRecommendPlaylists 获取推荐歌单（带Redis缓存，5分钟过期）
func GetRecommendPlaylists(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// 构建缓存key（包含分页参数）
	cacheKey := fmt.Sprintf("cache:playlist:recommend:%d:%d", page, pageSize)

	// 尝试从Redis缓存获取数据（如果Redis可用）
	if db.Redis != nil {
		cachedData, err := db.Redis.Get(db.Ctx, cacheKey).Result()
		if err == nil {
			// 缓存命中，直接返回
			c.Data(http.StatusOK, "application/json; charset=utf-8", []byte(cachedData))
			return
		}
	}

	offset := (page - 1) * pageSize

	// 定义包含创建者信息的歌单结构体
	type PlaylistWithCreator struct {
		model.Playlist
		CreatorName   string `json:"creator_name"`
		CreatorAvatar string `json:"creator_avatar"`
	}

	var playlists []PlaylistWithCreator
	// 只查询歌单列表需要的字段
	err := db.DB.Table("playlists").
		Select("playlists.id, playlists.user_id, playlists.name, playlists.description, playlists.cover, playlists.song_count, playlists.play_count, playlists.like_count, playlists.created_at, users.nickname as creator_name, users.avatar as creator_avatar").
		Joins("LEFT JOIN users ON users.id = playlists.user_id").
		Where("playlists.is_public = 1").
		Order("playlists.like_count DESC, playlists.play_count DESC, playlists.created_at DESC").
		Offset(offset).Limit(pageSize).Find(&playlists).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	// 构建响应数据
	response := utils.Response{
		Code: 0,
		Msg:  "success",
		Data: playlists,
	}

	// 序列化响应数据并存入Redis缓存（如果Redis可用）
	jsonData, err := json.Marshal(response)
	if err == nil && db.Redis != nil {
		// 将数据存入Redis缓存，设置5分钟过期
		db.Redis.Set(db.Ctx, cacheKey, string(jsonData), 5*time.Minute)
	}

	utils.Success(c, playlists)
}

// LikePlaylist 点赞/取消点赞歌单
func LikePlaylist(c *gin.Context) {
	userID := c.GetUint("user_id")
	playlistIDStr := c.Param("playlist_id")
	playlistID, err := strconv.ParseUint(playlistIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌单ID错误")
		return
	}

	// 检查是否已点赞
	var existing model.PlaylistLike
	err = db.DB.Where("playlist_id = ? AND user_id = ?", playlistID, userID).First(&existing).Error

	if err == nil {
		// 取消点赞，使用事务保证原子性
		tx := db.DB.Begin()

		if err := tx.Delete(&existing).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "操作失败")
			return
		}

		if err := tx.Model(&model.Playlist{}).Where("id = ?", playlistID).
			UpdateColumn("like_count", gorm.Expr("CASE WHEN like_count > 0 THEN like_count - 1 ELSE 0 END")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "操作失败")
			return
		}

		tx.Commit()

		// 清除推荐歌单缓存（点赞数变化影响排序）
		clearPlaylistRecommendCache()

		utils.SuccessWithMsg(c, "取消点赞成功", gin.H{"liked": false})
	} else {
		// 点赞，使用事务保证原子性
		tx := db.DB.Begin()

		like := model.PlaylistLike{
			PlaylistID: uint(playlistID),
			UserID:     userID,
		}
		if err := tx.Create(&like).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "操作失败")
			return
		}

		if err := tx.Model(&model.Playlist{}).Where("id = ?", playlistID).
			UpdateColumn("like_count", gorm.Expr("like_count + 1")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "操作失败")
			return
		}

		tx.Commit()

		// 清除推荐歌单缓存（点赞数变化影响排序）
		clearPlaylistRecommendCache()

		// 创建通知（喜欢了你的歌单）
		var playlist model.Playlist
		if db.DB.First(&playlist, playlistID).Error == nil && playlist.UserID != userID {
			content := "喜欢了你的歌单：“" + playlist.Name + "”"
			CreateNotification(playlist.UserID, userID, "like", "playlist", uint(playlistID), content)
		}

		utils.SuccessWithMsg(c, "点赞成功", gin.H{"liked": true})
	}
}

// GetUserWorks 获取用户作品 - 已在user.go中定义
// func GetUserWorks(c *gin.Context) {
// 	utils.Success(c, []interface{}{})
// }

// GetUserLikes 获取用户喜欢的歌曲 - 已在user.go中定义
// func GetUserLikes(c *gin.Context) {
// 	utils.Success(c, []interface{}{})
// }

// AddComment 添加评论 - 已在music.go中定义
// func AddComment(c *gin.Context) {
// 	utils.Success(c, nil)
// }

// GetSongComments 获取歌曲评论 - 已在music.go中定义
// func GetSongComments(c *gin.Context) {
// 	utils.Success(c, []interface{}{})
// }

// clearPlaylistRecommendCache 清除推荐歌单缓存
func clearPlaylistRecommendCache() {
	// 如果Redis不可用，跳过缓存清除
	if db.Redis == nil {
		return
	}

	// 使用模式匹配删除所有推荐歌单缓存
	keys, err := db.Redis.Keys(db.Ctx, "cache:playlist:recommend:*").Result()
	if err == nil && len(keys) > 0 {
		db.Redis.Del(db.Ctx, keys...)
	}
}
