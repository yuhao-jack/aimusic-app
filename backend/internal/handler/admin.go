package handler

import (
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AdminLogin 管理员登录
type AdminLogin struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func AdminLoginHandler(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req AdminLogin
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		var admin model.Admin
		if err := db.Where("username = ? AND status = 1", req.Username).First(&admin).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 401, "message": "用户名或密码错误"})
			return
		}

		// 使用bcrypt验证密码
		if !utils.CheckPassword(req.Password, admin.Password) {
			c.JSON(http.StatusOK, gin.H{"code": 401, "message": "用户名或密码错误"})
			return
		}

		// 记录登录日志
		db.Create(&model.AdminLoginLog{
			AdminID: admin.ID,
			IP:      c.ClientIP(),
		})

		token, err := utils.GenerateAdminToken(admin.ID, admin.Username)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "生成token失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"token":    token,
				"username": admin.Username,
				"nickname": admin.Nickname,
			},
			"message": "success",
		})
	}
}

// GetDashboardStats 获取仪表盘统计数据
func GetDashboardStats(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var totalUsers int64
		db.Model(&model.User{}).Count(&totalUsers)

		var totalSongs int64
		db.Model(&model.Song{}).Count(&totalSongs)

		var totalTasks int64
		db.Model(&model.AsyncTask{}).Count(&totalTasks)

		var totalPosts int64
		db.Model(&model.Post{}).Count(&totalPosts)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"total_users":       totalUsers,
				"total_songs":        totalSongs,
				"total_ai_creations": totalTasks,
				"total_posts":        totalPosts,
			},
			"message": "success",
		})
	}
}

// GetUserList 获取用户列表
func GetUserList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")

		offset := (page - 1) * pageSize
		var users []model.User
		var total int64

		query := db.Model(&model.User{})
		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("username LIKE ? OR nickname LIKE ? OR email LIKE ?", "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%")
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&users)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     users,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// UpdateUser 更新用户信息
func UpdateUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var user model.User
		if err := db.First(&user, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "用户不存在"})
			return
		}

		var req struct {
			Nickname string `json:"nickname"`
			Email    string `json:"email"`
			AiQuota  int    `json:"ai_quota"`
			Status   int    `json:"status"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&user).Updates(map[string]interface{}{
			"nickname": req.Nickname,
			"email":    req.Email,
			"ai_quota": req.AiQuota,
			"status":   req.Status,
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteUser 删除用户
func DeleteUser(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)
		db.Delete(&model.User{}, uint(id))
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetSongList 获取歌曲列表
func GetSongList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")

		offset := (page - 1) * pageSize
		var songs []model.Song
		var total int64

		query := db.Model(&model.Song{})
		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("title LIKE ? OR singer LIKE ?", "%"+keyword+"%", "%"+keyword+"%")
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&songs)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     songs,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// CreateSong 创建歌曲
func CreateSong(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var song model.Song
		if err := c.ShouldBindJSON(&song); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Create(&song)
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": song, "message": "success"})
	}
}

// UpdateSong 更新歌曲
func UpdateSong(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var song model.Song
		if err := db.First(&song, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "歌曲不存在"})
			return
		}

		var req struct {
			Title     string `json:"title"`
			Singer    string `json:"singer"`
			Album     string `json:"album"`
			CoverURL  string `json:"cover_url"`
			FileURL   string `json:"file_url"`
			Status    int    `json:"status"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&song).Updates(map[string]interface{}{
			"title":      req.Title,
			"singer":     req.Singer,
			"album":      req.Album,
			"cover_url":  req.CoverURL,
			"file_url":   req.FileURL,
			"status":     req.Status,
			"updated_at": time.Now().Unix(),
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteSong 删除歌曲
func DeleteSong(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		db.Delete(&model.Song{}, uint(id))
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetCommentList 获取评论列表
func GetCommentList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")

		offset := (page - 1) * pageSize
		var comments []struct {
			model.Comment
			UserNickname string `json:"user_nickname"`
			SongTitle    string `json:"song_title"`
		}
		var total int64

		query := db.Table("comments").
			Select("comments.*, users.nickname as user_nickname, songs.title as song_title").
			Joins("LEFT JOIN users ON users.id = comments.user_id").
			Joins("LEFT JOIN songs ON songs.id = comments.song_id")

		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("comments.content LIKE ?", "%"+keyword+"%")
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&comments)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     comments,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// DeleteComment 删除评论
func DeleteComment(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)
		db.Delete(&model.Comment{}, uint(id))
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetPostList 获取动态列表(admin后台)
func AdminGetPostList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")
		userID, err := strconv.Atoi(c.DefaultQuery("user_id", "0"))
		if err != nil {
			userID = 0
		}

		offset := (page - 1) * pageSize
		var posts []struct {
			model.Post
			UserNickname string `json:"user_nickname"`
		}
		var total int64

		query := db.Table("posts").
			Select("posts.*, users.nickname as user_nickname").
			Joins("LEFT JOIN users ON users.id = posts.user_id")

		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("posts.content LIKE ?", "%"+keyword+"%")
		}
		if userID > 0 {
			query = query.Where("posts.user_id = ?", userID)
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&posts)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     posts,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// DeletePost 删除动态(admin后台)
func AdminDeletePost(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)
		db.Delete(&model.Post{}, uint(id))
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetRoomList 获取一起听房间列表
func GetRoomList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		status, err := strconv.Atoi(c.DefaultQuery("status", ""))
		if err != nil {
			status = 0
		}

		offset := (page - 1) * pageSize
		var rooms []struct {
			model.TogetherRoom
			OwnerNickname string `json:"owner_nickname"`
			SongTitle     string `json:"song_title"`
			MemberCount   int    `json:"member_count"`
		}
		var total int64

		query := db.Table("together_rooms").
			Select("together_rooms.*, users.nickname as owner_nickname, songs.title as song_title, (SELECT COUNT(*) FROM room_members WHERE room_members.room_id = together_rooms.id) as member_count").
			Joins("LEFT JOIN users ON users.id = together_rooms.creator_id").
			Joins("LEFT JOIN songs ON songs.id = together_rooms.song_id")

		if status != 0 {
			query = query.Where("together_rooms.status = ?", status)
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&rooms)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     rooms,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// CloseTogetherRoom 关闭房间
func CloseTogetherRoom(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, err := strconv.ParseUint(idStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数格式错误"})
			return
		}

		db.Model(&model.TogetherRoom{}).Where("id = ?", uint(id)).Update("status", 0)
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "关闭成功"})
	}
}

