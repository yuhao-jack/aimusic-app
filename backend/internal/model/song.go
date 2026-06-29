package model

import "gorm.io/gorm"

type Song struct {
	gorm.Model
	UserID     uint   `gorm:"index;comment:所属用户ID，官方内容为0" json:"user_id"`
	Title      string `gorm:"size:128;index;comment:歌曲名称" json:"title"`
	Singer     string `gorm:"size:64;comment:歌手名" json:"singer"`
	Cover      string `gorm:"size:255;comment:封面图地址" json:"cover"`
	AudioURL   string `gorm:"size:255;comment:音频文件地址" json:"audio_url"`
	Lyric      string `gorm:"type:text;comment:歌词内容" json:"lyric"`
	Style      string `gorm:"size:32;index;comment:音乐风格" json:"style"`
	Emotion    string `gorm:"size:32;index;comment:情绪标签" json:"emotion"`
	Duration   int    `gorm:"comment:时长，单位秒" json:"duration"`
	PlayCount  int    `gorm:"default:0;index;comment:播放次数" json:"play_count"`
	LikeCount  int    `gorm:"default:0;index;comment:点赞次数" json:"like_count"`
	Status     int8   `gorm:"default:0;index;comment:状态：0审核中 1正常 2下架" json:"status"`
	CopyrightID string `gorm:"size:64;uniqueIndex;comment:版权唯一标识" json:"copyright_id"`
	IsPublic   int8   `gorm:"default:1;index;comment:是否公开：0私有 1公开" json:"is_public"`
}

func (Song) TableName() string {
	return "songs"
}
