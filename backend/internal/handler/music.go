package handler

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
)

// GetRecommendSongs 获取推荐歌曲
func GetRecommendSongs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var songs []model.Song
	err := db.DB.Where("status = 1 AND is_public = 1").
		Order("play_count DESC, created_at DESC").
		Offset(offset).Limit(pageSize).Find(&songs).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	utils.Success(c, songs)
}

// GetRankSongs 获取榜单歌曲
func GetRankSongs(c *gin.Context) {
	rankType := c.Param("type")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var orderBy string
	switch rankType {
	case "hot":
		orderBy = "play_count DESC"
	case "new":
		orderBy = "created_at DESC"
	case "like":
		orderBy = "like_count DESC"
	default:
		orderBy = "play_count DESC"
	}

	var songs []model.Song
	err := db.DB.Where("status = 1 AND is_public = 1").
		Order(orderBy).Offset(offset).Limit(pageSize).Find(&songs).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	utils.Success(c, songs)
}

// SearchSongs 搜索歌曲
func SearchSongs(c *gin.Context) {
	keyword := c.Query("keyword")
	if keyword == "" {
		utils.Fail(c, http.StatusBadRequest, "搜索关键词不能为空")
		return
	}
	// 关键词长度限制
	if len([]rune(keyword)) > 100 {
		utils.Fail(c, http.StatusBadRequest, "搜索关键词过长")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	// 转义 LIKE 特殊字符，防止注入
	keyword = strings.ReplaceAll(keyword, "%", "\\%")
	keyword = strings.ReplaceAll(keyword, "_", "\\_")

	var songs []model.Song
	err := db.DB.Where("status = 1 AND is_public = 1 AND (title LIKE ? OR singer LIKE ?)",
		"%"+keyword+"%", "%"+keyword+"%").
		Order("play_count DESC").Offset(offset).Limit(pageSize).Find(&songs).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "搜索失败")
		return
	}

	utils.Success(c, songs)
}

// GetSongDetail 获取歌曲详情
func GetSongDetail(c *gin.Context) {
	songIDStr := c.Param("song_id")
	songID, err := strconv.ParseUint(songIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲ID错误")
		return
	}

	var song model.Song
	if err := db.DB.First(&song, songID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "歌曲不存在")
		return
	}

	if song.Status != 1 || song.IsPublic != 1 {
		// 检查是否是歌曲作者本人
		userIDVal, exists := c.Get("user_id")
		if !exists {
			utils.Fail(c, http.StatusForbidden, "歌曲不可访问")
			return
		}
		userID, ok := userIDVal.(uint)
		if !ok || userID != song.UserID {
			utils.Fail(c, http.StatusForbidden, "歌曲不可访问")
			return
		}
	}

	utils.Success(c, song)
}

// IncrementPlayCount 增加播放次数
func IncrementPlayCount(c *gin.Context) {
	songIDStr := c.Param("song_id")
	songID, err := strconv.ParseUint(songIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲ID错误")
		return
	}

	// 原子增加播放次数
	err = db.DB.Model(&model.Song{}).Where("id = ?", songID).UpdateColumn("play_count", gorm.Expr("play_count + 1")).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "更新失败")
		return
	}

	utils.Success(c, nil)
}

