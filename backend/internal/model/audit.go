
package model

import (
	"gorm.io/gorm"
)

// Audit 内容审核记录表
type Audit struct {
	gorm.Model
	ContentType string `gorm:"size:20;not null" json:"content_type"` // post/comment
	ContentID   uint   `gorm:"not null" json:"content_id"`
	UserID      uint   `json:"user_id"`
	Content     string `gorm:"type:text" json:"content"`
	Status      int    `gorm:"default:0" json:"status"` // 0-待审核 1-通过 2-拒绝
	AuditAt     int64  `json:"audit_at"`
	AuditAdmin  uint   `json:"audit_admin"`
}
