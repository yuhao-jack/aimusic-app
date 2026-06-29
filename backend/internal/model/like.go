package model

import (
	"gorm.io/gorm"
)

// Like 点赞记录
type Like struct {
	gorm.Model
	UserID    uint   `gorm:"index:idx_user_like;not null;comment:用户ID" json:"user_id"`
	TargetID  uint   `gorm:"index:idx_user_like;not null;comment:目标ID" json:"target_id"`
	LikeType  string `gorm:"size:32;index;not null;comment:点赞类型：song/playlist/post" json:"like_type"`
}

func (Like) TableName() string {
	return "likes"
}