// LikeSong 点赞/取消点赞歌曲
func LikeSong(c *gin.Context) {
	userID := c.GetUint("user_id")
	songIDStr := c.Param("song_id")
	songID, err := strconv.ParseUint(songIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲ID错误")
		return
	}

	// 使用数据库Like表存储点赞状态，替代Redis
	var existingLike model.Like
	err = db.DB.Where("user_id = ? AND target_id = ? AND like_type = ?", userID, uint(songID), "song").First(&existingLike).Error

	if err == nil {
		// 已点赞，取消点赞（使用事务保证原子性）
		tx := db.DB.Begin()
		if err := tx.Delete(&existingLike).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "取消点赞失败")
			return
		}
		if err := tx.Model(&model.Song{}).Where("id = ?", songID).UpdateColumn("like_count", gorm.Expr("CASE WHEN like_count > 0 THEN like_count - 1 ELSE 0 END")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "取消点赞失败")
			return
		}
		tx.Commit()
		utils.SuccessWithMsg(c, "取消点赞成功", gin.H{"liked": false})
	} else {
		// 未点赞，添加点赞记录（使用事务保证原子性）
		tx := db.DB.Begin()
		like := model.Like{
			UserID:   userID,
			TargetID: uint(songID),
			LikeType: "song",
		}
		if err := tx.Create(&like).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "点赞失败")
			return
		}
		if err := tx.Model(&model.Song{}).Where("id = ?", songID).UpdateColumn("like_count", gorm.Expr("like_count + 1")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "点赞失败")
			return
		}
		tx.Commit()

		// 创建通知（喜欢了你的歌曲）
		var song model.Song
		if db.DB.First(&song, songID).Error == nil && song.UserID != userID {
			content := "喜欢了你的歌曲：" + song.Title + "”"
			CreateNotification(song.UserID, userID, "like", "song", uint(songID), content)
		}

		utils.SuccessWithMsg(c, "点赞成功", gin.H{"liked": true})
	}
}

// AddComment 添加评论
func AddComment(c *gin.Context) {
	userID := c.GetUint("user_id")
	songIDStr := c.Param("song_id")
	songID, err := strconv.ParseUint(songIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲ID错误")
		return
	}

	var req struct {
		Content string `json:"content" binding:"required"`
		ParentID uint `json:"parent_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}
	// 评论内容长度限制
	if len([]rune(req.Content)) > 1000 {
		utils.Fail(c, http.StatusBadRequest, "评论内容不能超过1000字")
		return
	}

	comment := model.Comment{
		UserID:   userID,
		SongID:   uint(songID),
		Content:  req.Content,
		ParentID: req.ParentID,
	}

	if err := db.DB.Create(&comment).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "添加评论失败")
		return
	}

	// 创建通知
	var song model.Song
	if err := db.DB.First(&song, songID).Error; err == nil && song.UserID != userID {
		if req.ParentID > 0 {
			// 回复评论，通知被回复者
			var parentComment model.Comment
			if db.DB.First(&parentComment, req.ParentID).Error == nil && parentComment.UserID != userID {
				content := "回复了你的评论"
				CreateNotification(parentComment.UserID, userID, "reply", "comment", uint(songID), content)
			}
		} else {
			content := "评论了你的歌曲"
			CreateNotification(song.UserID, userID, "comment", "song", uint(songID), content)
		}
	}

	utils.Success(c, comment)
}

// GetSongComments 获取歌曲评论
func GetSongComments(c *gin.Context) {
	songIDStr := c.Param("song_id")
	songID, err := strconv.ParseUint(songIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "歌曲ID错误")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var comments []model.Comment
	err = db.DB.Where("song_id = ? AND parent_id = 0", songID).
		Offset(offset).Limit(pageSize).Order("created_at desc").Find(&comments).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询评论失败")
		return
	}

	utils.Success(c, comments)
}

// CreateTogetherRoom 创建一起听房间
func CreateTogetherRoom(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		SongID      uint   `json:"song_id" binding:"required"`
		Name        string `json:"name"`
		Password    string `json:"password"`
		Description string `json:"description"`
		MaxMembers  int    `json:"max_members"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 默认房间名
	if req.Name == "" {
		req.Name = "一起听歌"
	}
	// 默认最大成员数
	if req.MaxMembers <= 0 || req.MaxMembers > 50 {
		req.MaxMembers = 10
	}

	// 检查用户是否已有进行中的房间
	var existingRoom model.TogetherRoom
	if err := db.DB.Where("creator_id = ? AND status = 1", userID).First(&existingRoom).Error; err == nil {
		utils.Success(c, gin.H{
			"room_code": existingRoom.RoomCode,
			"room_id":   existingRoom.ID,
			"msg":       "你已有进行中的房间",
		})
		return
	}

	// 生成6位随机房间码
	roomCode := fmt.Sprintf("%06d", rand.Intn(1000000))

	room := model.TogetherRoom{
		RoomCode:    roomCode,
		Name:        req.Name,
		Password:    req.Password,
		Description: req.Description,
		CreatorID:   userID,
		SongID:      req.SongID,
		Status:      1,
		MaxMembers:  req.MaxMembers,
		Members:     "[]",
	}

	// 使用事务保证房间创建和成员添加的原子性
	tx := db.DB.Begin()
	if err := tx.Create(&room).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建房间失败")
		return
	}

	// 创建者自动加入房间成员表
	member := model.RoomMember{
		RoomID: room.ID,
		UserID: userID,
		Role:   1, // 房主
	}
	if err := tx.Create(&member).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建房间失败")
		return
	}

	// 兼容旧逻辑：更新Members JSON字段
	members := []uint{userID}
	membersJSON, _ := json.Marshal(members)
	room.Members = string(membersJSON)
	if err := tx.Save(&room).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建房间失败")
		return
	}
	tx.Commit()

	utils.Success(c, gin.H{
		"room_code": roomCode,
		"room_id":   room.ID,
	})
}

