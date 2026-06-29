package model

import "gorm.io/gorm"

// 告警类型常量
const (
	AlertTypeRateLimit  = "rate_limit"  // 限流告警
	AlertTypeQuotaAbuse = "quota_abuse" // 配额滥用
	AlertTypeIPAbuse    = "ip_abuse"    // IP异常
)

// SystemAlert 系统运营告警
type SystemAlert struct {
	gorm.Model
	Type      string `gorm:"size:32;index;comment:类型:rate_limit/quota_abuse/ip_abuse" json:"type"`
	Level     int8   `gorm:"default:1;index;comment:1低 2中 3高" json:"level"`
	Target    string `gorm:"size:64;index;comment:目标(user_id或IP)" json:"target"`
	Message   string `gorm:"size:256;comment:告警信息" json:"message"`
	IsHandled bool   `gorm:"default:false;index;comment:是否已处理" json:"is_handled"`
}

func (SystemAlert) TableName() string {
	return "system_alerts"
}
