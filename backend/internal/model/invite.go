package model

import "gorm.io/gorm"

// InviteRecord 邀请记录模型
type InviteRecord struct {
	gorm.Model
	InviterID uint   `gorm:"index;comment:邀请者ID" json:"inviter_id"`
	InviteeID uint   `gorm:"index;comment:被邀请者ID" json:"invitee_id"`
	InviteCode string `gorm:"size:16;uniqueIndex;comment:邀请码" json:"invite_code"`
	Reward    int    `gorm:"default:100;comment:奖励音币" json:"reward"`
	Status    int8   `gorm:"default:0;comment:0待注册 1已注册 2已奖励" json:"status"`
}

func (InviteRecord) TableName() string {
	return "invite_records"
}
