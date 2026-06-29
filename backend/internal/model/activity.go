package model

import "gorm.io/gorm"

// Activity 活动/公告模型
type Activity struct {
	gorm.Model
	Title     string `gorm:"size:128;comment:标题" json:"title"`
	Content   string `gorm:"type:text;comment:内容" json:"content"`
	Cover     string `gorm:"size:256;comment:封面图URL" json:"cover"`
	Type      int8   `gorm:"default:1;comment:类型:1公告 2活动 3比赛" json:"type"`
	StartAt   int64  `gorm:"comment:开始时间戳" json:"start_at"`
	EndAt     int64  `gorm:"comment:结束时间戳" json:"end_at"`
	IsActive  bool   `gorm:"default:true;comment:是否启用" json:"is_active"`
	SortOrder int    `gorm:"default:0;comment:排序" json:"sort_order"`
}
