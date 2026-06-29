package model

import "gorm.io/gorm"

// 会员等级常量
const (
	MemberLevelFree = 0 // 普通用户
	MemberLevelVIP  = 1 // VIP
	MemberLevelSVIP = 2 // SVIP
)

// MembershipOrder 会员订单
type MembershipOrder struct {
	gorm.Model
	UserID    uint   `json:"user_id" gorm:"index"`
	OrderNo   string `json:"order_no" gorm:"uniqueIndex;size:64"` // 订单号
	Level     int    `json:"level"`                                // 会员等级 1=VIP 2=SVIP
	Duration  int    `json:"duration"`                             // 时长（天）
	Amount    int    `json:"amount"`                               // 金额（分）
	Coins     int    `json:"coins"`                                // 赠送音币
	Status    int    `json:"status" gorm:"default:0"`              // 0待支付 1已支付 2已取消
	PayMethod string `json:"pay_method" gorm:"size:32"`            // 支付方式
	PayTime   *int64 `json:"pay_time"`                             // 支付时间戳
}

// CoinTransaction 音币交易记录
type CoinTransaction struct {
	gorm.Model
	UserID      uint   `json:"user_id" gorm:"index"`
	Amount      int    `json:"amount"`                        // 变动数量（正数收入，负数支出）
	Balance     int    `json:"balance"`                       // 变动后余额
	Type        int    `json:"type"`                          // 1充值 2签到 3任务奖励 4AI消耗 5退款
	Description string `json:"description" gorm:"size:128"`
	OrderNo     string `json:"order_no" gorm:"size:64"`       // 关联订单号
}

// CoinPackage 音币充值包
type CoinPackage struct {
	gorm.Model
	Name      string `json:"name" gorm:"size:64"`
	Coins     int    `json:"coins"`                          // 音币数量
	Price     int    `json:"price"`                          // 价格（分）
	Bonus     int    `json:"bonus"`                          // 赠送音币
	SortOrder int    `json:"sort_order" gorm:"default:0"`
	IsActive  bool   `json:"is_active" gorm:"default:true"`
}

// VIPPlan VIP套餐
type VIPPlan struct {
	gorm.Model
	Name      string `json:"name" gorm:"size:64"`
	Level     int    `json:"level"`                          // 1=VIP 2=SVIP
	Duration  int    `json:"duration"`                       // 天数
	Price     int    `json:"price"`                          // 价格（分）
	Coins     int    `json:"coins"`                          // 赠送音币
	IsPopular bool   `json:"is_popular" gorm:"default:false"` // 热门推荐
	SortOrder int    `json:"sort_order" gorm:"default:0"`
	IsActive  bool   `json:"is_active" gorm:"default:true"`
}

// 音币交易类型常量
const (
	CoinTypeRecharge   = 1 // 充值
	CoinTypeCheckIn    = 2 // 签到
	CoinTypeTaskReward = 3 // 任务奖励
	CoinTypeAIConsume  = 4 // AI消耗
	CoinTypeRefund     = 5 // 退款
)
