package handler

import (
	"fmt"
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
		now := time.Now()
		todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		weekStart := todayStart.AddDate(0, 0, -int(now.Weekday())+1) // 周一
		monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())

		// 总数统计
		var totalUsers, totalSongs, totalTasks, totalPosts, totalComments, totalLikes int64
		db.Model(&model.User{}).Count(&totalUsers)
		db.Model(&model.Song{}).Count(&totalSongs)
		db.Model(&model.AsyncTask{}).Count(&totalTasks)
		db.Model(&model.Post{}).Count(&totalPosts)
		db.Model(&model.Comment{}).Count(&totalComments)
		db.Model(&model.Like{}).Count(&totalLikes)

		// 今日新增
		var todayUsers, todaySongs, todayTasks, todayPosts, todayComments, todayLikes int64
		db.Model(&model.User{}).Where("created_at >= ?", todayStart).Count(&todayUsers)
		db.Model(&model.Song{}).Where("created_at >= ?", todayStart).Count(&todaySongs)
		db.Model(&model.AsyncTask{}).Where("created_at >= ?", todayStart).Count(&todayTasks)
		db.Model(&model.Post{}).Where("created_at >= ?", todayStart).Count(&todayPosts)
		db.Model(&model.Comment{}).Where("created_at >= ?", todayStart).Count(&todayComments)
		db.Model(&model.Like{}).Where("created_at >= ?", todayStart).Count(&todayLikes)

		// 本周新增
		var weekUsers, weekSongs, weekTasks, weekPosts int64
		db.Model(&model.User{}).Where("created_at >= ?", weekStart).Count(&weekUsers)
		db.Model(&model.Song{}).Where("created_at >= ?", weekStart).Count(&weekSongs)
		db.Model(&model.AsyncTask{}).Where("created_at >= ?", weekStart).Count(&weekTasks)
		db.Model(&model.Post{}).Where("created_at >= ?", weekStart).Count(&weekPosts)

		// 本月新增
		var monthUsers, monthSongs, monthTasks, monthPosts int64
		db.Model(&model.User{}).Where("created_at >= ?", monthStart).Count(&monthUsers)
		db.Model(&model.Song{}).Where("created_at >= ?", monthStart).Count(&monthSongs)
		db.Model(&model.AsyncTask{}).Where("created_at >= ?", monthStart).Count(&monthTasks)
		db.Model(&model.Post{}).Where("created_at >= ?", monthStart).Count(&monthPosts)

		// 商业化指标
		var vipCount, svipCount int64
		db.Model(&model.User{}).Where("member_level = 1").Count(&vipCount)
		db.Model(&model.User{}).Where("member_level = 2").Count(&svipCount)

		var todayRevenue, monthRevenue int64
		db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ?", todayStart.Unix()).Select("COALESCE(SUM(amount),0)").Scan(&todayRevenue)
		db.Model(&model.MembershipOrder{}).Where("status = 1 AND pay_time >= ?", monthStart.Unix()).Select("COALESCE(SUM(amount),0)").Scan(&monthRevenue)

		// AI指标
		var aiSuccessCount, aiTotalCount, aiPendingCount int64
		db.Model(&model.AsyncTask{}).Where("status = 2").Count(&aiSuccessCount)
		db.Model(&model.AsyncTask{}).Where("status IN (0,1)").Count(&aiPendingCount)
		aiTotalCount = totalTasks
		aiSuccessRate := 0.0
		if aiTotalCount > 0 {
			aiSuccessRate = float64(aiSuccessCount) / float64(aiTotalCount) * 100
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"totals": gin.H{
					"users":    totalUsers,
					"songs":    totalSongs,
					"ai_tasks": totalTasks,
					"posts":    totalPosts,
					"comments": totalComments,
					"likes":    totalLikes,
				},
				"today": gin.H{
					"new_users":    todayUsers,
					"new_songs":    todaySongs,
					"new_ai_tasks": todayTasks,
					"new_posts":    todayPosts,
					"new_comments": todayComments,
					"new_likes":    todayLikes,
				},
				"this_week": gin.H{
					"new_users":    weekUsers,
					"new_songs":    weekSongs,
					"new_ai_tasks": weekTasks,
					"new_posts":    weekPosts,
				},
				"this_month": gin.H{
					"new_users":    monthUsers,
					"new_songs":    monthSongs,
					"new_ai_tasks": monthTasks,
					"new_posts":    monthPosts,
				},
				"commercial": gin.H{
					"today_revenue": todayRevenue,
					"month_revenue": monthRevenue,
					"vip_count":     vipCount,
					"svip_count":    svipCount,
				},
				"ai": gin.H{
					"success_rate":  fmt.Sprintf("%.1f", aiSuccessRate),
					"pending_tasks": aiPendingCount,
				},
			},
			"message": "success",
		})
	}
}

