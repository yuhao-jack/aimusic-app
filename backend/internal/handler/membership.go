package handler

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"gorm.io/gorm"
)

// GetMembershipInfo 获取会员信息
func GetMembershipInfo(c *gin.Context) {
	userID := c.GetUint("user_id")

	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 检查会员是否过期
	isExpired := false
	if user.MemberExpireAt != nil && user.MemberExpireAt.Before(time.Now()) {
		isExpired = true
		user.MemberLevel = model.MemberLevelFree
		user.MemberExpireAt = nil
	}

	// 重置今日AI次数
	today := utils.GetTodayDate()
	resetAI := false
	if user.LastGenerateDate != today {
		user.DailyAICount = 0
		resetAI = true
	}

	// 使用事务批量更新，避免多次独立写入
	if isExpired || resetAI {
		db.DB.Transaction(func(tx *gorm.DB) error {
			if isExpired {
				tx.Model(&model.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
					"member_level":     model.MemberLevelFree,
					"member_expire_at": nil,
				})
			}
			if resetAI {
				tx.Model(&model.User{}).Where("id = ?", userID).Updates(map[string]interface{}{
					"daily_ai_count":       0,
					"daily_generate_count": 0,
					"last_generate_date":   today,
				})
			}
			return nil
		})
	}

	// 计算每日AI上限
	maxDailyAI := getMaxDailyAI(int(user.MemberLevel))

	utils.Success(c, gin.H{
		"member_level":     user.MemberLevel,
		"member_expire_at": user.MemberExpireAt,
		"is_expired":       isExpired,
		"coins":            user.Coins,
		"daily_ai_count":   user.DailyAICount,
		"max_daily_ai":     maxDailyAI,
	})
}

// GetVIPPlans 获取VIP套餐列表
func GetVIPPlans(c *gin.Context) {
	var plans []model.VIPPlan
	if err := db.DB.Where("is_active = ?", true).
		Order("sort_order ASC, id ASC").
		Find(&plans).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取套餐失败")
		return
	}

	utils.Success(c, plans)
}

// GetCoinPackages 获取音币充值包列表
func GetCoinPackages(c *gin.Context) {
	var packages []model.CoinPackage
	if err := db.DB.Where("is_active = ?", true).
		Order("sort_order ASC, id ASC").
		Find(&packages).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取充值包失败")
		return
	}

	utils.Success(c, packages)
}

// BuyVIPRequest 购买VIP请求
type BuyVIPRequest struct {
	PlanID    uint   `json:"plan_id" binding:"required"`
	PayMethod string `json:"pay_method" binding:"required"` // alipay/wechat/mock
}

// BuyVIP 购买VIP（模拟支付）
func BuyVIP(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req BuyVIPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 查询套餐
	var plan model.VIPPlan
	if err := db.DB.First(&plan, req.PlanID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "套餐不存在")
		return
	}

	if !plan.IsActive {
		utils.Fail(c, http.StatusBadRequest, "该套餐已下架")
		return
	}

	// 生成订单号
	orderNo := fmt.Sprintf("VIP%d%d%d", userID, time.Now().UnixMilli(), plan.ID)

	// 使用事务保证订单创建、会员开通、音币赠送的原子性
	tx := db.DB.Begin()

	// 创建订单
	order := model.MembershipOrder{
		UserID:    userID,
		OrderNo:   orderNo,
		Level:     plan.Level,
		Duration:  plan.Duration,
		Amount:    plan.Price,
		Coins:     plan.Coins,
		Status:    1, // 模拟支付，直接已支付
		PayMethod: req.PayMethod,
	}

	now := time.Now().Unix()
	order.PayTime = &now

	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建订单失败")
		return
	}

	// 开通会员
	var user model.User
	if err := tx.First(&user, userID).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "用户不存在")
		return
	}

	// 计算新的到期时间
	var newExpireAt time.Time
	if user.MemberExpireAt != nil && user.MemberExpireAt.After(time.Now()) {
		newExpireAt = user.MemberExpireAt.AddDate(0, 0, plan.Duration)
	} else {
		newExpireAt = time.Now().AddDate(0, 0, plan.Duration)
	}

	// 更新用户会员信息
	if err := tx.Model(&user).Updates(map[string]interface{}{
		"member_level":     plan.Level,
		"member_expire_at": newExpireAt,
		"max_daily_ai":     getMaxDailyAI(plan.Level),
	}).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "开通会员失败")
		return
	}

	// 赠送音币
	if plan.Coins > 0 {
		if err := tx.Model(&user).Update("coins", gorm.Expr("coins + ?", plan.Coins)).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "赠送音币失败")
			return
		}
		// 记录音币交易
		tx.First(&user, userID)
		coinRecord := model.CoinTransaction{
			UserID:      userID,
			Amount:      plan.Coins,
			Balance:     user.Coins,
			Type:        model.CoinTypeTaskReward,
			Description: "VIP套餐赠送音币",
			OrderNo:     orderNo,
		}
		if err := tx.Create(&coinRecord).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "记录音币交易失败")
			return
		}
	}

	tx.Commit()

	utils.Success(c, gin.H{
		"order_no":        orderNo,
		"member_level":    plan.Level,
		"member_expire_at": newExpireAt,
		"coins_added":     plan.Coins,
	})
}

