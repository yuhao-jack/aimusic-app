package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
)

// CreatePost 创建动态发帖
func CreatePost(c *gin.Context) {
	userID := c.GetUint("user_id")

	var req struct {
		Content string   `json:"content" binding:"required"`
		Images  []string `json:"images"` // 图片URL数组
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}
	// 内容长度限制
	if len([]rune(req.Content)) > 5000 {
		utils.Fail(c, http.StatusBadRequest, "动态内容不能超过5000字")
		return
	}

	// 将图片数组转为JSON字符串存储
	imagesJSON, _ := json.Marshal(req.Images)

	post := model.Post{
		UserID:    userID,
		Content:   req.Content,
		Images:    string(imagesJSON),
		LikeCount: 0,
	}

	if err := db.DB.Create(&post).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "发布失败，请重试")
		return
	}

	utils.Success(c, post)
}

// GetPostList 获取动态列表（分页）
func GetPostList(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	listType := c.DefaultQuery("type", "all") // all=全部, following=仅关注
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}
	offset := (page - 1) * pageSize

	var posts []model.Post
	var total int64
	query := db.DB.Model(&model.Post{}).Where("deleted_at IS NULL")

	// 如果是关注动态，只查询关注用户的帖子
	if listType == "following" {
		// 从context获取用户ID（需要JWT中间件设置）
		userIDVal, exists := c.Get("user_id")
		if !exists {
			// 未登录返回空
			utils.Success(c, gin.H{"list": []model.Post{}, "total": 0, "page": page, "page_size": pageSize})
			return
		}
		userID := userIDVal.(uint)
		// 获取关注列表
		var followingIDs []uint
		db.DB.Model(&model.Follow{}).Where("follower_id = ?", userID).Pluck("following_id", &followingIDs)
		if len(followingIDs) == 0 {
			utils.Success(c, gin.H{"list": []model.Post{}, "total": 0, "page": page, "page_size": pageSize})
			return
		}
		query = query.Where("user_id IN (?)", followingIDs)
	}

	query.Count(&total)

	err := query.Order("created_at DESC").
		Offset(offset).Limit(pageSize).Find(&posts).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取动态列表失败")
		return
	}

	// 获取当前用户ID（可能为空，公开接口）
	var currentUserID uint
	if uid, exists := c.Get("user_id"); exists {
		currentUserID = uid.(uint)
	}

	// 解析图片URL数组 + 检查是否已点赞
	type PostWithInfo struct {
		model.Post
		IsLiked bool `json:"is_liked"`
	}
	var postsWithInfo []PostWithInfo
	for _, post := range posts {
		var images []string
		if post.Images != "" {
			json.Unmarshal([]byte(post.Images), &images)
		}
		
		isLiked := false
		if currentUserID > 0 {
			var like model.PostLike
			if err := db.DB.Where("post_id = ? AND user_id = ?", post.ID, currentUserID).First(&like).Error; err == nil {
				isLiked = true
			}
		}
		
		postsWithInfo = append(postsWithInfo, PostWithInfo{
			Post:    post,
			IsLiked: isLiked,
		})
	}

	utils.Success(c, gin.H{
		"list":      postsWithInfo,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// GetUserPostList 获取指定用户的动态列表
func GetUserPostList(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "用户ID错误")
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 10
	}
	offset := (page - 1) * pageSize

	var posts []model.Post
	var total int64

	db.DB.Model(&model.Post{}).Where("user_id = ? AND deleted_at IS NULL", userID).Count(&total)
	err = db.DB.Where("user_id = ? AND deleted_at IS NULL", userID).
		Order("created_at DESC").
		Offset(offset).Limit(pageSize).Find(&posts).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取动态列表失败")
		return
	}

	utils.Success(c, gin.H{
		"list":      posts,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// GetPostDetail 获取动态详情
func GetPostDetail(c *gin.Context) {
	postIDStr := c.Param("post_id")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "动态ID错误")
		return
	}

	var post model.Post
	if err := db.DB.Where("id = ? AND deleted_at IS NULL", postID).First(&post).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "动态不存在")
		return
	}

	// 检查当前用户是否已点赞
	isLiked := false
	if uid, exists := c.Get("user_id"); exists {
		var like model.PostLike
		if err := db.DB.Where("post_id = ? AND user_id = ?", post.ID, uid).First(&like).Error; err == nil {
			isLiked = true
		}
	}

	utils.Success(c, gin.H{
		"id":          post.ID,
		"user_id":     post.UserID,
		"content":     post.Content,
		"images":      post.Images,
		"like_count":  post.LikeCount,
		"comment_count": post.CommentCount,
		"created_at":  post.CreatedAt,
		"is_liked":    isLiked,
	})
}

// DeletePost 删除动态
func DeletePost(c *gin.Context) {
	userID := c.GetUint("user_id")
	postIDStr := c.Param("post_id")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "动态ID错误")
		return
	}

	var post model.Post
	if err := db.DB.Where("id = ?", postID).First(&post).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "动态不存在")
		return
	}

	if post.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "只能删除自己发布的动态")
		return
	}

	// 软删除
	if err := db.DB.Delete(&post).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "删除失败")
		return
	}

	utils.Success(c, nil)
}