// GetDashboardTrend 获取仪表盘趋势数据
func GetDashboardTrend(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		daysStr := c.DefaultQuery("days", "7")
		days, _ := strconv.Atoi(daysStr)
		if days <= 0 || days > 90 {
			days = 7
		}

		now := time.Now()
		dates := make([]string, days)
		users := make([]int64, days)
		songs := make([]int64, days)
		aiTasks := make([]int64, days)
		posts := make([]int64, days)
		comments := make([]int64, days)

		for i := days - 1; i >= 0; i-- {
			dayStart := time.Date(now.Year(), now.Month(), now.Day()-i, 0, 0, 0, 0, now.Location())
			dayEnd := dayStart.AddDate(0, 0, 1)
			dates[days-1-i] = dayStart.Format("01-02")

			db.Model(&model.User{}).Where("created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&users[days-1-i])
			db.Model(&model.Song{}).Where("created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&songs[days-1-i])
			db.Model(&model.AsyncTask{}).Where("created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&aiTasks[days-1-i])
			db.Model(&model.Post{}).Where("created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&posts[days-1-i])
			db.Model(&model.Comment{}).Where("created_at >= ? AND created_at < ?", dayStart, dayEnd).Count(&comments[days-1-i])
		}

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"dates":    dates,
				"users":    users,
				"songs":    songs,
				"ai_tasks": aiTasks,
				"posts":    posts,
				"comments": comments,
			},
			"message": "success",
		})
	}
}

// GetDashboardDistribution 获取仪表盘分布数据
func GetDashboardDistribution(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 歌曲风格分布
		type NameCount struct {
			Name  string `json:"name"`
			Count int64  `json:"value"`
		}
		var songStyles []NameCount
		db.Model(&model.Song{}).Select("style as name, COUNT(*) as value").Where("style != ''").Group("style").Order("value DESC").Limit(10).Scan(&songStyles)

		// 歌曲情绪分布
		var songEmotions []NameCount
		db.Model(&model.Song{}).Select("emotion as name, COUNT(*) as value").Where("emotion != ''").Group("emotion").Order("value DESC").Limit(10).Scan(&songEmotions)

		// 会员等级分布
		var memberLevels []NameCount
		db.Raw(`SELECT 
			CASE member_level 
				WHEN 0 THEN '普通用户' 
				WHEN 1 THEN 'VIP会员' 
				WHEN 2 THEN 'SVIP会员' 
			END as name, 
			COUNT(*) as value 
		FROM users GROUP BY member_level`).Scan(&memberLevels)

		// AI任务类型分布
		var aiTaskTypes []NameCount
		db.Raw(`SELECT 
			CASE task_type 
				WHEN 1 THEN '音乐生成' 
				WHEN 2 THEN '音色训练' 
				WHEN 3 THEN 'MV渲染' 
			END as name, 
			COUNT(*) as value 
		FROM async_tasks GROUP BY task_type`).Scan(&aiTaskTypes)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"song_styles":   songStyles,
				"song_emotions": songEmotions,
				"member_levels": memberLevels,
				"ai_task_types": aiTaskTypes,
			},
			"message": "success",
		})
	}
}

