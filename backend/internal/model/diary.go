package model

import "gorm.io/gorm"

// MusicDiary 音乐日记
type MusicDiary struct {
	gorm.Model
	UserID    uint   `gorm:"index;comment:用户ID"`
	Content   string `gorm:"type:text;comment:日记内容"`
	Mood      string `gorm:"size:32;comment:心情标签"`
	SongID    uint   `gorm:"comment:关联歌曲ID"`
	SongTitle string `gorm:"size:128;comment:歌曲标题"`
	SongCover string `gorm:"size:256;comment:歌曲封面"`
	IsPublic  bool   `gorm:"default:true;comment:是否公开"`
}

func (MusicDiary) TableName() string {
	return "music_diaries"
}
