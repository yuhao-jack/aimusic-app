package model

import "gorm.io/gorm"

// Discount 限时折扣活动
type Discount struct {
	gorm.Model
	Name          string `json:"name" gorm:"size:64;comment:活动名称"`
	Level         int    `json:"level" gorm:"comment:适用会员等级 1VIP 2SVIP"`
	Duration      int    `json:"duration" gorm:"comment:会员时长（天）"`
	OriginalPrice int    `json:"original_price" gorm:"comment:原价（分）"`
	DiscountPrice int    `json:"discount_price" gorm:"comment:折扣价（分）"`
	StartAt       int64  `json:"start_at" gorm:"comment:活动开始时间戳"`
	EndAt         int64  `json:"end_at" gorm:"comment:活动结束时间戳"`
	IsActive      bool   `json:"is_active" gorm:"default:true;comment:是否启用"`
}

func (Discount) TableName() string {
	return "discounts"
}