// GetDashboardRanking 获取仪表盘排行榜
func GetDashboardRanking(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 热门歌曲 Top10
		type SongRank struct {
			ID        uint   `json:"id"`
			Title     string `json:"title"`
			PlayCount int    `json:"play_count"`
			LikeCount int    `json:"like_count"`
		}
		var hotSongs []SongRank
		db.Model(&model.Song{}).Select("id, title, play_count, like_count").Order("play_count DESC").Limit(10).Scan(&hotSongs)

		// 活跃用户 Top10
		type UserRank struct {
			ID        uint   `json:"id"`
			Nickname  string `json:"nickname"`
			SongCount int64  `json:"song_count"`
			PostCount int64  `json:"post_count"`
		}
		var activeUsers []UserRank
		db.Raw(`SELECT u.id, u.nickname, 
			(SELECT COUNT(*) FROM songs WHERE user_id = u.id) as song_count,
			(SELECT COUNT(*) FROM posts WHERE user_id = u.id) as post_count
			FROM users u 
			ORDER BY song_count + post_count DESC 
			LIMIT 10`).Scan(&activeUsers)

		// 创作达人 Top10 (AI使用最多)
		type CreatorRank struct {
			ID       uint   `json:"id"`
			Nickname string `json:"nickname"`
			AICount  int64  `json:"ai_count"`
		}
		var topCreators []CreatorRank
		db.Raw(`SELECT u.id, u.nickname, COUNT(t.id) as ai_count
			FROM users u 
			JOIN async_tasks t ON t.user_id = u.id
			GROUP BY u.id, u.nickname
			ORDER BY ai_count DESC 
			LIMIT 10`).Scan(&topCreators)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"hot_songs":    hotSongs,
				"active_users": activeUsers,
				"top_creators": topCreators,
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
			Nickname  string `json:"nickname"`
			Email     string `json:"email"`
			MaxDailyAI int   `json:"max_daily_ai"`
			Status    int    `json:"status"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&user).Updates(map[string]interface{}{
			"nickname":     req.Nickname,
			"email":        req.Email,
			"max_daily_ai": req.MaxDailyAI,
			"status":       req.Status,
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

		var audit model.Audit
		if err := db.First(&audit, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "审核记录不存在"})
			return
		}

		// 更新审核状态
		db.Model(&audit).Update("status", 1)

		// 联动更新原内容状态
		switch audit.ContentType {
		case "post":
			db.Model(&model.Post{}).Where("id = ?", audit.ContentID).Update("status", 1)
		case "comment":
			db.Model(&model.Comment{}).Where("id = ?", audit.ContentID).Update("status", 1)
		case "song":
			db.Model(&model.Song{}).Where("id = ?", audit.ContentID).Update("status", 1)
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "审核通过"})
	}
}

// AuditReject 拒绝审核
func AuditReject(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var audit model.Audit
		if err := db.First(&audit, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "审核记录不存在"})
			return
		}

		// 更新审核状态
		db.Model(&audit).Update("status", 2)

		// 联动更新原内容状态（下架/隐藏）
		switch audit.ContentType {
		case "post":
			db.Model(&model.Post{}).Where("id = ?", audit.ContentID).Update("status", 2)
		case "comment":
			db.Model(&model.Comment{}).Where("id = ?", audit.ContentID).Update("status", 2)
		case "song":
			db.Model(&model.Song{}).Where("id = ?", audit.ContentID).Update("status", 2)
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "审核拒绝，内容已下架"})
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

		// 使用事务确保批量保存原子性
		err := db.Transaction(func(tx *gorm.DB) error {
			for key, value := range configMap {
				var cfg model.SystemConfig
				if err := tx.Where("key = ?", key).First(&cfg).Error; err == nil {
					tx.Model(&cfg).Update("value", value)
				} else {
					tx.Create(&model.SystemConfig{Key: key, Value: value})
				}
			}
			return nil
		})

		if err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "保存失败"})
			return
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
		adminName := c.DefaultQuery("admin_name", "")
		action := c.DefaultQuery("action", "")
		offset := (page - 1) * pageSize

		var logs []model.AdminOperationLog
		var total int64

		query := db.Model(&model.AdminOperationLog{})
		if adminName != "" {
			// 转义 LIKE 特殊字符，防止注入
			adminName = strings.ReplaceAll(adminName, "%", "\\%")
			adminName = strings.ReplaceAll(adminName, "_", "\\_")
			query = query.Where("admin_name LIKE ?", "%"+adminName+"%")
		}
		if action != "" {
			query = query.Where("action = ?", action)
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Order("id DESC").Find(&logs)

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

// ==================== 活动/公告管理接口 ====================

// GetActivityList 获取活动/公告列表
func GetActivityList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		activityType, err := strconv.Atoi(c.DefaultQuery("type", "0"))
		if err != nil {
			activityType = 0
		}

		offset := (page - 1) * pageSize
		var activities []model.Activity
		var total int64

		query := db.Model(&model.Activity{})
		if activityType > 0 {
			query = query.Where("type = ?", activityType)
		}

		query.Count(&total).Offset(offset).Limit(pageSize).Order("sort_order ASC, id DESC").Find(&activities)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     activities,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// CreateActivity 创建活动/公告
func CreateActivity(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var activity model.Activity
		if err := c.ShouldBindJSON(&activity); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Create(&activity)
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": activity, "message": "success"})
	}
}

// UpdateActivity 更新活动/公告
func UpdateActivity(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		var activity model.Activity
		if err := db.First(&activity, uint(id)).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 404, "message": "活动不存在"})
			return
		}

		var req struct {
			Title     string `json:"title"`
			Content   string `json:"content"`
			Cover     string `json:"cover"`
			Type      int8   `json:"type"`
			StartAt   int64  `json:"start_at"`
			EndAt     int64  `json:"end_at"`
			IsActive  bool   `json:"is_active"`
			SortOrder int    `json:"sort_order"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		db.Model(&activity).Updates(map[string]interface{}{
			"title":      req.Title,
			"content":    req.Content,
			"cover":      req.Cover,
			"type":       req.Type,
			"start_at":   req.StartAt,
			"end_at":     req.EndAt,
			"is_active":  req.IsActive,
			"sort_order": req.SortOrder,
		})

		c.JSON(http.StatusOK, gin.H{"code": 200, "data": nil, "message": "success"})
	}
}

