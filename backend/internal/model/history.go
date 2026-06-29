package model

import "gorm.io/gorm"

// PlayHistory 播放历史模型
type PlayHistory struct {
	gorm.Model
	UserID   uint `gorm:"index;comment:用户ID" json:"user_id"`
	SongID   uint `gorm:"index;comment:歌曲ID" json:"song_id"`
	PlayedAt int64 `gorm:"index;comment:播放时间戳" json:"played_at"`
}

func (PlayHistory) TableName() string {
	return "play_histories"
}
