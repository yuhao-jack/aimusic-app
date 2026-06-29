package handler

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// FollowUser 关注用户
// POST /api/v1/user/follow/:target_id (需要鉴权)
func FollowUser(c *gin.Context) {
	userID := c.GetUint("user_id")
	targetIDStr := c.Param("target_id")
	targetID, err := strconv.ParseUint(targetIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "用户ID错误")
		return
	}

	// 不能关注自己
	if userID == uint(targetID) {
		utils.Fail(c, http.StatusBadRequest, "不能关注自己")
		return
	}

	// 检查目标用户是否存在
	var targetUser model.User
	if err := db.DB.First(&targetUser, targetID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "目标用户不存在")
		return
	}

	// 检查是否已经关注（兼容软删除，使用 DeletedAt IS NULL）
	var existing model.Follow
	result := db.DB.Where("follower_id = ? AND following_id = ? AND deleted_at IS NULL", userID, targetID).First(&existing)
	if result.Error == nil {
		utils.Fail(c, http.StatusBadRequest, "已经关注该用户")
		return
	}

	// 创建关注关系
	follow := model.Follow{
		FollowerID:  userID,
		FollowingID: uint(targetID),
	}
	if err := db.DB.Create(&follow).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "关注失败")
		return
	}

	// 创建通知
	content := "关注了你"
	CreateNotification(uint(targetID), userID, "follow", "user", 0, content)

	utils.SuccessWithMsg(c, "关注成功", gin.H{"following": true})
}

// UnfollowUser 取消关注用户
// POST /api/v1/user/unfollow/:target_id (需要鉴权)
func UnfollowUser(c *gin.Context) {
	userID := c.GetUint("user_id")
	targetIDStr := c.Param("target_id")
	targetID, err := strconv.ParseUint(targetIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "用户ID错误")
		return
	}

	// 查找并硬删除关注记录
	var follow model.Follow
	result := db.DB.Unscoped().Where("follower_id = ? AND following_id = ?", userID, targetID).First(&follow)
	if result.Error != nil {
		utils.Fail(c, http.StatusNotFound, "未关注该用户")
		return
	}

	// 硬删除（完全删除记录）
	if err := db.DB.Unscoped().Delete(&follow).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "取消失败")
		return
	}

	utils.SuccessWithMsg(c, "取消关注成功", gin.H{"following": false})
}

// GetFollowers 获取用户的粉丝列表（公开）
// GET /api/v1/user/followers/:user_id
func GetFollowers(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "用户ID错误")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	offset := (page - 1) * pageSize

	// 查询粉丝列表（附带用户基本信息）
	type FollowerInfo struct {
		model.Follow
		FollowerUser model.User `gorm:"foreignKey:FollowerID"`
	}

	var follows []model.Follow
	var total int64

	// 获取总数
	db.DB.Model(&model.Follow{}).Where("following_id = ? AND deleted_at IS NULL", userID).Count(&total)

	// 分页查询
	err = db.DB.Where("following_id = ? AND deleted_at IS NULL", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).Find(&follows).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	// 获取粉丝的用户信息
	var userIDs []uint
	for _, f := range follows {
		userIDs = append(userIDs, f.FollowerID)
	}

	var users []model.User
	if len(userIDs) > 0 {
		db.DB.Select("id, nickname, avatar, bio").Where("id IN ?", userIDs).Find(&users)
	}

	// 构建 user map
	userMap := make(map[uint]model.User)
	for _, u := range users {
		userMap[u.ID] = u
	}

	// 组合结果
	type FollowerResult struct {
		FollowID uint   `json:"follow_id"`
		UserID   uint   `json:"user_id"`
		Nickname string `json:"nickname"`
		Avatar   string `json:"avatar"`
		Bio      string `json:"bio"`
		FollowedAt string `json:"followed_at"`
	}

	var result []FollowerResult
	for _, f := range follows {
		u := userMap[f.FollowerID]
		result = append(result, FollowerResult{
			FollowID:   f.ID,
			UserID:     f.FollowerID,
			Nickname:   u.Nickname,
			Avatar:     u.Avatar,
			Bio:        u.Bio,
			FollowedAt: f.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	utils.Success(c, gin.H{
		"list":      result,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// GetFollowing 获取用户的关注列表（公开）
// GET /api/v1/user/following/:user_id
func GetFollowing(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "用户ID错误")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	offset := (page - 1) * pageSize

	var follows []model.Follow
	var total int64

	// 获取总数
	db.DB.Model(&model.Follow{}).Where("follower_id = ? AND deleted_at IS NULL", userID).Count(&total)

	// 分页查询
	err = db.DB.Where("follower_id = ? AND deleted_at IS NULL", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).Find(&follows).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "查询失败")
		return
	}

	// 获取被关注者的用户信息
	var followingIDs []uint
	for _, f := range follows {
		followingIDs = append(followingIDs, f.FollowingID)
	}

	var users []model.User
	if len(followingIDs) > 0 {
		db.DB.Select("id, nickname, avatar, bio").Where("id IN ?", followingIDs).Find(&users)
	}

	userMap := make(map[uint]model.User)
	for _, u := range users {
		userMap[u.ID] = u
	}

	type FollowingResult struct {
		FollowID   uint   `json:"follow_id"`
		UserID     uint   `json:"user_id"`
		Nickname   string `json:"nickname"`
		Avatar     string `json:"avatar"`
		Bio        string `json:"bio"`
		FollowedAt string `json:"followed_at"`
	}

	var result []FollowingResult
	for _, f := range follows {
		u := userMap[f.FollowingID]
		result = append(result, FollowingResult{
			FollowID:   f.ID,
			UserID:     f.FollowingID,
			Nickname:   u.Nickname,
			Avatar:     u.Avatar,
			Bio:        u.Bio,
			FollowedAt: f.CreatedAt.Format("2006-01-02 15:04:05"),
		})
	}

	utils.Success(c, gin.H{
		"list":      result,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// GetFollowStatus 批量查询当前用户是否关注了指定用户列表
// GET /api/v1/user/follow/:target_id/status?target_ids=1,2,3 (需要鉴权)
func GetFollowStatus(c *gin.Context) {
	userID := c.GetUint("user_id")
	targetIDStr := c.Query("target_ids")
	if targetIDStr == "" {
		utils.Fail(c, http.StatusBadRequest, "target_ids 不能为空")
		return
	}

	// 解析逗号分隔的ID列表
	idStrs := strings.Split(targetIDStr, ",")
	var targetIDs []uint
	for _, idStr := range idStrs {
		idStr = strings.TrimSpace(idStr)
		id, err := strconv.ParseUint(idStr, 10, 64)
		if err != nil {
			continue
		}
		targetIDs = append(targetIDs, uint(id))
	}

	if len(targetIDs) == 0 {
		utils.Fail(c, http.StatusBadRequest, "目标用户ID参数错误")
		return
	}

	// 查询当前用户已关注的用户
	var follows []model.Follow
	db.DB.Where("follower_id = ? AND following_id IN ? AND deleted_at IS NULL", userID, targetIDs).Find(&follows)

	// 构建结果 map
	statusMap := make(map[string]bool)
	for _, id := range targetIDs {
		statusMap[strconv.FormatUint(uint64(id), 10)] = false
	}
	for _, f := range follows {
		statusMap[strconv.FormatUint(uint64(f.FollowingID), 10)] = true
	}

	utils.Success(c, gin.H{
		"status": statusMap,
	})
}