// DeleteActivity 删除活动/公告
func DeleteActivity(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)

		db.Delete(&model.Activity{}, uint(id))
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// ==================== 数据导出接口 ====================

// ExportUsers 导出用户列表为CSV
func ExportUsers(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var users []model.User
		db.Find(&users)

		// 设置CSV响应头
		c.Header("Content-Type", "text/csv; charset=utf-8")
		c.Header("Content-Disposition", "attachment; filename=users.csv")

		// 写入BOM（解决Excel中文乱码）
		c.Writer.Write([]byte{0xEF, 0xBB, 0xBF})

		// 写入CSV表头
		c.Writer.WriteString("ID,用户名,昵称,手机号,邮箱,会员等级,音币余额,注册时间\n")

		// 写入数据行
		for _, user := range users {
			phone := ""
			if user.Phone != nil {
				phone = *user.Phone
			}
			memberLevel := "普通用户"
			if user.MemberLevel == 1 {
				memberLevel = "VIP会员"
			} else if user.MemberLevel == 2 {
				memberLevel = "SVIP会员"
			}
			c.Writer.WriteString(fmt.Sprintf("%d,%s,%s,%s,%s,%s,%d,%s\n",
				user.ID, user.Username, user.Nickname, phone, user.Email,
				memberLevel, user.Coins, user.CreatedAt.Format("2006-01-02 15:04:05")))
		}
	}
}