// BuyCoinsRequest 购买音币请求
type BuyCoinsRequest struct {
	PackageID uint   `json:"package_id" binding:"required"`
	PayMethod string `json:"pay_method" binding:"required"` // alipay/wechat/mock
}

// BuyCoins 购买音币（模拟支付）
func BuyCoins(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req BuyCoinsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 查询充值包
	var pkg model.CoinPackage
	if err := db.DB.First(&pkg, req.PackageID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "充值包不存在")
		return
	}

	if !pkg.IsActive {
		utils.Fail(c, http.StatusBadRequest, "该充值包已下架")
		return
	}

	// 生成订单号
	orderNo := fmt.Sprintf("COIN%d%d%d", userID, time.Now().UnixMilli(), pkg.ID)

	// 使用事务保证订单创建和音币充值的原子性
	tx := db.DB.Begin()

	// 创建订单（复用MembershipOrder）
	order := model.MembershipOrder{
		UserID:    userID,
		OrderNo:   orderNo,
		Level:     0,
		Duration:  0,
		Amount:    pkg.Price,
		Coins:     pkg.Coins + pkg.Bonus,
		Status:    1, // 模拟支付，直接已支付
		PayMethod: req.PayMethod,
	}

	now := time.Now().Unix()
	order.PayTime = &now

	if err := tx.Create(&order).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建订单失败")
		return
	}

	// 充值音币
	totalCoins := pkg.Coins + pkg.Bonus
	var user model.User
	if err := tx.First(&user, userID).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "用户不存在")
		return
	}
	if err := tx.Model(&user).Update("coins", gorm.Expr("coins + ?", totalCoins)).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "充值失败")
		return
	}

	// 记录交易
	tx.First(&user, userID)
	coinRecord := model.CoinTransaction{
		UserID:      userID,
		Amount:      totalCoins,
		Balance:     user.Coins,
		Type:        model.CoinTypeRecharge,
		Description: "音币充值",
		OrderNo:     orderNo,
	}
	if err := tx.Create(&coinRecord).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "记录交易失败")
		return
	}

	tx.Commit()

	// 查询当前余额
	db.DB.First(&user, userID)

	utils.Success(c, gin.H{
		"order_no":      orderNo,
		"coins_added":   totalCoins,
		"coins_balance": user.Coins,
	})
}