// GetAiTaskList 获取AI任务列表
func GetAiTaskList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")
		taskType := c.DefaultQuery("type", "")

		offset := (page - 1) * pageSize
		var tasks []model.AsyncTask
		var total int64

		query := db.Model(&model.AsyncTask{})
		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("params LIKE ?", "%"+keyword+"%")
		}
		if taskType != "" {
			query = query.Where("type = ?", taskType)
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&tasks)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     tasks,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// GetAuditList 获取内容审核列表
func GetAuditList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		contentType := c.DefaultQuery("content_type", "")
		status, err := strconv.Atoi(c.DefaultQuery("status", "0"))
		if err != nil {
			status = 0
		}

		offset := (page - 1) * pageSize
		var audits []model.Audit
		var total int64

		query := db.Model(&model.Audit{})
		if contentType != "" {
			query = query.Where("content_type = ?", contentType)
		}
		if status > 0 {
			query = query.Where("status = ?", status)
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Find(&audits)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     audits,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// AuditPass 通过审核
func AuditPass(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		db.Model(&model.Audit{}).Where("id = ?", uint(id)).Update("status", 1)
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "操作成功"})
	}
}

// AuditReject 拒绝审核
func AuditReject(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		db.Model(&model.Audit{}).Where("id = ?", uint(id)).Update("status", 2)
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "操作成功"})
	}
}

// GetSystemConfig 获取系统配置
func GetSystemConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var configs []model.SystemConfig
		db.Find(&configs)

		result := make(map[string]string)
		for _, cfg := range configs {
			result[cfg.Key] = cfg.Value
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": result,
			"message": "success",
		})
	}
}

