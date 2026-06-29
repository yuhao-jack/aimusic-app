package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"gorm.io/gorm"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/ai"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

var aiService ai.AIService

// InitAIService 初始化AI服务
func InitAIService(service ai.AIService) {
	aiService = service
}

type GenerateLyricRequest struct {
	Prompt  string `json:"prompt" binding:"required"` // 主题关键词
	Style   string `json:"style" binding:"required"`  // 风格：流行/说唱/民谣等
	Emotion string `json:"emotion" binding:"required"`// 情绪：开心/悲伤等
	Lang    string `json:"lang" default:"zh"`         // 语言
}

// GenerateLyric 生成歌词
// 策略：先扣费→调用AI→失败时退款
func GenerateLyric(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req GenerateLyricRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 查询用户信息
	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusUnauthorized, "用户不存在")
		return
	}

	// 检查每日AI配额
	today := utils.GetTodayDate()
	if user.LastGenerateDate != today {
		user.DailyGenerateCount = 0
		user.LastGenerateDate = today
		user.DailyAICount = 0
	}

	maxDaily := getMaxDailyAI(int(user.MemberLevel))
	if user.DailyAICount >= maxDaily {
		utils.Fail(c, http.StatusTooManyRequests, "今日AI生成次数已用完")
		return
	}

	// 计算本次消耗音币
	coinsCost := getAICoinsCost(user.MemberLevel)
	if coinsCost > 0 && user.Coins < coinsCost {
		utils.Fail(c, http.StatusPaymentRequired, "音币余额不足")
		return
	}

	// 使用事务保证扣费和配额更新的原子性
	tx := db.DB.Begin()

	if coinsCost > 0 {
		result := tx.Model(&user).Where("coins >= ?", coinsCost).Update("coins", gorm.Expr("coins - ?", coinsCost))
		if result.RowsAffected == 0 {
			tx.Rollback()
			utils.Fail(c, http.StatusPaymentRequired, "音币余额不足")
			return
		}

		// 记录音币交易
		coinTx := model.CoinTransaction{
			UserID:      userID,
			Amount:      -coinsCost,
			Balance:     user.Coins - coinsCost,
			Type:        model.CoinTypeAIConsume,
			Description: "AI生成歌词消耗",
		}
		if err := tx.Create(&coinTx).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "扣费记录失败")
			return
		}
	}

	// 更新AI使用次数
	if err := tx.Model(&user).Updates(map[string]interface{}{
		"daily_ai_count": gorm.Expr("daily_ai_count + 1"),
	}).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "更新配额失败")
		return
	}

	if err := tx.Commit().Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "操作失败")
		return
	}

	// 调用AI服务生成歌词
	lyric, err := aiService.GenerateLyric(req.Prompt, req.Style, req.Emotion, req.Lang)
	if err != nil {
		// AI调用失败，执行退款
		if coinsCost > 0 {
			refundCoins(db.DB, userID, coinsCost, "AI生成歌词失败退款")
		}
		// 回退AI使用次数
		db.DB.Model(&model.User{}).Where("id = ?", userID).Update("daily_ai_count", gorm.Expr("GREATEST(daily_ai_count - 1, 0)"))
		utils.Fail(c, http.StatusInternalServerError, "生成失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{
		"lyric":       lyric,
		"prompt":      req.Prompt,
		"coins_cost":  coinsCost,
		"coins_remain": user.Coins - coinsCost,
	})
}

type OptimizeLyricRequest struct {
	Lyric   string `json:"lyric" binding:"required"` // 原始歌词
	Style   string `json:"style" binding:"required"` // 目标风格
}

// OptimizeLyric 优化歌词
func OptimizeLyric(c *gin.Context) {
	var req OptimizeLyricRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 调用AI服务优化歌词
	optimizedLyric, err := aiService.OptimizeLyric(req.Lyric, req.Style)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "优化失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{
		"original_lyric": req.Lyric,
		"optimized_lyric": optimizedLyric,
	})
}

// GenerateSongRequest 生成歌曲请求，结构体定义在model中
type GenerateSongRequest = model.GenerateSongRequest

