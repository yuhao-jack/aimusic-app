package model

import "gorm.io/gorm"

// MV MV生成模型
type MV struct {
	gorm.Model
	UserID      uint   `gorm:"index;comment:用户ID" json:"user_id"`
	SongID      uint   `gorm:"index;comment:歌曲ID" json:"song_id"`
	Name        string `gorm:"size:100;comment:MV名称" json:"name"`
	Description string `gorm:"type:text;comment:MV描述" json:"description"`
	Template    string `gorm:"size:50;comment:MV模板" json:"template"`
	Status      string `gorm:"size:20;default:'pending';comment:状态" json:"status"`
	Progress    int    `gorm:"default:0;comment:生成进度 0-100" json:"progress"`
	ErrorMsg    string `gorm:"type:text;comment:错误信息" json:"error_msg"`
	MaterialURL string `gorm:"size:500;comment:素材URL" json:"material_url"`
	VideoURL    string `gorm:"size:500;comment:生成的视频URL" json:"video_url"`
	Resolution  string `gorm:"size:20;default:'1080p';comment:分辨率" json:"resolution"`
}

func (MV) TableName() string {
	return "mvs"
}