// ExportOrders 导出订单列表为CSV
func ExportOrders(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var orders []struct {
			model.MembershipOrder
			UserNickname string `json:"user_nickname"`
		}

		db.Table("membership_orders").
			Select("membership_orders.*, users.nickname as user_nickname").
			Joins("LEFT JOIN users ON users.id = membership_orders.user_id").
			Find(&orders)

		// 设置CSV响应头
		c.Header("Content-Type", "text/csv; charset=utf-8")
		c.Header("Content-Disposition", "attachment; filename=orders.csv")

		// 写入BOM（解决Excel中文乱码）
		c.Writer.Write([]byte{0xEF, 0xBB, 0xBF})

		// 写入CSV表头
		c.Writer.WriteString("订单号,用户昵称,会员等级,时长(天),金额(分),赠送音币,状态,支付方式,创建时间\n")

		// 写入数据行
		for _, order := range orders {
			status := "待支付"
			if order.Status == 1 {
				status = "已支付"
			} else if order.Status == 2 {
				status = "已取消"
			}
			level := "VIP"
			if order.Level == 2 {
				level = "SVIP"
			}
			c.Writer.WriteString(fmt.Sprintf("%s,%s,%s,%d,%d,%d,%s,%s,%s\n",
				order.OrderNo, order.UserNickname, level, order.Duration,
				order.Amount, order.Coins, status, order.PayMethod,
				order.CreatedAt.Format("2006-01-02 15:04:05")))
		}
	}
}

// ==================== 音乐日记管理接口 ====================

// AdminGetDiaryList 管理后台获取音乐日记列表
func AdminGetDiaryList(db *gorm.DB) gin.HandlerFunc {
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
		mood := c.DefaultQuery("mood", "")

		offset := (page - 1) * pageSize
		var diaries []struct {
			model.MusicDiary
			UserNickname string `json:"user_nickname"`
		}
		var total int64

		query := db.Table("music_diaries").
			Select("music_diaries.*, users.nickname as user_nickname").
			Joins("LEFT JOIN users ON users.id = music_diaries.user_id")

		if userID > 0 {
			query = query.Where("music_diaries.user_id = ?", userID)
		}
		if mood != "" {
			query = query.Where("music_diaries.mood = ?", mood)
		}

		query.Count(&total).
			Offset(offset).Limit(pageSize).
			Order("music_diaries.id DESC").
			Find(&diaries)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     diaries,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// AdminDeleteDiary 管理后台删除音乐日记
func AdminDeleteDiary(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		idStr := c.Param("id")
		id, _ := strconv.ParseUint(idStr, 10, 32)
		db.Delete(&model.MusicDiary{}, uint(id))
		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "删除成功"})
	}
}

// ==================== 邀请记录管理接口 ====================

// AdminGetInviteList 管理后台获取邀请记录列表
func AdminGetInviteList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		inviterID, err := strconv.Atoi(c.DefaultQuery("inviter_id", "0"))
		if err != nil {
			inviterID = 0
		}
		status, err := strconv.Atoi(c.DefaultQuery("status", "-1"))
		if err != nil {
			status = -1
		}

		offset := (page - 1) * pageSize
		var records []model.InviteRecord
		var total int64

		query := db.Model(&model.InviteRecord{})
		if inviterID > 0 {
			query = query.Where("inviter_id = ?", inviterID)
		}
		if status >= 0 {
			query = query.Where("status = ?", status)
		}

		query.Count(&total).
			Offset(offset).Limit(pageSize).
			Order("id DESC").
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

// ==================== 音色克隆管理接口 ====================

