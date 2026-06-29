package model

import (
	"gorm.io/gorm"
	"encoding/json"
)

type GenerateSongRequest struct {
	Lyric   string `json:"lyric" binding:"required"` // 歌词
	Style   string `json:"style" binding:"required"` // 音乐风格
	Emotion string `json:"emotion" binding:"required"`// 情绪
	VoiceID string `json:"voice_id" default:"0"`     // 音色ID
	Duration int `json:"duration" default:"180"`     // 时长秒
	Title   string `json:"title" binding:"required"` // 歌曲标题
}

type AsyncTask struct {
	gorm.Model
	TaskType     int8            `gorm:"index;comment:任务类型：1音乐生成 2音色训练 3MV渲染" json:"task_type"`
	UserID       uint            `gorm:"index;comment:所属用户ID" json:"user_id"`
	Params       json.RawMessage `gorm:"type:json;comment:任务参数" json:"params"`
	Status       int8            `gorm:"default:0;index;comment:状态：0等待中 1处理中 2成功 3失败" json:"status"`
	Progress     int             `gorm:"default:0;comment:进度 0-100" json:"progress"`
	Result       json.RawMessage `gorm:"type:json;comment:任务结果" json:"result"`
	ErrorMsg     string          `gorm:"size:255;comment:错误信息" json:"error_msg"`
}

const (
	TaskStatusWaiting = 0
	TaskStatusRunning = 1
	TaskStatusSuccess = 2
	TaskStatusFailed  = 3

	TaskTypeMusicGenerate = 1
	TaskTypeVoiceTrain    = 2
	TaskTypeMVGenerate    = 3
)

func (AsyncTask) TableName() string {
	return "async_tasks"
}
