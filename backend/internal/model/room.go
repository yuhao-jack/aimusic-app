package model

import "gorm.io/gorm"

// TogetherRoom 一起听房间
type TogetherRoom struct {
	gorm.Model
	RoomCode   string `gorm:"size:6;uniqueIndex;comment:房间邀请码"`
	Name       string `gorm:"size:64;comment:房间名称"`
	Password   string `gorm:"size:16;comment:房间密码(空=无密码)"`
	Description string `gorm:"size:256;comment:房间描述"`
	CreatorID  uint   `gorm:"index;comment:创建者ID"`
	SongID     uint   `gorm:"index;comment:当前播放歌曲ID"`
	Status     int8   `gorm:"default:1;comment:1进行中 2已结束"`
	MaxMembers int    `gorm:"default:10;comment:最大成员数"`
	Members    string `gorm:"type:text;comment:成员ID列表JSON"`
	NowPlaying int8   `gorm:"default:0;comment:0暂停 1播放中"`
}

func (TogetherRoom) TableName() string {
	return "together_rooms"
}