// GetCoinRecords 获取音币交易记录
func GetCoinRecords(c *gin.Context) {
	userID := c.GetUint("user_id")

	page := 1
	pageSize := 20
	if p, err := strconv.Atoi(c.DefaultQuery("page", "1")); err == nil && p > 0 {
		page = p
	}
	if ps, err := strconv.Atoi(c.DefaultQuery("page_size", "20")); err == nil && ps > 0 && ps <= 100 {
		pageSize = ps
	}

	var records []model.CoinTransaction
	var total int64

	db.DB.Model(&model.CoinTransaction{}).Where("user_id = ?", userID).Count(&total)

	if err := db.DB.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset((page - 1) * pageSize).
		Limit(pageSize).
		Find(&records).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "获取记录失败")
		return
	}

	utils.Success(c, gin.H{
		"records":   records,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// CheckIn 每日签到领音币
func CheckIn(c *gin.Context) {
	userID := c.GetUint("user_id")

	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 检查今天是否已签到
	today := utils.GetTodayDate()
	if user.LastCheckInDate == today {
		utils.Fail(c, http.StatusBadRequest, "今日已签到，请明天再来")
		return
	}

	// 签到奖励：从 system_configs 表读取，默认 10 音币
	coinsReward := getSystemConfigInt("checkin_reward_coins", 10)

	// 使用事务+原子更新，防止并发签到竞态条件
	tx := db.DB.Begin()

	// 原子更新签到日期，仅当今天未签到时才更新
	result := tx.Model(&model.User{}).Where("id = ? AND last_check_in_date != ?", userID, today).
		Update("last_check_in_date", today)
	if result.Error != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "签到失败")
		return
	}

	// 如果没有更新任何行，说明并发签到或已签到
	if result.RowsAffected == 0 {
		tx.Rollback()
		utils.Fail(c, http.StatusBadRequest, "今日已签到，请明天再来")
		return
	}

	// 增加音币
	if err := tx.Model(&model.User{}).Where("id = ?", userID).Update("coins", gorm.Expr("coins + ?", coinsReward)).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "签到失败")
		return
	}

	// 重新查询获取最新余额
	tx.First(&user, userID)

	// 记录交易
	coinRecord := model.CoinTransaction{
		UserID:      userID,
		Amount:      coinsReward,
		Balance:     user.Coins,
		Type:        model.CoinTypeCheckIn,
		Description: "每日签到奖励",
	}
	if err := tx.Create(&coinRecord).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "签到失败")
		return
	}

	tx.Commit()

	utils.Success(c, gin.H{
		"coins_reward":  coinsReward,
		"coins_balance": user.Coins,
	})
}



// addCoins 增加音币并记录交易
func addCoins(userID uint, amount int, txType int, description string, orderNo string) int {
	// 使用事务保证原子性
	tx := db.DB.Begin()

	var user model.User
	if err := tx.First(&user, userID).Error; err != nil {
		tx.Rollback()
		return 0
	}

	// 原子更新音币余额，避免竞态条件
	if err := tx.Model(&user).Update("coins", gorm.Expr("coins + ?", amount)).Error; err != nil {
		tx.Rollback()
		return 0
	}

	// 重新查询获取最新余额
	tx.First(&user, userID)
	newBalance := user.Coins

	// 记录交易
	record := model.CoinTransaction{
		UserID:      userID,
		Amount:      amount,
		Balance:     newBalance,
		Type:        txType,
		Description: description,
		OrderNo:     orderNo,
	}
	if err := tx.Create(&record).Error; err != nil {
		tx.Rollback()
		return 0
	}

	tx.Commit()
	return newBalance
}

// DeductCoins 扣减音币并记录交易（供其他模块调用）
func DeductCoins(userID uint, amount int, txType int, description string, orderNo string) (int, error) {
	tx := db.DB.Begin()

	var user model.User
	if err := tx.First(&user, userID).Error; err != nil {
		tx.Rollback()
		return 0, err
	}

	if user.Coins < amount {
		tx.Rollback()
		return 0, fmt.Errorf("音币余额不足")
	}

	// 原子更新音币余额，避免竞态条件
	if err := tx.Model(&user).Update("coins", gorm.Expr("coins - ?", amount)).Error; err != nil {
		tx.Rollback()
		return 0, err
	}

	// 重新查询获取最新余额
	tx.First(&user, userID)
	newBalance := user.Coins

	record := model.CoinTransaction{
		UserID:      userID,
		Amount:      -amount,
		Balance:     newBalance,
		Type:        txType,
		Description: description,
		OrderNo:     orderNo,
	}
	if err := tx.Create(&record).Error; err != nil {
		tx.Rollback()
		return 0, err
	}

	tx.Commit()
	return newBalance, nil
}

// GetAIQuota 获取用户AI创作配额信息（今日使用次数、上限、会员等级）
func GetAIQuota(c *gin.Context) {
	userID := c.GetUint("user_id")

	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 检查并重置今日AI次数
	today := utils.GetTodayDate()
	if user.LastGenerateDate != today {
		db.DB.Model(&user).Updates(map[string]interface{}{
			"daily_ai_count":       0,
			"daily_generate_count": 0,
			"last_generate_date":   today,
		})
		user.DailyAICount = 0
	}

	// 计算每日AI上限
	maxDailyAI := getMaxDailyAI(int(user.MemberLevel))

	utils.Success(c, gin.H{
		"daily_ai_count": user.DailyAICount,
		"max_daily_ai":   maxDailyAI,
		"member_level":   user.MemberLevel,
		"coins":          user.Coins,
	})
}