// GenerateSong 生成歌曲
// 策略：先检查余额→创建任务→扣费→投递队列→失败时退款
func GenerateSong(c *gin.Context) {
	userID := c.GetUint("user_id")
	var req GenerateSongRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 查询用户信息
	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusUnauthorized, "用户不存在")
		return
	}

	// 检查每日AI配额
	today := utils.GetTodayDate()
	if user.LastGenerateDate != today {
		// 重置每日计数
		user.DailyGenerateCount = 0
		user.LastGenerateDate = today
		user.DailyAICount = 0
	}

	// 根据会员等级检查每日配额
	maxDaily := getMaxDailyAI(int(user.MemberLevel))
	if user.DailyAICount >= maxDaily {
		utils.Fail(c, http.StatusTooManyRequests, "今日AI生成次数已用完")
		return
	}

	// 计算本次消耗音币
	coinsCost := getAICoinsCost(user.MemberLevel)
	if coinsCost > 0 && user.Coins < coinsCost {
		utils.Fail(c, http.StatusPaymentRequired, "音币余额不足")
		return
	}

	// 使用事务保证扣费和任务创建的原子性
	tx := db.DB.Begin()

	// 扣费（SVIP免费）
	if coinsCost > 0 {
		result := tx.Model(&user).Where("coins >= ?", coinsCost).Update("coins", gorm.Expr("coins - ?", coinsCost))
		if result.RowsAffected == 0 {
			tx.Rollback()
			utils.Fail(c, http.StatusPaymentRequired, "音币余额不足")
			return
		}

		// 记录音币交易
		coinTx := model.CoinTransaction{
			UserID:      userID,
			Amount:      -coinsCost,
			Balance:     user.Coins - coinsCost,
			Type:        model.CoinTypeAIConsume,
			Description: "AI生成歌曲消耗",
		}
		if err := tx.Create(&coinTx).Error; err != nil {
			tx.Rollback()
			utils.Fail(c, http.StatusInternalServerError, "扣费记录失败")
			return
		}
	}

	// 创建异步任务
	params, _ := json.Marshal(req)
	task := model.AsyncTask{
		TaskType: model.TaskTypeMusicGenerate,
		UserID:   userID,
		Params:   params,
		Status:   model.TaskStatusWaiting,
		Progress: 0,
	}

	if err := tx.Create(&task).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建任务失败")
		return
	}

	// 增加用户生成次数
	if err := tx.Model(&user).Updates(map[string]interface{}{
		"daily_generate_count": gorm.Expr("daily_generate_count + 1"),
		"daily_ai_count":       gorm.Expr("daily_ai_count + 1"),
	}).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "更新配额失败")
		return
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "任务提交失败")
		return
	}

	// 投递到Redis队列，后台消费
	if err := db.Redis.XAdd(db.Ctx, &redis.XAddArgs{
		Stream: "music_generate_tasks",
		Values: map[string]interface{}{
			"task_id": task.ID,
			"user_id": userID,
			"params":  string(params),
		},
	}).Err(); err != nil {
		// Redis 投递失败，更新任务状态为失败并退款
		db.DB.Model(&task).Updates(map[string]interface{}{
			"status":    model.TaskStatusFailed,
			"error_msg": "任务队列投递失败",
		})
		// 退款
		if coinsCost > 0 {
			refundCoins(db.DB, userID, coinsCost, "AI生成歌曲任务投递失败退款")
		}
		// 回退配额
		db.DB.Model(&user).Updates(map[string]interface{}{
			"daily_generate_count": gorm.Expr("GREATEST(daily_generate_count - 1, 0)"),
			"daily_ai_count":       gorm.Expr("GREATEST(daily_ai_count - 1, 0)"),
		})
		utils.Fail(c, http.StatusInternalServerError, "任务提交失败，请重试")
		return
	}

	utils.Success(c, gin.H{
		"task_id":     task.ID,
		"message":     "任务已提交，正在生成中",
		"coins_cost":  coinsCost,
		"coins_remain": user.Coins - coinsCost,
	})
}

// GetTaskProgress 查询任务进度
func GetTaskProgress(c *gin.Context) {
	userID := c.GetUint("user_id")
	taskIDStr := c.Param("task_id")
	taskID, err := strconv.ParseUint(taskIDStr, 10, 64)
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "任务ID错误")
		return
	}

	var task model.AsyncTask
	if err := db.DB.Where("id = ? AND user_id = ?", taskID, userID).First(&task).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "任务不存在")
		return
	}

	utils.Success(c, gin.H{
		"task_id":    task.ID,
		"status":     task.Status,
		"progress":   task.Progress,
		"result":     task.Result,
		"error_msg":  task.ErrorMsg,
		"created_at": task.CreatedAt,
	})
}

// getAICoinsCost 根据会员等级获取AI消耗音币数
// 普通用户: 5音币, VIP: 2音币, SVIP: 免费
func getAICoinsCost(memberLevel int8) int {
	switch memberLevel {
	case model.MemberLevelVIP:
		return 2
	case model.MemberLevelSVIP:
		return 0
	default:
		return 5
	}
}

// refundCoins 退款函数，用于AI调用失败时退还音币
func refundCoins(tx *gorm.DB, userID uint, amount int, description string) {
	// 退还音币
	if err := tx.Model(&model.User{}).Where("id = ?", userID).Update("coins", gorm.Expr("coins + ?", amount)).Error; err != nil {
		log.Printf("退款失败: userID=%d, amount=%d, error=%v", userID, amount, err)
		return
	}

	// 查询退款后的余额
	var user model.User
	tx.Select("coins").First(&user, userID)

	// 记录退款交易
	coinTx := model.CoinTransaction{
		UserID:      userID,
		Amount:      amount,
		Balance:     user.Coins,
		Type:        model.CoinTypeRefund,
		Description: description,
	}
	if err := tx.Create(&coinTx).Error; err != nil {
		log.Printf("退款记录失败: userID=%d, amount=%d, error=%v", userID, amount, err)
	}
}