// AdminGetVoiceCloneList 管理后台获取音色克隆列表
func AdminGetVoiceCloneList(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			page = 1
		}
		pageSize, err := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		if err != nil || pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		status := c.DefaultQuery("status", "")

		offset := (page - 1) * pageSize
		var clones []model.VoiceClone
		var total int64

		query := db.Model(&model.VoiceClone{})
		if status != "" {
			query = query.Where("status = ?", status)
		}

		query.Count(&total).
			Offset(offset).Limit(pageSize).
			Order("id DESC").
			Find(&clones)

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"list":     clones,
				"total":    total,
				"page":     page,
				"pageSize": pageSize,
			},
			"message": "success",
		})
	}
}

// ExportSongs 导出歌曲列表为CSV
func ExportSongs(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var songs []model.Song
		db.Find(&songs)

		// 设置CSV响应头
		c.Header("Content-Type", "text/csv; charset=utf-8")
		c.Header("Content-Disposition", "attachment; filename=songs.csv")

		// 写入BOM（解决Excel中文乱码）
		c.Writer.Write([]byte{0xEF, 0xBB, 0xBF})

		// 写入CSV表头
		c.Writer.WriteString("ID,标题,歌手,专辑,播放次数,点赞次数,状态,创建时间\n")

		// 写入数据行
		for _, song := range songs {
			status := "审核中"
			if song.Status == 1 {
				status = "正常"
			} else if song.Status == 2 {
				status = "下架"
			}
			c.Writer.WriteString(fmt.Sprintf("%d,%s,%s,%s,%d,%d,%s,%s\n",
				song.ID, song.Title, song.Singer, song.Album,
				song.PlayCount, song.LikeCount, status, song.CreatedAt.Format("2006-01-02 15:04:05")))
		}
	}
}

// ==================== 版本管理 ====================

// GetVersionConfig 获取版本配置
func GetVersionConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var versions []model.AppVersion
		if err := db.Order("platform ASC, version_code DESC").Find(&versions).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{"code": 500, "message": "获取失败"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"code": 200, "data": versions, "message": "success"})
	}
}

// SaveVersionConfig 保存版本配置
func SaveVersionConfig(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.AppVersion
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误"})
			return
		}

		if req.ID > 0 {
			// 更新
			if err := db.Model(&model.AppVersion{}).Where("id = ?", req.ID).Updates(map[string]interface{}{
				"version_code": req.VersionCode,
				"version_name": req.VersionName,
				"force_update": req.ForceUpdate,
				"update_url":   req.UpdateURL,
				"changelog":    req.Changelog,
				"is_active":    req.IsActive,
			}).Error; err != nil {
				c.JSON(http.StatusOK, gin.H{"code": 500, "message": "更新失败"})
				return
			}
		} else {
			// 新增
			if err := db.Create(&req).Error; err != nil {
				c.JSON(http.StatusOK, gin.H{"code": 500, "message": "创建失败"})
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{"code": 200, "message": "保存成功"})
	}
}

// VersionCheck APP版本检查
func VersionCheck(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		platform := c.Query("platform") // ios/android
		currentVersion, _ := strconv.Atoi(c.Query("version_code"))

		if platform == "" || currentVersion == 0 {
			c.JSON(http.StatusOK, gin.H{
				"code": 200,
				"data": gin.H{"need_update": false},
				"message": "success",
			})
			return
		}

		// 查询最新版本
		var latest model.AppVersion
		if err := db.Where("platform = ? AND is_active = true", platform).
			Order("version_code DESC").First(&latest).Error; err != nil {
			c.JSON(http.StatusOK, gin.H{
				"code": 200,
				"data": gin.H{"need_update": false},
				"message": "success",
			})
			return
		}

		needUpdate := latest.VersionCode > currentVersion

		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"data": gin.H{
				"need_update":  needUpdate,
				"force_update": needUpdate && latest.ForceUpdate,
				"version_code": latest.VersionCode,
				"version_name": latest.VersionName,
				"update_url":   latest.UpdateURL,
				"changelog":    latest.Changelog,
			},
			"message": "success",
		})
	}
}
