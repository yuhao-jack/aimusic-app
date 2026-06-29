package model

import "gorm.io/gorm"

type Comment struct {
	gorm.Model
	UserID   uint   `gorm:"index;comment:用户ID"`
	SongID   uint   `gorm:"index;comment:歌曲ID"`
	Content string `gorm:"size:500;comment:评论内容"`
	LikeCount int  `gorm:"default:0;comment:点赞数"`
	ParentID uint   `gorm:"default:0;comment:父评论ID，二级评论"`
	Status   int8   `gorm:"default:1;index;comment:状态：0审核中 1正常 2下架"`
}

func (Comment) TableName() string {
	return "comments"
}
