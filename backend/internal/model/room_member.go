package model

import "gorm.io/gorm"

// RoomMember 房间成员关联表
type RoomMember struct {
	gorm.Model
	RoomID uint `gorm:"index;comment:房间ID"`
	UserID uint `gorm:"index;comment:用户ID"`
	Role   int8 `gorm:"default:0;comment:0成员 1房主"`
}

func (RoomMember) TableName() string {
	return "room_members"
}
