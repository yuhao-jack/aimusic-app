package model

import (
	"time"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	OpenID         *string   `gorm:"size:64;uniqueIndex;comment:第三方登录唯一标识" json:"open_id"`
	Username       string    `gorm:"size:32;uniqueIndex;comment:用户名" json:"username"`
	Nickname       string    `gorm:"size:32;comment:用户昵称" json:"nickname"`
	Avatar         string    `gorm:"size:255;comment:头像地址" json:"avatar"`
	Bio            string    `gorm:"size:255;comment:个人简介" json:"bio"`
	Phone          *string   `gorm:"size:16;uniqueIndex;comment:手机号" json:"phone"`
	Email          string    `gorm:"size:64;comment:邮箱" json:"email"`
	Password       string    `gorm:"size:255;comment:密码" json:"-"`
	Status         int8      `gorm:"default:0;index;comment:用户状态：0正常 1禁用" json:"status"`
	MemberLevel    int8      `gorm:"default:0;index;comment:会员等级：0普通 1普通会员 2高级会员" json:"member_level"`
	MemberExpireAt *time.Time `gorm:"comment:会员过期时间" json:"member_expire_at"`
	DailyGenerateCount int    `gorm:"default:0;comment:今日生成次数" json:"-"`
	LastGenerateDate   string `gorm:"size:10;comment:最后生成日期yyyy-mm-dd" json:"-"`
	Coins              int    `gorm:"default:0;comment:音币余额" json:"coins"`
	DailyAICount       int    `gorm:"default:0;comment:今日AI使用次数" json:"daily_ai_count"`
	MaxDailyAI         int    `gorm:"default:3;comment:每日AI上限" json:"max_daily_ai"`
	LastCheckInDate    string `gorm:"size:10;comment:最后签到日期yyyy-mm-dd" json:"-"`
	InviteCode         string `gorm:"size:16;uniqueIndex;comment:我的邀请码" json:"invite_code"`
}

func (User) TableName() string {
	return "users"
}
