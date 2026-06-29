package model

import "gorm.io/gorm"

// Notification 用户通知模型
type Notification struct {
	gorm.Model
	UserID     uint   `gorm:"index;not null;comment:接收通知的用户ID" json:"user_id"`
	ActorID    uint   `gorm:"not null;comment:触发通知的用户ID" json:"actor_id"`
	ActionType string `gorm:"size:32;index;not null;comment:通知类型:like/follow/comment/reply" json:"action_type"`
	TargetType string `gorm:"size:32;not null;comment:目标类型:song/playlist/post/comment" json:"target_type"`
	TargetID   uint   `gorm:"comment:目标资源ID" json:"target_id"`
	Content    string `gorm:"size:255;comment:预览内容" json:"content"`
	IsRead     int8   `gorm:"default:0;index;comment:是否已读:0未读 1已读" json:"is_read"`
}

func (Notification) TableName() string {
	return "notifications"
}
