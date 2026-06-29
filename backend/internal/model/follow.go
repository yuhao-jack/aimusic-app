package model

import (
	"gorm.io/gorm"
)

// Follow 关注关系
type Follow struct {
	gorm.Model
	FollowerID  uint   `gorm:"index:idx_follower_following;not null;comment:关注者用户ID" json:"follower_id"`
	FollowingID uint   `gorm:"index:idx_follower_following;not null;comment:被关注者用户ID" json:"following_id"`
}

func (Follow) TableName() string {
	return "follows"
}