// JoinTogetherRoom 加入一起听房间
func JoinTogetherRoom(c *gin.Context) {
	userID := c.GetUint("user_id")
	roomCode := c.Param("room_code")

	var req struct {
		Password string `json:"password"`
	}
	// 允许空body（密码为空时可不传）
	c.ShouldBindJSON(&req)

	var room model.TogetherRoom
	if err := db.DB.Where("room_code = ? AND status = 1", roomCode).First(&room).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "房间不存在或已结束")
		return
	}

	// 验证密码
	if room.Password != "" && room.Password != req.Password {
		utils.Fail(c, http.StatusUnauthorized, "密码错误")
		return
	}

	// 检查是否已在房间（通过关联表查询）
	var existingMember model.RoomMember
	if err := db.DB.Where("room_id = ? AND user_id = ?", room.ID, userID).First(&existingMember).Error; err == nil {
		var song model.Song
		db.DB.First(&song, room.SongID)
		utils.Success(c, gin.H{"room": room, "song": song})
		return
	}

	// 查询当前房间成员数
	var memberCount int64
	db.DB.Model(&model.RoomMember{}).Where("room_id = ?", room.ID).Count(&memberCount)

	// 检查房间是否已满
	if int(memberCount) >= room.MaxMembers {
		utils.Fail(c, http.StatusBadRequest, "房间已满")
		return
	}

	// 添加成员到关联表
	newMember := model.RoomMember{
		RoomID: room.ID,
		UserID: userID,
		Role:   0, // 普通成员
	}
	// 使用事务保证成员添加和房间更新的原子性
	tx := db.DB.Begin()
	if err := tx.Create(&newMember).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "加入房间失败")
		return
	}

	// 兼容旧逻辑：更新Members JSON字段
	var members []uint
	json.Unmarshal([]byte(room.Members), &members)
	members = append(members, userID)
	newMembers, _ := json.Marshal(members)
	room.Members = string(newMembers)
	if err := tx.Save(&room).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "加入房间失败")
		return
	}
	tx.Commit()

	var song model.Song
	db.DB.First(&song, room.SongID)

	utils.Success(c, gin.H{"room": room, "song": song})
}

