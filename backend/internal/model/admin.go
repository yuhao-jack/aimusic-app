
package model

import (
	"gorm.io/gorm"
)

// Admin 管理员模型
type Admin struct {
	gorm.Model
	Username string `gorm:"size:50;uniqueIndex;not null" json:"username"`
	Password string `gorm:"size:255;not null" json:"-"`
	Nickname string `gorm:"size:50" json:"nickname"`
	Role     string `gorm:"size:20;default:admin" json:"role"` // admin/operator/visitor
	Status   int    `gorm:"default:1" json:"status"` // 1-正常 0-禁用
}

// AdminLoginLog 管理员登录日志
type AdminLoginLog struct {
	gorm.Model
	AdminID uint   `json:"admin_id"`
	IP      string `gorm:"size:50" json:"ip"`
}

// AdminOperationLog 管理员操作日志
type AdminOperationLog struct {
	gorm.Model
	AdminID   uint   `json:"admin_id"`
	AdminName string `gorm:"size:50" json:"admin_name"`
	Action    string `gorm:"size:100" json:"action"`
	Path      string `gorm:"size:200" json:"path"`
	IP        string `gorm:"size:50" json:"ip"`
}

// SystemConfig 系统配置
type SystemConfig struct {
	gorm.Model
	Key         string `gorm:"size:100;uniqueIndex;not null" json:"key"`
	Value       string `gorm:"type:text" json:"value"`
	Description string `gorm:"size:200" json:"description"`
}

// AppVersion APP版本管理
type AppVersion struct {
	gorm.Model
	Platform    string `gorm:"size:20;index;not null;comment:平台 ios/android" json:"platform"`
	VersionCode int    `gorm:"not null;comment:版本号(数字)" json:"version_code"`
	VersionName string `gorm:"size:20;not null;comment:版本名(如1.2.0)" json:"version_name"`
	ForceUpdate bool   `gorm:"default:false;comment:是否强制更新" json:"force_update"`
	UpdateURL   string `gorm:"size:255;comment:更新链接" json:"update_url"`
	Changelog   string `gorm:"type:text;comment:更新日志" json:"changelog"`
	IsActive    bool   `gorm:"default:true;comment:是否启用" json:"is_active"`
}