// SaveSystemConfig 保存系统配置
func SaveSystemConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var configMap map[string]string
		if err := c.ShouldBindJSON(&configMap); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		for key, value := range configMap {
			var cfg model.SystemConfig
			if err := db.Where("key = ?", key).First(&cfg).Error; err == nil {
				db.Model(&cfg).Update("value", value)
			} else {
				db.Create(&model.SystemConfig{Key: key, Value: value})
			}
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "保存成功"})
	}
}

// GetPublicConfig 返回公开的系统配置项（不需要鉴权）
// 只返回前端需要的公开 key，避免泄露敏感配置
func GetPublicConfig(db *gorm.DB) gin.HandlerFunc {
	// 公开配置的白名单
	publicKeys := map[string]bool{
		"music_emotions": true,
		"music_styles":   true,
	}

	return func(c *gin.Context) {
		var configs []model.SystemConfig
		db.Find(&configs)

		result := make(map[string]string)
		for _, cfg := range configs {
			if publicKeys[cfg.Key] {
				result[cfg.Key] = cfg.Value
			}
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 0,
			"data": result,
			"msg":  "success",
		})
	}
}

// GetOperationLogs 获取操作日志
func GetOperationLogs(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		offset := (page - 1) * pageSize

		var logs []model.AdminOperationLog
		var total int64

		db.Model(&model.AdminOperationLog{}).Count(&total).Offset(offset).Limit(pageSize).Find(&logs)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     logs,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// ==================== 商业化管理接口 ====================

// GetMemberList 获取会员用户列表
func GetMemberList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		keyword := c.DefaultQuery("keyword", "")
		memberLevel, err := strconv.Atoi(c.DefaultQuery("member_level", "-1"))
		if err != nil {
			memberLevel = -1
		}

		offset := (page - 1) * pageSize
		var total int64

		query := db.Model(&model.User{})
		if keyword != "" {
			// 转义 LIKE 特殊字符，防止注入
			keyword = strings.ReplaceAll(keyword, "%", "\\%")
			keyword = strings.ReplaceAll(keyword, "_", "\\_")
			query = query.Where("nickname LIKE ? OR phone LIKE ? OR email LIKE ?", "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%")
		}
		if memberLevel >= 0 {
			query = query.Where("member_level = ?", memberLevel)
		}

		// 只查询商业化相关字段
		var users []struct {
			ID             uint       `json:"id"`
			Nickname       string     `json:"nickname"`
			Phone          *string    `json:"phone"`
			Email          string     `json:"email"`
			MemberLevel    int8       `json:"member_level"`
			MemberExpireAt *time.Time `json:"member_expire_at"`
			Coins          int        `json:"coins"`
			CreatedAt      time.Time  `json:"created_at"`
		}

		query.Count(&total).
			Select("id, nickname, phone, email, member_level, member_expire_at, coins, created_at").
			Offset(offset).Limit(pageSize).
			Order("id DESC").
			Find(&users)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     users,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// UpdateMember 修改会员信息（等级、到期时间、音币）
func UpdateMember(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var user model.User
		if err := db.First(&user, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "用户不存在"})
			return
		}

		var req struct {
			MemberLevel    int    `json:"member_level"`
			MemberExpireAt string `json:"member_expire_at"` // RFC3339 或空字符串清除
			Coins          *int   `json:"coins"`            // 指针区分零值和未传
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		updates := map[string]interface{}{
			"member_level": req.MemberLevel,
		}

		// 解析会员到期时间
		if req.MemberExpireAt == "" {
			updates["member_expire_at"] = nil
		} else if t, err := time.Parse(time.RFC3339, req.MemberExpireAt); err == nil {
			updates["member_expire_at"] = &t
		}

		if req.Coins != nil {
			updates["coins"] = *req.Coins
		}

		db.Model(&user).Updates(updates)
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// GetVIPPlanList 获取VIP套餐列表
func GetVIPPlanList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var plans []model.VIPPlan
		db.Order("sort_order ASC, id ASC").Find(&plans)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": plans,
			"message": "success",
		})
	}
}

// CreateVIPPlan 创建VIP套餐
func CreateVIPPlan(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var plan model.VIPPlan
		if err := c.ShouldBindJSON(&plan); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Create(&plan)
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": plan, "message": "success"})
	}
}

