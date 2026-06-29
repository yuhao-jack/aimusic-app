package router

import (
	"path/filepath"
	"time"

	"github.com/yourname/aimusic-backend/internal/handler"
	"github.com/yourname/aimusic-backend/internal/middleware"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func InitRouter(db *gorm.DB) *gin.Engine {
	if config.AppConfig.Server.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// 全局中间件
	r.Use(middleware.Cors())                      // CORS跨域（安全增强版，限制允许的Origin/Methods/Headers）
	r.Use(middleware.Logger())                    // 日志记录
	r.Use(middleware.Recovery())                  // 异常恢复
	r.Use(middleware.InputValidation())           // 全局输入验证（请求体大小、字符串长度、数字范围）

	// 静态文件服务 - 上传的文件
	uploadPath := filepath.Join(".", config.AppConfig.Upload.Path)
	r.Static("/uploads", uploadPath)

	// 获取可配置的API版本前缀，默认为 /api/v1
	apiVersion := config.AppConfig.Server.APIVersion
	if apiVersion == "" {
		apiVersion = "/api/v1"
	}

	// 公开路由组，不需要鉴权
	public := r.Group(apiVersion)
	{
		// 公开的关注列表
		public.GET("/user/followers/:user_id", handler.GetFollowers)
		public.GET("/user/following/:user_id", handler.GetFollowing)
	}
	{
		// 登录接口限流：同一IP每分钟最多5次
		public.POST("/user/login/phone",
			middleware.RateLimit(middleware.IPLimitByIP, 5, 1*time.Minute),
			handler.LoginByPhone)
		public.POST("/user/login/oauth",
			middleware.RateLimit(middleware.IPLimitByIP, 5, 1*time.Minute),
			handler.LoginByOAuth)
		public.POST("/user/login",
			middleware.RateLimit(middleware.IPLimitByIP, 5, 1*time.Minute),
			handler.LoginByPassword)
		// 注册接口限流：同一IP每小时最多3次
		public.POST("/user/register",
			middleware.RateLimit(middleware.IPLimitByIP, 10, 1*time.Minute),
			handler.RegisterByPassword)
		// 发送验证码限流：同一手机号每分钟最多1次
		public.POST("/user/send-reset-code",
			middleware.RateLimit(middleware.PhoneLimitByPhone, 1, 1*time.Minute),
			handler.SendResetCode)
		public.POST("/user/send-sms-code",
			middleware.RateLimit(middleware.PhoneLimitByPhone, 1, 1*time.Minute),
			handler.SendSmsCode)
		public.POST("/user/reset-password", handler.ResetPassword)
		public.GET("/music/recommend", handler.GetRecommendSongs)
		public.GET("/music/daily-recommend", handler.GetDailyRecommend)
		public.GET("/music/charts", handler.GetMusicCharts)
		public.GET("/music/rank/:type", handler.GetRankSongs)
		public.GET("/music/search", handler.SearchSongs)
		public.GET("/music/:song_id", handler.GetSongDetail)
		public.GET("/music/:song_id/comments", handler.GetSongComments)
		public.GET("/playlist/recommend", handler.GetRecommendPlaylists)
		public.GET("/playlist/:playlist_id", handler.GetPlaylistDetail)
		// 创作明星相关
		public.GET("/creator/stars", handler.GetCreatorStars)
		public.GET("/creator/:user_id", handler.GetCreatorDetail)
		// 刷新令牌（token过期后也可调用）
		public.POST("/user/refresh-token", handler.RefreshToken)
		public.GET("/post/list", handler.GetPostList)
		public.GET("/post/user/:user_id", handler.GetUserPostList)
		public.GET("/post/:post_id", handler.GetPostDetail)
		public.GET("/post/:post_id/comments", handler.GetPostComments)
		// 公开Banner（只返回已激活的）
		public.GET("/banners", handler.GetPublicBanners(db))
		// 公开系统配置（情绪、风格等前端选项）
		public.GET("/system/config", handler.GetPublicConfig(db))
		// 公开房间列表
		public.GET("/music/together/rooms", handler.GetPublicRooms)
		// 一起听社区动态
		public.GET("/music/together/feed", handler.GetTogetherFeed)
	}

	// WebSocket 路由（token 通过 query 参数传递）
	r.GET(apiVersion+"/music/together/ws/:room_id", handler.HandleTogetherWS)

	// 私有路由组，需要JWT鉴权
	private := r.Group(apiVersion)
	private.Use(middleware.JWTAuth())
	private.Use(middleware.CheckBan())
	private.Use(middleware.AntiSpam())            // 防刷检测
	private.Use(middleware.UserOperationLog())    // 用户操作审计
	{
		// 通用上传
		private.POST("/upload", handler.UploadFile)

		// 音乐日记
		diary := private.Group("/diary")
		{
			diary.GET("/list", handler.GetDiaryList)
			diary.POST("/create", handler.CreateDiary)
			diary.DELETE("/:id", handler.DeleteDiary)
		}

		// 用户模块
		user := private.Group("/user")
		{
			user.GET("/info", handler.GetUserInfo)
			user.PUT("/info", handler.UpdateUserInfo)
			user.PUT("/profile", handler.UpdateUserProfile)
			user.POST("/avatar", handler.UploadAvatar)
			user.GET("/works", handler.GetUserWorks)
			user.GET("/likes", handler.GetUserLikes)
			// 邀请系统
			user.GET("/invite-code", handler.GetInviteCode)
			user.GET("/invite-records", handler.GetInviteRecords)
			user.POST("/invite-code", handler.CreateInviteCode)
		}

		// AI创作模块（限流：同一用户每分钟最多2次）
		ai := private.Group("/ai")
		ai.Use(middleware.RateLimit(middleware.UserLimitByUserID, 2, 1*time.Minute))
		ai.Use(middleware.CheckLargeCoinConsumption()) // 大额音币消费确认
		{
			ai.POST("/lyric/generate", handler.GenerateLyric)
			ai.POST("/lyric/optimize", handler.OptimizeLyric)
			ai.POST("/song/generate", handler.GenerateSong)
			ai.GET("/task/:task_id/progress", handler.GetTaskProgress)
		}

		// 音乐模块
		music := private.Group("/music")
		{
			music.POST("/:song_id/play", handler.IncrementPlayCount)
			music.POST("/:song_id/like", handler.LikeSong)
			music.POST("/:song_id/comment", handler.AddComment)
			// 歌词海报数据
			music.GET("/:song_id/lyric-poster", handler.GetLyricPoster)
			// 一起听房间
			music.POST("/together/create", handler.CreateTogetherRoom)
			music.POST("/together/join/:room_code", handler.JoinTogetherRoom)
			music.POST("/together/leave/:room_id", handler.LeaveTogetherRoom)
			music.GET("/together/room/:room_id", handler.GetRoomInfo)
			music.PUT("/together/room/:room_id", handler.UpdateRoom)
			music.POST("/together/room/:room_id/kick/:member_id", handler.KickMember)
			music.GET("/together/my-rooms", handler.GetMyRooms)
		}

		// 播放历史
		history := private.Group("/history")
		{
			history.GET("", handler.GetPlayHistory)
			history.POST("", handler.AddPlayHistory)
			history.DELETE("", handler.ClearPlayHistory)
			history.DELETE("/:id", handler.RemovePlayHistoryItem)
		}

		// 听歌报告
		report := private.Group("/report")
		{
			report.GET("/weekly", handler.GetWeeklyReport(db))
		}

		// 音色克隆
		voice := private.Group("/voice")
		{
			voice.GET("/clones", handler.GetVoiceClones)
			voice.GET("/clones/:id", handler.GetVoiceClone)
			voice.POST("/clones", handler.CreateVoiceClone)
			voice.PUT("/clones/:id", handler.UpdateVoiceClone)
			voice.DELETE("/clones/:id", handler.DeleteVoiceClone)
		}

		// 歌单模块
		playlist := private.Group("/playlist")
		{
			playlist.GET("/list", handler.GetUserPlaylists)
			playlist.POST("/create", handler.CreatePlaylist)
			playlist.PUT("/:playlist_id", handler.UpdatePlaylist)
			playlist.DELETE("/:playlist_id", handler.DeletePlaylist)
			playlist.POST("/:playlist_id/add", handler.AddSongToPlaylist)
			playlist.DELETE("/:playlist_id/song/:song_id", handler.RemoveSongFromPlaylist)
			playlist.POST("/:playlist_id/like", handler.LikePlaylist)
		}

		// 动态模块（用户发帖 - 写操作需登录）
		post := private.Group("/post")
		{
			post.POST("/create", handler.CreatePost)
			post.DELETE("/:post_id", handler.DeletePost)
			post.POST("/:post_id/like", handler.LikePost)
			post.POST("/:post_id/comment", handler.AddPostComment)
			post.DELETE("/comment/:comment_id", handler.DeletePostComment)
			post.POST("/report", handler.ReportPost)
		}

		// 互动模块
		interact := private.Group("")
		{
			// 关注
			interact.POST("/user/follow/:target_id", handler.FollowUser)
			interact.POST("/user/unfollow/:target_id", handler.UnfollowUser)
			interact.GET("/user/follow/status", handler.GetFollowStatus)
			// 通知
			interact.GET("/notifications", handler.GetNotifications)
			interact.PUT("/notifications/:id/read", handler.MarkNotificationRead)
			interact.PUT("/notifications/read-all", handler.MarkAllRead)
			interact.GET("/notifications/unread-count", handler.GetUnreadCount)
		}

		// 会员模块
		membership := private.Group("/membership")
		{
			membership.GET("/info", handler.GetMembershipInfo)
			membership.GET("/vip-plans", handler.GetVIPPlans)
			membership.GET("/coin-packages", handler.GetCoinPackages)
			membership.POST("/buy-vip", handler.BuyVIP)
			membership.POST("/buy-coins", handler.BuyCoins)
			membership.GET("/coin-records", handler.GetCoinRecords)
			membership.POST("/check-in", handler.CheckIn)
			membership.GET("/ai-quota", handler.GetAIQuota)
		}
	}

	// 后台管理路由组
	admin := r.Group("/api/admin")
	{
		// 登录不需要鉴权
		admin.POST("/login", handler.AdminLoginHandler(db))

		// 需要管理员鉴权
		admin.Use(middleware.AdminJWTAuth())
		admin.Use(middleware.AdminAuditLog())
		{
			// 仪表盘
			admin.GET("/dashboard/stats", handler.GetDashboardStats(db))

			// 用户管理
			admin.GET("/users", handler.GetUserList(db))
			admin.PUT("/users/:id", handler.UpdateUser(db))
			admin.DELETE("/users/:id", handler.DeleteUser(db))

			// 歌曲管理
			admin.GET("/songs", handler.GetSongList(db))
			admin.POST("/songs", handler.CreateSong(db))
			admin.PUT("/songs/:id", handler.UpdateSong(db))
			admin.DELETE("/songs/:id", handler.DeleteSong(db))

			// AI任务管理
			admin.GET("/ai-tasks", handler.GetAiTaskList(db))

			// 评论管理
			admin.GET("/comments", handler.GetCommentList(db))
			admin.DELETE("/comments/:id", handler.DeleteComment(db))

			// 内容审核
			admin.GET("/audit", handler.GetAuditList(db))
			admin.POST("/audit/:id/pass", handler.AuditPass(db))
			admin.POST("/audit/:id/reject", handler.AuditReject(db))

			// 动态管理
			admin.GET("/posts", handler.AdminGetPostList(db))
			admin.DELETE("/posts/:id", handler.AdminDeletePost(db))

			// 一起听房间管理
			admin.GET("/together-rooms", handler.GetRoomList(db))
			admin.POST("/together-rooms/:id/close", handler.CloseTogetherRoom(db))

			// 系统配置
			admin.GET("/system/config", handler.GetSystemConfig(db))
			admin.POST("/system/config", handler.SaveSystemConfig(db))
			admin.GET("/system/logs", handler.GetOperationLogs(db))

			// 商业化管理
			// 会员管理
			admin.GET("/members", handler.GetMemberList(db))
			admin.PUT("/members/:id", handler.UpdateMember(db))
			// VIP套餐管理
			admin.GET("/vip-plans", handler.GetVIPPlanList(db))
			admin.POST("/vip-plans", handler.CreateVIPPlan(db))
			admin.PUT("/vip-plans/:id", handler.UpdateVIPPlan(db))
			admin.DELETE("/vip-plans/:id", handler.DeleteVIPPlan(db))
			// 音币充值包管理
			admin.GET("/coin-packages", handler.GetCoinPackageList(db))
			admin.POST("/coin-packages", handler.CreateCoinPackage(db))
			admin.PUT("/coin-packages/:id", handler.UpdateCoinPackage(db))
			admin.DELETE("/coin-packages/:id", handler.DeleteCoinPackage(db))
			// 音币交易记录
			admin.GET("/coin-records", handler.GetCoinRecordList(db))
			// 会员订单
			admin.GET("/orders", handler.GetOrderList(db))

			// 运营管理
			// Banner管理
			admin.GET("/banners", handler.GetBannerList(db))
			admin.POST("/banners", handler.CreateBanner(db))
			admin.PUT("/banners/:id", handler.UpdateBanner(db))
			admin.DELETE("/banners/:id", handler.DeleteBanner(db))
			// 话题管理
			admin.GET("/topics", handler.GetTopicList(db))
			admin.POST("/topics", handler.CreateTopic(db))
			admin.PUT("/topics/:id", handler.UpdateTopic(db))
			admin.DELETE("/topics/:id", handler.DeleteTopic(db))

			// 风控管理
			// 举报管理
			admin.GET("/reports", handler.GetReportList(db))
			admin.POST("/reports/:id/handle", handler.HandleReport(db))
			// 封禁管理
			admin.GET("/bans", handler.GetBanList(db))
			admin.POST("/bans", handler.BanUser(db))
			admin.POST("/bans/:id/unban", handler.UnbanUser(db))

			// 数据统计
			admin.GET("/dashboard/overview", handler.GetDashboardOverview(db))
			admin.GET("/dashboard/trend", handler.GetDashboardTrend(db))
			admin.GET("/dashboard/distribution", handler.GetDashboardDistribution(db))

			// 运营分析
			admin.GET("/analytics/user-behavior", handler.GetUserBehaviorData(db))
			admin.GET("/analytics/retention", handler.GetRetentionData(db))
			admin.GET("/analytics/funnel", handler.GetFunnelData(db))
			admin.GET("/analytics/revenue", handler.GetRevenueData(db))

			// 运营监控
			// 告警管理
			admin.GET("/alerts", handler.GetAlertList(db))
			admin.PUT("/alerts/:id/handle", handler.HandleAlert(db))
			// 实时监控
			admin.GET("/monitor/stats", handler.GetMonitorStats(db))
			// 配额配置
			admin.GET("/quota-config", handler.GetQuotaConfig(db))
			admin.POST("/quota-config", handler.SaveQuotaConfig(db))

			// 活动/公告管理
			admin.GET("/activities", handler.GetActivityList(db))
			admin.POST("/activities", handler.CreateActivity(db))
			admin.PUT("/activities/:id", handler.UpdateActivity(db))
			admin.DELETE("/activities/:id", handler.DeleteActivity(db))

			// 数据导出
			admin.GET("/export/users", handler.ExportUsers(db))
			admin.GET("/export/orders", handler.ExportOrders(db))
			admin.GET("/export/songs", handler.ExportSongs(db))
		}
	}

	return r
}