// LeaveTogetherRoom 离开一起听房间
func LeaveTogetherRoom(c *gin.Context) {
	userID := c.GetUint("user_id")
	roomIDStr := c.Param("room_id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数格式错误")
		return
	}

	var room model.TogetherRoom
	if err := db.DB.Where("id = ? AND status = 1", roomID).First(&room).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "房间不存在")
		return
	}

	// 从关联表中删除成员
	// 使用事务保证删除和房间更新的原子性
	tx := db.DB.Begin()
	if err := tx.Where("room_id = ? AND user_id = ?", room.ID, userID).Delete(&model.RoomMember{}).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "离开房间失败")
		return
	}

	// 查询剩余成员
	var remainingMembers []model.RoomMember
	tx.Where("room_id = ?", room.ID).Find(&remainingMembers)

	if len(remainingMembers) == 0 {
		// 无成员，结束房间
		room.Status = 2
	} else {
		// 如果离开的是房主，转让房主
		if room.CreatorID == userID {
			room.CreatorID = remainingMembers[0].UserID
			// 更新新房主角色
			tx.Model(&model.RoomMember{}).Where("room_id = ? AND user_id = ?", room.ID, remainingMembers[0].UserID).Update("role", 1)
		}
		// 兼容旧逻辑：更新Members JSON字段
		var newMemberIDs []uint
		for _, m := range remainingMembers {
			newMemberIDs = append(newMemberIDs, m.UserID)
		}
		newMembersJson, _ := json.Marshal(newMemberIDs)
		room.Members = string(newMembersJson)
	}

	if err := tx.Save(&room).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "离开房间失败")
		return
	}
	tx.Commit()
	utils.Success(c, nil)
}

// GetRoomInfo 获取房间信息
func GetRoomInfo(c *gin.Context) {
	roomIDStr := c.Param("room_id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数格式错误")
		return
	}

	var room model.TogetherRoom
	if err := db.DB.First(&room, roomID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "房间不存在")
		return
	}

	// 从关联表获取成员信息 — 批量查询避免N+1
	var roomMembers []model.RoomMember
	db.DB.Where("room_id = ?", room.ID).Find(&roomMembers)

	type MemberInfo struct {
		ID       uint   `json:"id"`
		Nickname string `json:"nickname"`
		Avatar   string `json:"avatar"`
		Role     int8   `json:"role"`
	}
	var memberList []MemberInfo
	if len(roomMembers) > 0 {
		var memberIDs []uint
		for _, rm := range roomMembers {
			memberIDs = append(memberIDs, rm.UserID)
		}
		var users []model.User
		db.DB.Where("id IN (?)", memberIDs).Find(&users)
		userMap := make(map[uint]model.User, len(users))
		for _, u := range users {
			userMap[u.ID] = u
		}
		for _, rm := range roomMembers {
			if u, ok := userMap[rm.UserID]; ok {
				memberList = append(memberList, MemberInfo{
					ID:       u.ID,
					Nickname: u.Nickname,
					Avatar:   u.Avatar,
					Role:     rm.Role,
				})
			}
		}
	}

	// 获取歌曲信息
	var song model.Song
	db.DB.First(&song, room.SongID)

	// 获取房主信息
	var creator model.User
	db.DB.First(&creator, room.CreatorID)

	utils.Success(c, gin.H{
		"room":         room,
		"song":         song,
		"members":      memberList,
		"creator_name": creator.Nickname,
		"has_password": room.Password != "",
	})
}