// getMaxDailyAI 根据会员等级获取每日AI上限
func getMaxDailyAI(level int) int {
	switch level {
	case model.MemberLevelVIP:
		return 10
	case model.MemberLevelSVIP:
		return 999999 // 无限制
	default:
		return 3
	}
}

// getSystemConfigInt 从 system_configs 表读取整数配置，读取失败时返回默认值
func getSystemConfigInt(key string, defaultVal int) int {
	var cfg model.SystemConfig
	if err := db.DB.Where("`key` = ?", key).First(&cfg).Error; err != nil {
		return defaultVal
	}
	val, err := strconv.Atoi(cfg.Value)
	if err != nil {
		return defaultVal
	}
	return val
}

// InitDefaultData 初始化默认VIP套餐和音币充值包
func InitDefaultData() {
	// 初始化默认管理员账号（密码使用bcrypt加密）
	var adminCount int64
	db.DB.Model(&model.Admin{}).Count(&adminCount)
	if adminCount == 0 {
		// 从环境变量读取初始管理员密码
		adminPwd := os.Getenv("ADMIN_INIT_PASSWORD")
		if adminPwd == "" {
			// 环境变量未设置，使用crypto/rand生成随机16位密码
			randomBytes := make([]byte, 8)
			if _, err := rand.Read(randomBytes); err != nil {
				log.Printf("生成随机密码失败: %v", err)
				return
			}
			adminPwd = hex.EncodeToString(randomBytes)
			log.Printf("⚠️ 未设置ADMIN_INIT_PASSWORD环境变量，已生成随机管理员密码: %s", adminPwd)
			log.Printf("⚠️ 请立即保存此密码，它不会再次显示！")
		}
		hashedPwd, err := utils.HashPassword(adminPwd)
		if err == nil {
			db.DB.Create(&model.Admin{
				Username: "admin",
				Password: hashedPwd,
				Nickname: "超级管理员",
				Status:   1,
			})
			log.Println("默认管理员账号初始化完成（用户名: admin）")
		}
	}

	// 检查是否已有数据
	var planCount int64
	db.DB.Model(&model.VIPPlan{}).Count(&planCount)
	if planCount > 0 {
		return
	}

	// 默认VIP套餐
	vipPlans := []model.VIPPlan{
		{Name: "VIP月卡", Level: model.MemberLevelVIP, Duration: 30, Price: 1990, Coins: 100, SortOrder: 1, IsActive: true},
		{Name: "VIP季卡", Level: model.MemberLevelVIP, Duration: 90, Price: 4990, Coins: 300, IsPopular: true, SortOrder: 2, IsActive: true},
		{Name: "VIP年卡", Level: model.MemberLevelVIP, Duration: 365, Price: 15990, Coins: 1000, SortOrder: 3, IsActive: true},
		{Name: "SVIP月卡", Level: model.MemberLevelSVIP, Duration: 30, Price: 3990, Coins: 200, SortOrder: 4, IsActive: true},
		{Name: "SVIP季卡", Level: model.MemberLevelSVIP, Duration: 90, Price: 9990, Coins: 600, SortOrder: 5, IsActive: true},
		{Name: "SVIP年卡", Level: model.MemberLevelSVIP, Duration: 365, Price: 29990, Coins: 2000, IsPopular: true, SortOrder: 6, IsActive: true},
	}
	db.DB.Create(&vipPlans)

	// 默认音币充值包
	coinPackages := []model.CoinPackage{
		{Name: "60音币", Coins: 60, Price: 600, Bonus: 0, SortOrder: 1, IsActive: true},
		{Name: "300音币", Coins: 300, Price: 3000, Bonus: 30, SortOrder: 2, IsActive: true},
		{Name: "680音币", Coins: 680, Price: 6800, Bonus: 80, SortOrder: 3, IsActive: true},
		{Name: "1280音币", Coins: 1280, Price: 12800, Bonus: 200, SortOrder: 4, IsActive: true},
		{Name: "3280音币", Coins: 3280, Price: 32800, Bonus: 600, SortOrder: 5, IsActive: true},
		{Name: "6480音币", Coins: 6480, Price: 64800, Bonus: 1500, SortOrder: 6, IsActive: true},
	}
	db.DB.Create(&coinPackages)

	log.Println("默认VIP套餐和音币充值包初始化完成")
}
