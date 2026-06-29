package middleware

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
)

// RequireVIP 会员权限检查中间件
// level: 需要的最低会员等级 (1=VIP, 2=SVIP)
func RequireVIP(level int) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从context获取user_id
		userID, exists := c.Get("user_id")
		if !exists {
			utils.Fail(c, http.StatusUnauthorized, "未登录")
			c.Abort()
			return
		}

		// 查询用户会员等级
		var user model.User
		if err := db.DB.First(&user, userID).Error; err != nil {
			utils.Fail(c, http.StatusNotFound, "用户不存在")
			c.Abort()
			return
		}

		// 检查会员是否过期
		if user.MemberExpireAt != nil && user.MemberExpireAt.Before(time.Now()) {
			// 会员已过期，降级为普通用户
			db.DB.Model(&user).Updates(map[string]interface{}{
				"member_level":     model.MemberLevelFree,
				"member_expire_at": nil,
			})
			user.MemberLevel = model.MemberLevelFree
		}

		// 如果等级不够，返回403
		if int(user.MemberLevel) < level {
			levelName := "VIP"
			if level >= model.MemberLevelSVIP {
				levelName = "SVIP"
			}
			utils.Fail(c, http.StatusForbidden, "需要"+levelName+"会员权限")
			c.Abort()
			return
		}

		// 将会员等级存入上下文，供后续使用
		c.Set("member_level", int(user.MemberLevel))
		c.Next()
	}
}

// CheckAICoinLimit AI音币消耗检查中间件
// 检查用户是否有足够的音币或会员权限进行AI操作
func CheckAICoinLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetUint("user_id")

		var user model.User
		if err := db.DB.First(&user, userID).Error; err != nil {
			utils.Fail(c, http.StatusNotFound, "用户不存在")
			c.Abort()
			return
		}

		// 检查会员是否过期
		if user.MemberExpireAt != nil && user.MemberExpireAt.Before(time.Now()) {
			db.DB.Model(&user).Updates(map[string]interface{}{
				"member_level":     model.MemberLevelFree,
				"member_expire_at": nil,
			})
			user.MemberLevel = model.MemberLevelFree
		}

		// SVIP免费，不限制
		if user.MemberLevel == model.MemberLevelSVIP {
			c.Next()
			return
		}

		// 检查每日次数限制
		today := time.Now().Format("2006-01-02")
		if user.LastGenerateDate != today {
			// 重置今日次数
			db.DB.Model(&user).Updates(map[string]interface{}{
				"daily_ai_count":       0,
				"daily_generate_count": 0,
				"last_generate_date":   today,
			})
			user.DailyAICount = 0
		}

		maxDailyAI := 3 // 普通用户
		if user.MemberLevel == model.MemberLevelVIP {
			maxDailyAI = 10
		}

		if user.DailyAICount >= maxDailyAI {
			utils.Fail(c, http.StatusForbidden, "今日AI使用次数已用完，请升级会员或明天再试")
			c.Abort()
			return
		}

		// 普通用户需要检查音币
		if user.MemberLevel == model.MemberLevelFree {
			// VIP减半消耗5音币，普通用户5音币
			coinsCost := 5
			if user.Coins < coinsCost {
				utils.Fail(c, http.StatusForbidden, "音币不足，请充值或升级会员")
				c.Abort()
				return
			}
			c.Set("ai_coins_cost", coinsCost)
		} else if user.MemberLevel == model.MemberLevelVIP {
			// VIP减半消耗
			c.Set("ai_coins_cost", 2)
		} else {
			// SVIP免费
			c.Set("ai_coins_cost", 0)
		}

		c.Next()
	}
}
