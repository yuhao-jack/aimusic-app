package model

import "gorm.io/gorm"

// VoiceClone 音色克隆模型
type VoiceClone struct {
	gorm.Model
	UserID      uint   `gorm:"index;comment:用户ID" json:"user_id"`
	Name        string `gorm:"size:100;comment:音色名称" json:"name"`
	Description string `gorm:"type:text;comment:音色描述" json:"description"`
	VoiceType   string `gorm:"size:50;comment:音色类型（original/cloned" json:"voice_type"`
	Status     string `gorm:"size:20;default:'pending';comment:状态（pending/processing/completed/failed" json:"status"`
	Progress   int    `gorm:"default:0;comment:克隆进度 0-100" json:"progress"`
	ErrorMsg   string `gorm:"type:text;comment:错误信息" json:"error_msg"`
	AudioURL   string `gorm:"size:500;comment:上传的音频URL" json:"audio_url"`
	VoiceURL   string `gorm:"size:500;comment:克隆后的音色URL" json:"voice_url"`
}

func (VoiceClone) TableName() string {
	return "voice_clones"
}