// UpdateRoom 房主更新房间信息
func UpdateRoom(c *gin.Context) {
	userID := c.GetUint("user_id")
	roomIDStr := c.Param("room_id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数格式错误")
		return
	}

	var room model.TogetherRoom
	if err := db.DB.First(&room, roomID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "房间不存在")
		return
	}

	if room.CreatorID != userID {
		utils.Fail(c, http.StatusForbidden, "只有房主可以修改房间")
		return
	}

	var req struct {
		Name        *string `json:"name"`
		Description *string `json:"description"`
		Password    *string `json:"password"`
		MaxMembers  *int    `json:"max_members"`
		SongID      *uint   `json:"song_id"`
		NowPlaying  *int8   `json:"now_playing"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	if req.Name != nil {
		room.Name = *req.Name
	}
	if req.Description != nil {
		room.Description = *req.Description
	}
	if req.Password != nil {
		room.Password = *req.Password
	}
	if req.MaxMembers != nil && *req.MaxMembers > 0 && *req.MaxMembers <= 50 {
		room.MaxMembers = *req.MaxMembers
	}
	if req.SongID != nil {
		room.SongID = *req.SongID
	}
	if req.NowPlaying != nil {
		room.NowPlaying = *req.NowPlaying
	}

	db.DB.Save(&room)
	utils.Success(c, room)
}

// KickMember 房主踢出成员
func KickMember(c *gin.Context) {
	userID := c.GetUint("user_id")
	roomIDStr := c.Param("room_id")
	roomID, err := strconv.Atoi(roomIDStr)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数格式错误")
		return
	}
	memberIDStr := c.Param("member_id")
	memberID, err := strconv.Atoi(memberIDStr)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数格式错误")
		return
	}

	var room model.TogetherRoom
	if err := db.DB.First(&room, roomID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "房间不存在")
		return
	}

	if room.CreatorID != userID {
		utils.Fail(c, http.StatusForbidden, "只有房主可以踢人")
		return
	}

	if uint(memberID) == userID {
		utils.Fail(c, http.StatusBadRequest, "不能踢出自己")
		return
	}

	// 从关联表中删除成员
	db.DB.Where("room_id = ? AND user_id = ?", room.ID, uint(memberID)).Delete(&model.RoomMember{})

	// 兼容旧逻辑：更新Members JSON字段
	var members []uint
	json.Unmarshal([]byte(room.Members), &members)
	var newMembers []uint
	for _, id := range members {
		if id != uint(memberID) {
			newMembers = append(newMembers, id)
		}
	}

	newMembersJson, _ := json.Marshal(newMembers)
	room.Members = string(newMembersJson)
	db.DB.Save(&room)

	utils.Success(c, nil)
}

// GetMyRooms 获取我的房间列表
func GetMyRooms(c *gin.Context) {
	userID := c.GetUint("user_id")

	// 从关联表查询用户所在的房间
	var roomIDs []uint
	db.DB.Model(&model.RoomMember{}).Where("user_id = ?", userID).Pluck("room_id", &roomIDs)

	var rooms []model.TogetherRoom
	if len(roomIDs) > 0 {
		db.DB.Where("id IN (?) AND status = 1", roomIDs).Order("created_at DESC").Find(&rooms)
	}

	utils.Success(c, rooms)
}

// GetPublicRooms 获取公开房间列表
func GetPublicRooms(c *gin.Context) {
	page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
	if err != nil || page < 1 {
		page = 1
	}
	pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if err != nil || pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var rooms []model.TogetherRoom
	db.DB.Where("status = 1 AND password = ''").
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).
		Find(&rooms)

	if len(rooms) == 0 {
		utils.Success(c, []interface{}{})
		return
	}

	// 收集所有创建者ID和歌曲ID
	creatorIDs := make([]uint, 0, len(rooms))
	songIDs := make([]uint, 0, len(rooms))
	for _, room := range rooms {
		creatorIDs = append(creatorIDs, room.CreatorID)
		songIDs = append(songIDs, room.SongID)
	}

	// 批量查询创建者信息
	var creators []model.User
	db.DB.Where("id IN ?", creatorIDs).Find(&creators)
	creatorMap := make(map[uint]model.User, len(creators))
	for _, creator := range creators {
		creatorMap[creator.ID] = creator
	}

	// 批量统计成员数
	type RoomMemberCount struct {
		RoomID uint
		Count  int64
	}
	var memberCounts []RoomMemberCount
	db.DB.Model(&model.RoomMember{}).
		Where("room_id IN ?", func() []uint {
			ids := make([]uint, 0, len(rooms))
			for _, room := range rooms {
				ids = append(ids, room.ID)
			}
			return ids
		}()).
		Group("room_id").
		Select("room_id, COUNT(*) as count").
		Scan(&memberCounts)
	memberCountMap := make(map[uint]int64, len(memberCounts))
	for _, mc := range memberCounts {
		memberCountMap[mc.RoomID] = mc.Count
	}

	// 批量查询歌曲信息
	var songs []model.Song
	db.DB.Where("id IN ?", songIDs).Find(&songs)
	songMap := make(map[uint]model.Song, len(songs))
	for _, song := range songs {
		songMap[song.ID] = song
	}

	// 填充创建者信息和成员数
	type RoomInfo struct {
		model.TogetherRoom
		CreatorName   string `json:"creator_name"`
		CreatorAvatar string `json:"creator_avatar"`
		MemberCount   int    `json:"member_count"`
		SongTitle     string `json:"song_title"`
		SongCover     string `json:"song_cover"`
	}

	var result []RoomInfo
	for _, room := range rooms {
		creator := creatorMap[room.CreatorID]
		song := songMap[room.SongID]
		memberCount := memberCountMap[room.ID]

		result = append(result, RoomInfo{
			TogetherRoom:  room,
			CreatorName:   creator.Nickname,
			CreatorAvatar: creator.Avatar,
			MemberCount:   int(memberCount),
			SongTitle:     song.Title,
			SongCover:     song.Cover,
		})
	}

	utils.Success(c, result)
}

// CreatorStar 创作明星响应结构
type CreatorStar struct {
	UserID      uint   `json:"user_id"`
	Nickname    string `json:"nickname"`
	Avatar      string `json:"avatar"`
	Bio         string `json:"bio"`
	WorksCount  int64  `json:"works_count"`
	TotalPlays  int64  `json:"total_plays"`
	MusicStyles []string `json:"music_styles"`
	CreatedAt   string `json:"created_at"`
}

// GetCreatorStars 获取创作明星列表
func GetCreatorStars(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}
	offset := (page - 1) * pageSize

	// 查询有作品的用户，按作品数量排序
	type UserWithStats struct {
		UserID     uint
		Nickname   string
		Avatar     string
		Bio        string
		WorksCount int64
		TotalPlays int64
		CreatedAt  string
	}

	var usersWithStats []UserWithStats

	// 原生查询：统计每个用户的作品数量和总播放量
	err := db.DB.Table("users").
		Select("users.id as user_id, users.nickname, users.avatar, users.bio, users.created_at, "+
			"COUNT(songs.id) as works_count, COALESCE(SUM(songs.play_count), 0) as total_plays").
		Joins("LEFT JOIN songs ON songs.user_id = users.id AND songs.status = 1 AND songs.is_public = 1").
		Group("users.id").
		Having("COUNT(songs.id) > 0").
		Order("works_count DESC, total_plays DESC").
		Offset(offset).Limit(pageSize).
		Scan(&usersWithStats).Error

	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	// 批量查询所有用户的音乐风格，避免N+1
	var allUserIDs []uint
	for _, u := range usersWithStats {
		allUserIDs = append(allUserIDs, u.UserID)
	}
	type UserStyle struct {
		UserID uint
		Style  string
	}
	var allStyles []UserStyle
	db.DB.Model(&model.Song{}).
		Select("DISTINCT user_id, style").
		Where("user_id IN (?) AND status = 1 AND is_public = 1 AND style != ''", allUserIDs).
		Scan(&allStyles)
	// 按user_id分组
	styleMap := make(map[uint][]string)
	for _, s := range allStyles {
		styleMap[s.UserID] = append(styleMap[s.UserID], s.Style)
	}

	// 构建响应
	var creatorStars []CreatorStar
	for _, u := range usersWithStats {
		creatorStars = append(creatorStars, CreatorStar{
			UserID:     u.UserID,
			Nickname:   u.Nickname,
			Avatar:     u.Avatar,
			Bio:        u.Bio,
			WorksCount: u.WorksCount,
			TotalPlays: u.TotalPlays,
			MusicStyles: styleMap[u.UserID],
			CreatedAt:  u.CreatedAt,
		})
	}

	utils.Success(c, creatorStars)
}

// GetCreatorDetail 获取创作明星详情
func GetCreatorDetail(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "用户ID错误")
		return
	}

	// 获取用户信息
	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 统计用户作品数量和总播放量
	var worksCount int64
	var totalPlays int64
	db.DB.Model(&model.Song{}).Where("user_id = ? AND status = 1 AND is_public = 1", userID).Count(&worksCount)
	db.DB.Model(&model.Song{}).Where("user_id = ? AND status = 1 AND is_public = 1", userID).Select("COALESCE(SUM(play_count), 0)").Scan(&totalPlays)

	// 获取用户的音乐风格
	var styles []string
	var songs []model.Song
	db.DB.Where("user_id = ? AND status = 1 AND is_public = 1", userID).Limit(5).Find(&songs)
	for _, song := range songs {
		if song.Style != "" {
			styles = append(styles, song.Style)
		}
	}

	// 获取用户的作品列表
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var userSongs []model.Song
	db.DB.Where("user_id = ? AND status = 1 AND is_public = 1", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).
		Find(&userSongs)

	utils.Success(c, gin.H{
		"user": gin.H{
			"id":         user.ID,
			"nickname":   user.Nickname,
			"avatar":     user.Avatar,
			"bio":        user.Bio,
			"works_count": worksCount,
			"total_plays": totalPlays,
			"music_styles": styles,
			"created_at": user.CreatedAt,
		},
		"songs": userSongs,
	})
}

// GetDailyRecommend 获取每日推荐歌曲
func GetDailyRecommend(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}
	offset := (page - 1) * pageSize

	var songs []model.Song
	// 每日推荐：随机选择一些公开的歌曲
	err := db.DB.Where("status = 1 AND is_public = 1").
		Order("RAND()").
		Offset(offset).Limit(pageSize).Find(&songs).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	utils.Success(c, songs)
}

// GetMusicCharts 获取音乐榜单列表
func GetMusicCharts(c *gin.Context) {
	// 返回榜单列表
	charts := []gin.H{
		{
			"id":          1,
			"name":        "飙升榜",
			"type":        "hot",
			"description": "24小时最热",
		},
		{
			"id":          2,
			"name":        "新歌榜",
			"type":        "new",
			"description": "最新首发",
		},
		{
			"id":          3,
			"name":        "原创榜",
			"type":        "original",
			"description": "独立音乐",
		},
	}

	utils.Success(c, charts)
}

// GetTogetherFeed 获取一起听社区动态（最近创建的房间活动）
func GetTogetherFeed(c *gin.Context) {
	page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
	if err != nil || page < 1 {
		page = 1
	}
	pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if err != nil || pageSize < 1 || pageSize > 50 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	// 查询最近创建的房间作为动态
	var rooms []model.TogetherRoom
	db.DB.Where("status = 1").
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).
		Find(&rooms)

	if len(rooms) == 0 {
		utils.Success(c, gin.H{
			"list":  []interface{}{},
			"total": 0,
		})
		return
	}

	// 统计总数
	var total int64
	db.DB.Model(&model.TogetherRoom{}).Where("status = 1").Count(&total)

	// 收集创建者ID
	creatorIDs := make([]uint, 0, len(rooms))
	for _, room := range rooms {
		creatorIDs = append(creatorIDs, room.CreatorID)
	}

	// 批量查询创建者信息
	var creators []model.User
	db.DB.Where("id IN ?", creatorIDs).Find(&creators)
	creatorMap := make(map[uint]model.User, len(creators))
	for _, creator := range creators {
		creatorMap[creator.ID] = creator
	}

	// 构建动态列表
	type FeedItem struct {
		Type          string `json:"type"`
		RoomID        uint   `json:"room_id"`
		RoomName      string `json:"room_name"`
		CreatorID     uint   `json:"creator_id"`
		CreatorName   string `json:"creator_name"`
		CreatorAvatar string `json:"creator_avatar"`
		CreatedAt     int64  `json:"created_at"`
	}

	feedList := make([]FeedItem, 0, len(rooms))
	for _, room := range rooms {
		creator := creatorMap[room.CreatorID]
		feedList = append(feedList, FeedItem{
			Type:          "create_room",
			RoomID:        room.ID,
			RoomName:      room.Name,
			CreatorID:     room.CreatorID,
			CreatorName:   creator.Nickname,
			CreatorAvatar: creator.Avatar,
			CreatedAt:     room.CreatedAt.Unix(),
		})
	}

	utils.Success(c, gin.H{
		"list":  feedList,
		"total": total,
	})
}