// UpdateVIPPlan 修改VIP套餐
func UpdateVIPPlan(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var plan model.VIPPlan
		if err := db.First(&plan, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "套餐不存在"})
			return
		}

		var req struct {
			Name      string `json:"name"`
			Level     int    `json:"level"`
			Duration  int    `json:"duration"`
			Price     int    `json:"price"`
			Coins     int    `json:"coins"`
			IsPopular bool   `json:"is_popular"`
			SortOrder int    `json:"sort_order"`
			IsActive  bool   `json:"is_active"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&plan).Updates(map[string]interface{}{
			"name":       req.Name,
			"level":      req.Level,
			"duration":   req.Duration,
			"price":      req.Price,
			"coins":      req.Coins,
			"is_popular": req.IsPopular,
			"sort_order": req.SortOrder,
			"is_active":  req.IsActive,
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteVIPPlan 删除VIP套餐（软删除）
func DeleteVIPPlan(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		if err := db.Delete(&model.VIPPlan{}, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "删除失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetCoinPackageList 获取音币充值包列表
func GetCoinPackageList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var packages []model.CoinPackage
		db.Order("sort_order ASC, id ASC").Find(&packages)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": packages,
			"message": "success",
		})
	}
}

// CreateCoinPackage 创建音币充值包
func CreateCoinPackage(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var pkg model.CoinPackage
		if err := c.ShouldBindJSON(&pkg); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Create(&pkg)
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": pkg, "message": "success"})
	}
}

// UpdateCoinPackage 修改音币充值包
func UpdateCoinPackage(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var pkg model.CoinPackage
		if err := db.First(&pkg, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "充值包不存在"})
			return
		}

		var req struct {
			Name      string `json:"name"`
			Coins     int    `json:"coins"`
			Price     int    `json:"price"`
			Bonus     int    `json:"bonus"`
			SortOrder int    `json:"sort_order"`
			IsActive  bool   `json:"is_active"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&pkg).Updates(map[string]interface{}{
			"name":       req.Name,
			"coins":      req.Coins,
			"price":      req.Price,
			"bonus":      req.Bonus,
			"sort_order": req.SortOrder,
			"is_active":  req.IsActive,
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteCoinPackage 删除音币充值包（软删除）
func DeleteCoinPackage(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, err := strconv.ParseUint(idStr, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数格式错误"})
			return
		}

		if err := db.Delete(&model.CoinPackage{}, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "删除失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// GetCoinRecordList 获取音币交易记录列表
func GetCoinRecordList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		userID, err := strconv.Atoi(c.DefaultQuery("user_id", "0"))
		if err != nil {
			userID = 0
		}
		coinType, err := strconv.Atoi(c.DefaultQuery("type", "0"))
		if err != nil {
			coinType = 0
		}

		offset := (page - 1) * pageSize
		var records []struct {
			model.CoinTransaction
			UserNickname string `json:"user_nickname"`
		}
		var total int64

		query := db.Table("coin_transactions").
			Select("coin_transactions.*, users.nickname as user_nickname").
			Joins("LEFT JOIN users ON users.id = coin_transactions.user_id")

		if userID > 0 {
			query = query.Where("coin_transactions.user_id = ?", userID)
		}
		if coinType > 0 {
			query = query.Where("coin_transactions.type = ?", coinType)
		}

		query.Count(&total).
			Offset(offset).Limit(pageSize).
			Order("coin_transactions.id DESC").
			Find(&records)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     records,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// GetOrderList 获取会员订单列表
func GetOrderList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		status, err := strconv.Atoi(c.DefaultQuery("status", "-1"))
		if err != nil {
			status = -1
		}

		offset := (page - 1) * pageSize
		var orders []struct {
			model.MembershipOrder
			UserNickname string `json:"user_nickname"`
		}
		var total int64

		query := db.Table("membership_orders").
			Select("membership_orders.*, users.nickname as user_nickname").
			Joins("LEFT JOIN users ON users.id = membership_orders.user_id")

		if status >= 0 {
			query = query.Where("membership_orders.status = ?", status)
		}

		query.Count(&total).
			Offset(offset).Limit(pageSize).
			Order("membership_orders.id DESC").
			Find(&orders)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     orders,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}
