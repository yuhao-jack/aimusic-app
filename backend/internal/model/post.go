package model

import (
	"time"
)

// Post 用户动态发帖模型
type Post struct {
	ID        uint       `json:"id" gorm:"primaryKey"`
	UserID    uint       `json:"user_id" gorm:"index"`
	Content   string     `json:"content" gorm:"type:text"`
	Images    string     `json:"images" gorm:"type:text"` // JSON 格式存储图片URL数组
	LikeCount int        `json:"like_count" gorm:"default:0"`
	CommentCount int    `json:"comment_count" gorm:"default:0"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

// PostComment 动态评论模型
type PostComment struct {
	ID         uint       `json:"id" gorm:"primaryKey"`
	PostID     uint       `json:"post_id" gorm:"index"`
	UserID     uint       `json:"user_id" gorm:"index"`
	ParentID   uint       `json:"parent_id" gorm:"default:0"` // 0一级评论，大于0回复
	Content    string     `json:"content"`
	LikeCount  int        `json:"like_count" gorm:"default:0"`
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`
	DeletedAt  *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

// PostLike 用户点赞动态记录
type PostLike struct {
	ID        uint       `json:"id" gorm:"primaryKey"`
	PostID    uint       `json:"post_id" gorm:"index"`
	UserID    uint       `json:"user_id" gorm:"index"`
	CreatedAt time.Time  `json:"created_at"`
}
