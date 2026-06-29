package model

import "gorm.io/gorm"

// Banner 轮播图/广告位
type Banner struct {
	gorm.Model
	Title     string `gorm:"size:64;comment:标题" json:"title"`
	Image     string `gorm:"size:256;comment:图片URL" json:"image"`
	Link      string `gorm:"size:256;comment:跳转链接" json:"link"`
	LinkType  int8   `gorm:"default:1;comment:1歌曲 2歌单 3活动 4外链" json:"link_type"`
	Position  string `gorm:"size:32;default:home;comment:位置:home/player/create" json:"position"`
	SortOrder int    `gorm:"default:0;comment:排序" json:"sort_order"`
	IsActive  bool   `gorm:"default:true;comment:是否启用" json:"is_active"`
	StartAt   *int64 `json:"start_at" gorm:"comment:开始时间戳"`
	EndAt     *int64 `json:"end_at" gorm:"comment:结束时间戳"`
}

// Topic 话题/标签
type Topic struct {
	gorm.Model
	Name      string `gorm:"size:64;uniqueIndex;comment:话题名称" json:"name"`
	Icon      string `gorm:"size:256;comment:图标URL" json:"icon"`
	PostCount int64  `gorm:"default:0;comment:关联动态数" json:"post_count"`
	SortOrder int    `gorm:"default:0;comment:排序" json:"sort_order"`
	IsActive  bool   `gorm:"default:true;comment:是否启用" json:"is_active"`
}

// Report 举报记录
type Report struct {
	gorm.Model
	ReporterID  uint   `gorm:"index;comment:举报者ID" json:"reporter_id"`
	TargetType  string `gorm:"size:32;comment:目标类型:song/post/comment/user" json:"target_type"`
	TargetID    uint   `gorm:"index;comment:目标ID" json:"target_id"`
	Reason      string `gorm:"size:128;comment:举报原因" json:"reason"`
	Description string `gorm:"size:512;comment:详细描述" json:"description"`
	Status      int8   `gorm:"default:0;comment:0待处理 1已处理 2已驳回" json:"status"`
	HandlerID   uint   `gorm:"comment:处理人ID" json:"handler_id"`
	HandleNote  string `gorm:"size:256;comment:处理备注" json:"handle_note"`
}

// UserBan 用户封禁记录
type UserBan struct {
	gorm.Model
	UserID    uint   `gorm:"index;comment:用户ID" json:"user_id"`
	Reason    string `gorm:"size:128;comment:封禁原因" json:"reason"`
	BanType   int8   `gorm:"default:1;comment:1禁言 2封号" json:"ban_type"`
	ExpireAt  *int64 `json:"expire_at" gorm:"comment:过期时间戳(null=永久)"`
	HandlerID uint   `gorm:"comment:操作人ID" json:"handler_id"`
}

// DailyStats 每日统计
type DailyStats struct {
	gorm.Model
	Date          string `gorm:"size:10;uniqueIndex;comment:日期yyyy-mm-dd" json:"date"`
	NewUsers      int    `gorm:"default:0;comment:新增用户" json:"new_users"`
	ActiveUsers   int    `gorm:"default:0;comment:活跃用户" json:"active_users"`
	NewSongs      int    `gorm:"default:0;comment:新增歌曲" json:"new_songs"`
	TotalPlays    int    `gorm:"default:0;comment:总播放次数" json:"total_plays"`
	NewPosts      int    `gorm:"default:0;comment:新增动态" json:"new_posts"`
	NewOrders     int    `gorm:"default:0;comment:新增订单" json:"new_orders"`
	Revenue       int    `gorm:"default:0;comment:收入(分)" json:"revenue"`
	AIGenerations int    `gorm:"default:0;comment:AI生成次数" json:"ai_generations"`
}

// Alert 告警记录
type Alert struct {
	gorm.Model
	Type      string `gorm:"size:32;index;comment:告警类型:rate_limit/quota_abuse/ip_abuse" json:"type"`
	Level     int8   `gorm:"default:1;index;comment:告警级别:1低 2中 3高" json:"level"`
	Target    string `gorm:"size:128;comment:告警目标(用户ID/IP等)" json:"target"`
	Message   string `gorm:"size:512;comment:告警信息" json:"message"`
	Status    int8   `gorm:"default:0;index;comment:处理状态:0未处理 1已处理" json:"status"`
	HandlerID uint   `gorm:"comment:处理人ID" json:"handler_id"`
}

// QuotaConfig 配额配置（单例，ID固定为1）
type QuotaConfig struct {
	gorm.Model
	// AI配额配置
	NormalDailyAI  int `gorm:"default:3;comment:普通用户每日AI次数" json:"normal_daily_ai"`
	VIPDailyAI     int `gorm:"default:20;comment:VIP用户每日AI次数" json:"vip_daily_ai"`
	SVIPDailyAI    int `gorm:"default:-1;comment:SVIP用户每日AI次数(-1表示无限制)" json:"svip_daily_ai"`
	NormalCoinPerAI int `gorm:"default:5;comment:普通用户每次AI消耗音币" json:"normal_coin_per_ai"`
	VIPCoinPerAI    int `gorm:"default:2;comment:VIP用户每次AI消耗音币" json:"vip_coin_per_ai"`
	SVIPCoinPerAI   int `gorm:"default:0;comment:SVIP用户每次AI消耗音币" json:"svip_coin_per_ai"`
	// 限流配置
	LoginRateLimit    int `gorm:"default:5;comment:登录限流(次/分钟)" json:"login_rate_limit"`
	RegisterRateLimit int `gorm:"default:3;comment:注册限流(次/小时)" json:"register_rate_limit"`
	AIRateLimit       int `gorm:"default:2;comment:AI生成限流(次/分钟)" json:"ai_rate_limit"`
}