// LikePost 点赞/取消点赞动态
func LikePost(c *gin.Context) {
	userID := c.GetUint("user_id")
	postIDStr := c.Param("post_id")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "动态ID错误")
		return
	}

	// 查询是否已经点赞
	var like model.PostLike
	hasLike := db.DB.Where("post_id = ? AND user_id = ?", postID, userID).First(&like).Error == nil

	var post model.Post
	db.DB.First(&post, postID)

	if hasLike {
		// 取消点赞（使用事务保证原子性）
		tx := db.DB.Begin()
		if err := tx.Delete(&like).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "取消点赞失败")
			return
		}
		if err := tx.Model(&post).UpdateColumn("like_count", gorm.Expr("CASE WHEN like_count > 0 THEN like_count - 1 ELSE 0 END")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "取消点赞失败")
			return
		}
		tx.Commit()
		utils.SuccessWithMsg(c, "取消点赞成功", gin.H{"liked": false})
	} else {
		// 添加点赞（使用事务保证原子性）
		tx := db.DB.Begin()
		newLike := model.PostLike{
			PostID: uint(postID),
			UserID: userID,
		}
		if err := tx.Create(&newLike).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "点赞失败")
			return
		}
		if err := tx.Model(&post).UpdateColumn("like_count", gorm.Expr("like_count + 1")).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "点赞失败")
			return
		}
		tx.Commit()

		// 创建通知（点赞了你的动态）
		if post.UserID != userID {
			content := "赞了你的动态"
			CreateNotification(post.UserID, userID, "like", "post", uint(postID), content)
		}

		utils.SuccessWithMsg(c, "点赞成功", gin.H{"liked": true})
	}
}

// AddPostComment 添加动态评论
func AddPostComment(c *gin.Context) {
	userID := c.GetUint("user_id")
	postIDStr := c.Param("post_id")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "动态ID错误")
		return
	}

	var req struct {
		Content string `json:"content" binding:"required"`
		ParentID uint   `json:"parent_id"`
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

	comment := model.PostComment{
		PostID:   uint(postID),
		UserID:   userID,
		Content:  req.Content,
		ParentID: req.ParentID,
	}

	// 使用事务保证创建评论和更新计数的原子性
	tx := db.DB.Begin()

	if err := tx.Create(&comment).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "评论失败")
		return
	}

	// 增加评论计数
	if err := tx.Model(&model.Post{}).Where("id = ?", postID).UpdateColumn("comment_count", gorm.Expr("comment_count + 1")).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "评论失败")
		return
	}

	tx.Commit()

	// 创建通知
	var postModel model.Post
	if db.DB.First(&postModel, postID).Error == nil && postModel.UserID != userID {
		if req.ParentID > 0 {
			// 查询被回复的原始评论
			var parentComment model.PostComment
			if db.DB.First(&parentComment, req.ParentID).Error == nil && parentComment.UserID != userID {
				content := "回复了你的评论"
				CreateNotification(parentComment.UserID, userID, "reply", "post", uint(postID), content)
			}
		} else {
			content := "评论了你的动态"
			CreateNotification(postModel.UserID, userID, "comment", "post", uint(postID), content)
		}
	}

	utils.Success(c, comment)
}

// GetPostComments 获取动态评论列表
func GetPostComments(c *gin.Context) {
	postIDStr := c.Param("post_id")
	postID, err := strconv.ParseUint(postIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "动态ID错误")
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

	var comments []model.PostComment
	err = db.DB.Where("post_id = ? AND parent_id = 0 AND deleted_at IS NULL", postID).
		Offset(offset).Limit(pageSize).Order("created_at desc").Find(&comments).Error
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取评论失败")
		return
	}

	var total int64
	db.DB.Model(&model.PostComment{}).Where("post_id = ? AND parent_id = 0 AND deleted_at IS NULL", postID).Count(&total)

	utils.Success(c, gin.H{
		"list":      comments,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// DeletePostComment 删除动态评论
func DeletePostComment(c *gin.Context) {
	userID := c.GetUint("user_id")
	commentIDStr := c.Param("comment_id")
	commentID, err := strconv.ParseUint(commentIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "评论ID错误")
		return
	}

	var comment model.PostComment
	if err := db.DB.Where("id = ?", commentID).First(&comment).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "评论不存在")
		return
	}

	if comment.UserID != userID {
		utils.Fail(c, http.StatusForbidden, "只能删除自己的评论")
		return
	}

	// 使用事务保证删除评论和更新计数的原子性
	tx := db.DB.Begin()

	// 删除评论
	if err := tx.Delete(&comment).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "删除失败")
		return
	}

	// 减少评论计数
	if err := tx.Model(&model.Post{}).Where("id = ?", comment.PostID).UpdateColumn("comment_count", gorm.Expr("CASE WHEN comment_count > 0 THEN comment_count - 1 ELSE 0 END")).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "删除失败")
		return
	}

	tx.Commit()

	utils.Success(c, nil)
}
