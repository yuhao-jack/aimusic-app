package handler

import (
	cryptoRand "crypto/rand"
	"fmt"
	"log"
	"math/big"
	"math/rand"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/internal/middleware"
	"gorm.io/gorm"
)

type LoginByPhoneRequest struct {
	Phone string `json:"phone" binding:"required,len=11"`
	Code  string `json:"code" binding:"required,len=6"`
}

// LoginByPhone 手机号验证码登录
func LoginByPhone(c *gin.Context) {
	var req LoginByPhoneRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	smsKey := "sms:code:" + req.Phone

	// 验证码为空时，生成并发送验证码
	if req.Code == "" {
		code := fmt.Sprintf("%06d", rand.Intn(1000000))
		db.Redis.Set(db.Ctx, smsKey, code, 5*time.Minute)

		// 尝试发送验证码（短信或邮件）
		smsCfg := config.AppConfig.AI.SMS
		if smsCfg.Provider != "" && smsCfg.AccessKey != "" {
			// 短信服务已配置，调用短信发送
			if err := utils.SendSMS(req.Phone, code); err != nil {
				log.Printf("短信发送失败: %v", err)
			}
		} else {
			// 短信服务未配置，尝试通过邮件发送（需要手机号关联邮箱）
			var user model.User
			if err := db.DB.Where("phone = ?", req.Phone).First(&user).Error; err == nil && user.Email != "" {
				if err := utils.SendVerificationCode(user.Email, code); err != nil {
					log.Printf("发送验证码邮件失败: %v", err)
				}
		} else {
			// 没有关联邮箱，仅记录日志（隐藏手机号后8位和验证码）
			maskedPhone := req.Phone[:3] + "****"
			log.Printf("验证码服务未配置，手机号: %s", maskedPhone)
		}
		}

		// 仅在debug模式下返回验证码，生产环境绝不返回
		if config.AppConfig.Server.Mode == "debug" {
			utils.Success(c, gin.H{"msg": "验证码已发送", "code": code})
		} else {
			utils.Success(c, gin.H{"msg": "验证码已发送"})
		}
		return
	}

	// 从Redis获取验证码并校验
	storedCode, err := db.Redis.Get(db.Ctx, smsKey).Result()
	if err != nil || storedCode != req.Code {
		utils.Fail(c, http.StatusBadRequest, "验证码错误或已过期")
		return
	}
	// 验证通过后删除验证码，防止重复使用
	db.Redis.Del(db.Ctx, smsKey)

	// 查询用户，不存在则自动注册
	var user model.User
	err = db.DB.Where("phone = ?", req.Phone).First(&user).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			// 自动创建新用户
			phone := req.Phone
			user = model.User{
				Phone:    &phone,
				Nickname: "音乐爱好者" + req.Phone[7:],
				Status:   0,
			}
			if err := db.DB.Create(&user).Error; err != nil {
				utils.Fail(c, http.StatusInternalServerError, "创建用户失败")
				return
			}
		} else {
			utils.Fail(c, http.StatusInternalServerError, "查询用户失败")
			return
		}
	}

	if user.Status == 1 {
		utils.Fail(c, http.StatusForbidden, "账号已被禁用")
		return
	}

	// 生成JWT令牌对
	phoneStr := ""
	if user.Phone != nil {
		phoneStr = *user.Phone
	}
	accessToken, refreshToken, err := middleware.GenerateTokenPair(user.ID, phoneStr)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "生成令牌失败")
		return
	}

	// 返回用户信息和双令牌
	utils.Success(c, gin.H{
		"token":         accessToken,
		"refresh_token": refreshToken,
		"user": gin.H{
			"id":           user.ID,
			"nickname":     user.Nickname,
			"avatar":       user.Avatar,
			"phone":        user.Phone,
			"member_level": user.MemberLevel,
		},
	})
}

type LoginByOAuthRequest struct {
	OpenID  string `json:"open_id" binding:"required"`
	Platform string `json:"platform" binding:"required"` // wechat/qq/apple
	Nickname string `json:"nickname"`
	Avatar   string `json:"avatar"`
}

// LoginByOAuth 第三方登录
func LoginByOAuth(c *gin.Context) {
	var req LoginByOAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 查询用户
	var user model.User
	err := db.DB.Where("open_id = ?", req.OpenID).First(&user).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			// 自动注册
			openID := req.OpenID
			user = model.User{
				OpenID:     &openID,
				Nickname:   req.Nickname,
				Avatar:     req.Avatar,
				Status:     0,
				InviteCode: fmt.Sprintf("INVITE_OAUTH_%d", time.Now().UnixNano()),
			}
			if err := db.DB.Create(&user).Error; err != nil {
				utils.Fail(c, http.StatusInternalServerError, "创建用户失败")
				return
			}
		} else {
			utils.Fail(c, http.StatusInternalServerError, "查询用户失败")
			return
		}
	}

	if user.Status == 1 {
		utils.Fail(c, http.StatusForbidden, "账号已被禁用")
		return
	}

	// 生成令牌对
	phoneStr := ""
	if user.Phone != nil {
		phoneStr = *user.Phone
	}
	accessToken, refreshToken, err := middleware.GenerateTokenPair(user.ID, phoneStr)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "生成令牌失败")
		return
	}

	// 查询真实统计数据
	var worksCount int64
	db.DB.Model(&model.Song{}).Where("user_id = ? AND status = 1", user.ID).Count(&worksCount)

	var fansCount int64
	db.DB.Model(&model.Follow{}).Where("following_id = ?", user.ID).Count(&fansCount)

	var followingCount int64
	db.DB.Model(&model.Follow{}).Where("follower_id = ?", user.ID).Count(&followingCount)

	utils.Success(c, gin.H{
		"token":         accessToken,
		"refresh_token": refreshToken,
		"user": gin.H{
			"id":               user.ID,
			"nickname":         user.Nickname,
			"avatar":           user.Avatar,
			"bio":              user.Bio,
			"member_level":      user.MemberLevel,
			"member_expire_at":  user.MemberExpireAt,
			"created_at":        user.CreatedAt,
			"works_count":       worksCount,
			"fans_count":        fansCount,
			"following_count":   followingCount,
		},
	})
}

// GetUserInfo 获取当前用户信息
func GetUserInfo(c *gin.Context) {
	userID := c.GetUint("user_id")
	
	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 查询真实统计数据
	var worksCount int64
	db.DB.Model(&model.Song{}).Where("user_id = ? AND status = 1", userID).Count(&worksCount)

	var fansCount int64
	db.DB.Model(&model.Follow{}).Where("following_id = ?", userID).Count(&fansCount)

	var followingCount int64
	db.DB.Model(&model.Follow{}).Where("follower_id = ?", userID).Count(&followingCount)

	utils.Success(c, gin.H{
		"id":               user.ID,
		"nickname":         user.Nickname,
		"avatar":           user.Avatar,
		"bio":              user.Bio,
		"phone":            user.Phone,
		"member_level":      user.MemberLevel,
		"member_expire_at":  user.MemberExpireAt,
		"created_at":        user.CreatedAt,
		"works_count":       worksCount,
		"fans_count":        fansCount,
		"following_count":   followingCount,
	})
}

// UpdateUserInfo 更新用户信息（保留兼容）
func UpdateUserInfo(c *gin.Context) {
	userID := c.GetUint("user_id")
	
	var req struct {
		Nickname string `json:"nickname"`
		Avatar   string `json:"avatar"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	updateData := make(map[string]interface{})
	if req.Nickname != "" {
		updateData["nickname"] = req.Nickname
	}
	if req.Avatar != "" {
		updateData["avatar"] = req.Avatar
	}

	if len(updateData) == 0 {
		utils.Fail(c, http.StatusBadRequest, "没有需要更新的字段")
		return
	}

	if err := db.DB.Model(&model.User{}).Where("id = ?", userID).Updates(updateData).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "更新失败")
		return
	}

	utils.Success(c, nil)
}

// UpdateUserProfile 更新用户资料（昵称和简介）
func UpdateUserProfile(c *gin.Context) {
	userID := c.GetUint("user_id")
	
	var req struct {
		Nickname string `json:"nickname"`
		Bio      string `json:"bio"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	if req.Nickname == "" {
		utils.Fail(c, http.StatusBadRequest, "昵称不能为空")
		return
	}

	updateData := make(map[string]interface{})
	updateData["nickname"] = req.Nickname
	updateData["bio"] = req.Bio

	if err := db.DB.Model(&model.User{}).Where("id = ?", userID).Updates(updateData).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "更新失败")
		return
	}

	utils.Success(c, nil)
}

// UploadAvatar 上传头像
func UploadAvatar(c *gin.Context) {
	userID := c.GetUint("user_id")

	// 获取上传的文件
	file, err := c.FormFile("avatar")
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "请选择头像文件")
		return
	}

	// 检查文件大小 (限制 5MB)
	const maxFileSize = 5 * 1024 * 1024
	if file.Size > maxFileSize {
		utils.Fail(c, http.StatusBadRequest, "文件大小不能超过5MB")
		return
	}

	// 检查文件类型
	ext := filepath.Ext(file.Filename)
	ext = strings.ToLower(ext)
	allowedExts := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
	}
	if !allowedExts[ext] {
		utils.Fail(c, http.StatusBadRequest, "只支持 JPG、PNG、GIF、WebP 格式")
		return
	}

	// 生成新的文件名
	newFileName := "avatar_" + strconv.FormatUint(uint64(userID), 10) + "_" + time.Now().Format("20060102150405") + ext

	// 按日期分目录存储
	now := time.Now()
	datePath := now.Format("2006/01/02")
	uploadDir := filepath.Join(config.AppConfig.Upload.Path, "avatars", datePath)

	// 创建目录
	if err := utils.EnsureDir(uploadDir); err != nil {
		utils.Fail(c, http.StatusInternalServerError, "创建目录失败")
		return
	}

	// 保存文件
	dstPath := filepath.Join(uploadDir, newFileName)
	if err := c.SaveUploadedFile(file, dstPath); err != nil {
		utils.Fail(c, http.StatusInternalServerError, "保存文件失败")
		return
	}

	// 返回文件访问 URL
	avatarURL := config.AppConfig.Upload.BaseURL + "/avatars/" + datePath + "/" + newFileName

	// 更新用户头像
	if err := db.DB.Model(&model.User{}).Where("id = ?", userID).Update("avatar", avatarURL).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "更新头像失败")
		return
	}

	utils.Success(c, gin.H{
		"avatar_url": avatarURL,
	})
}

type LoginByPasswordRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginByPassword 用户名密码登录
func LoginByPassword(c *gin.Context) {
	var req LoginByPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 查询用户
	var user model.User
	err := db.DB.Where("username = ?", req.Username).Or("email = ?", req.Username).First(&user).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.Fail(c, http.StatusUnauthorized, "用户名或密码错误")
			return
		} else {
			utils.Fail(c, http.StatusInternalServerError, "查询用户失败")
			return
		}
	}

	if user.Status == 1 {
		utils.Fail(c, http.StatusForbidden, "账号已被禁用")
		return
	}

	// 验证密码
	if !utils.CheckPassword(req.Password, user.Password) {
		utils.Fail(c, http.StatusUnauthorized, "用户名或密码错误")
		return
	}

	// 生成JWT令牌对
	phoneStr := ""
	if user.Phone != nil {
		phoneStr = *user.Phone
	}
	accessToken, refreshToken, err := middleware.GenerateTokenPair(user.ID, phoneStr)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "生成令牌失败")
		return
	}

	// 查询真实统计数据（与GetUserInfo保持一致）
	var worksCount int64
	db.DB.Model(&model.Song{}).Where("user_id = ? AND status = 1", user.ID).Count(&worksCount)

	var fansCount int64
	db.DB.Model(&model.Follow{}).Where("following_id = ?", user.ID).Count(&fansCount)

	var followingCount int64
	db.DB.Model(&model.Follow{}).Where("follower_id = ?", user.ID).Count(&followingCount)

	// 返回用户信息和双令牌（和 GetUserInfo 保持一致）

	utils.Success(c, gin.H{
		"token":         accessToken,
		"refresh_token": refreshToken,
		"user": gin.H{
			"id":               user.ID,
			"username":         user.Username,
			"nickname":         user.Nickname,
			"avatar":           user.Avatar,
			"bio":              user.Bio,
			"email":            user.Email,
			"member_level":      user.MemberLevel,
			"member_expire_at":  user.MemberExpireAt,
			"created_at":        user.CreatedAt,
			"works_count":       worksCount,
			"fans_count":        fansCount,
			"following_count":   followingCount,
		},
	})
}

type RegisterByPasswordRequest struct {
	Username   string `json:"username" binding:"required"`
	Email      string `json:"email" binding:"required,email"`
	Password   string `json:"password" binding:"required,min=6"`
	InviteCode string `json:"invite_code"` // 邀请码（可选）
}

// RegisterByPassword 用户名密码注册
func RegisterByPassword(c *gin.Context) {
	var req RegisterByPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 检查用户名是否已存在
	var count int64
	db.DB.Model(&model.User{}).Where("username = ?", req.Username).Count(&count)
	if count > 0 {
		utils.Fail(c, http.StatusBadRequest, "用户名已存在")
		return
	}

	// 检查邮箱是否已存在
	db.DB.Model(&model.User{}).Where("email = ?", req.Email).Count(&count)
	if count > 0 {
		utils.Fail(c, http.StatusBadRequest, "邮箱已被注册")
		return
	}

	// 加密密码
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "密码加密失败")
		return
	}

	// 生成用户自己的邀请码（8位随机字符串）
	myInviteCode := generateInviteCode()

	// 创建用户
	user := model.User{
		Username:   req.Username,
		Email:      req.Email,
		Password:   hashedPassword,
		Nickname:   req.Username,
		Status:     0,
		InviteCode: myInviteCode,
	}

	// 使用事务保证用户创建和邀请记录的原子性
	tx := db.DB.Begin()
	if err := tx.Create(&user).Error; err != nil {
		tx.Rollback()
		utils.Fail(c, http.StatusInternalServerError, "创建用户失败")
		return
	}

	// 处理邀请码逻辑
	if req.InviteCode != "" {
		// 查找邀请记录
		var inviteRecord model.InviteRecord
		if err := tx.Where("invite_code = ? AND status = 0", req.InviteCode).First(&inviteRecord).Error; err == nil {
			// 更新邀请记录状态
			inviteRecord.InviteeID = user.ID
			inviteRecord.Status = 1 // 已注册
			tx.Save(&inviteRecord)

			// 奖励邀请者音币
			tx.Model(&model.User{}).Where("id = ?", inviteRecord.InviterID).Update("coins", gorm.Expr("coins + ?", inviteRecord.Reward))

			// 更新邀请记录状态为已奖励
			inviteRecord.Status = 2
			tx.Save(&inviteRecord)
		}
	}

	tx.Commit()

	utils.Success(c, gin.H{
		"user_id":     user.ID,
		"invite_code": myInviteCode,
	})
}

type SendResetCodeRequest struct {
	Email string `json:"email" binding:"required,email"`
}

// SendResetCode 发送密码重置验证码
func SendResetCode(c *gin.Context) {
	var req SendResetCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 检查邮箱是否存在
	var user model.User
	err := db.DB.Where("email = ?", req.Email).First(&user).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			utils.Fail(c, http.StatusBadRequest, "该邮箱未注册")
			return
		} else {
			utils.Fail(c, http.StatusInternalServerError, "查询失败")
			return
		}
	}

	// 生成6位随机验证码，存入Redis，过期时间10分钟
	resetCode := fmt.Sprintf("%06d", rand.Intn(1000000))
	resetKey := "reset:code:" + req.Email
	db.Redis.Set(db.Ctx, resetKey, resetCode, 10*time.Minute)

	// 发送验证码邮件，发送失败不阻塞主流程（验证码已存入Redis）
	if err := utils.SendVerificationCode(req.Email, resetCode); err != nil {
		log.Printf("发送验证码邮件失败: %v", err)
		// 仅在debug模式下返回验证码，生产环境返回错误
		if config.AppConfig.Server.Mode == "debug" {
			utils.Success(c, gin.H{
				"msg":  "验证码已发送",
				"code": resetCode,
			})
		} else {
			utils.Fail(c, http.StatusInternalServerError, "验证码发送失败，请稍后重试")
		}
		return
	}

	utils.Success(c, gin.H{
		"msg": "验证码已发送到您的邮箱",
	})
}

type ResetPasswordRequest struct {
	Email       string `json:"email" binding:"required,email"`
	Code        string `json:"code" binding:"required,len=6"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}

// ResetPassword 重置密码
func ResetPassword(c *gin.Context) {
	var req ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 从Redis获取验证码并校验
	resetKey := "reset:code:" + req.Email
	storedCode, err := db.Redis.Get(db.Ctx, resetKey).Result()
	if err != nil || storedCode != req.Code {
		utils.Fail(c, http.StatusBadRequest, "验证码错误或已过期")
		return
	}
	// 验证通过后删除验证码，防止重复使用
	db.Redis.Del(db.Ctx, resetKey)

	// 查询用户
	var user model.User
	err = db.DB.Where("email = ?", req.Email).First(&user).Error
	if err != nil {
		utils.Fail(c, http.StatusBadRequest, "该邮箱未注册")
		return
	}

	// 加密新密码
	hashedPassword, err := utils.HashPassword(req.NewPassword)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "密码加密失败")
		return
	}

	// 更新密码
	user.Password = hashedPassword
	if err := db.DB.Save(&user).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "更新密码失败")
		return
	}

	utils.Success(c, nil)
}

// SendSmsCodeRequest 发送短信验证码请求
type SendSmsCodeRequest struct {
	Phone string `json:"phone" binding:"required,len=11"`
}

// SendSmsCode 发送短信验证码
func SendSmsCode(c *gin.Context) {
	var req SendSmsCodeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "手机号格式错误")
		return
	}

	// 检查发送频率限制（同一手机号60秒内只能发送一次）
	rateLimitKey := "sms:rate:" + req.Phone
	exists, _ := db.Redis.Exists(db.Ctx, rateLimitKey).Result()
	if exists > 0 {
		utils.Fail(c, http.StatusTooManyRequests, "验证码发送过于频繁，请稍后再试")
		return
	}

	// 生成6位随机验证码
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	// 存入Redis，过期时间5分钟
	smsKey := "sms:code:" + req.Phone
	db.Redis.Set(db.Ctx, smsKey, code, 5*time.Minute)

	// 设置发送频率限制，60秒
	db.Redis.Set(db.Ctx, rateLimitKey, "1", 60*time.Second)

	// 调用短信服务发送验证码
	smsErr := utils.SendSMS(req.Phone, code)
	if smsErr != nil {
		log.Printf("发送短信失败: %v", smsErr)
	}

	// 仅在debug模式下返回验证码，生产环境移除
	if config.AppConfig.Server.Mode == "debug" {
		resp := gin.H{"msg": "验证码已发送"}
		// 短信发送失败时也在开发环境返回验证码，方便测试
		if smsErr != nil {
			resp["code"] = code
			resp["sms_error"] = smsErr.Error()
		} else {
			resp["code"] = code
		}
		utils.Success(c, resp)
	} else {
		if smsErr != nil {
			utils.Fail(c, http.StatusInternalServerError, "短信发送失败，请稍后重试")
			return
		}
		utils.Success(c, gin.H{"msg": "验证码已发送到您的手机"})
	}
}

// GetUserWorks 获取用户作品
func GetUserWorks(c *gin.Context) {
	userID := c.GetUint("user_id")
	
	var songs []model.Song
	if err := db.DB.Where("user_id = ? AND status = 1", userID).
		Order("created_at DESC").
		Find(&songs).Error; err != nil {
		utils.Success(c, []model.Song{})
		return
	}

	utils.Success(c, songs)
}

// GetUserLikes 获取用户喜欢的歌曲
func GetUserLikes(c *gin.Context) {
	userID := c.GetUint("user_id")

	var songIDs []uint
	db.DB.Model(&model.Like{}).
		Where("user_id = ? AND like_type = ?", userID, "song").
		Pluck("target_id", &songIDs)

	if len(songIDs) == 0 {
		utils.Success(c, []model.Song{})
		return
	}

	var songs []model.Song
	if err := db.DB.Where("id IN ?", songIDs).
		Order("created_at DESC").
		Find(&songs).Error; err != nil {
		utils.Success(c, []model.Song{})
		return
	}

	utils.Success(c, songs)
}

// RefreshTokenRequest 刷新令牌请求
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// RefreshToken 使用 refresh_token 获取新的令牌对
func RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.Fail(c, http.StatusBadRequest, "参数错误")
		return
	}

	// 解析并验证 refresh_token
	claims, err := middleware.ParseRefreshToken(req.RefreshToken)
	if err != nil {
		utils.Fail(c, http.StatusUnauthorized, "refresh_token 无效或已过期")
		return
	}

	// 查询用户信息
	var user model.User
	if err := db.DB.First(&user, claims.UserID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	if user.Status == 1 {
		utils.Fail(c, http.StatusForbidden, "账号已被禁用")
		return
	}

	// 生成新的令牌对
	phoneStr := ""
	if user.Phone != nil {
		phoneStr = *user.Phone
	}
	accessToken, refreshToken, err := middleware.GenerateTokenPair(user.ID, phoneStr)
	if err != nil {
		utils.Fail(c, http.StatusInternalServerError, "生成令牌失败")
		return
	}

	// 返回新的双令牌
	utils.Success(c, gin.H{
		"token":         accessToken,
		"refresh_token": refreshToken,
	})
}

// generateInviteCode 生成8位随机邀请码（大写字母+数字）
func generateInviteCode() string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code := make([]byte, 8)
	for i := range code {
		n, _ := cryptoRand.Int(cryptoRand.Reader, big.NewInt(int64(len(chars))))
		code[i] = chars[n.Int64()]
	}
	return string(code)
}

// GetInviteCode 获取我的邀请码
func GetInviteCode(c *gin.Context) {
	userID := c.GetUint("user_id")

	var user model.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		utils.Fail(c, http.StatusNotFound, "用户不存在")
		return
	}

	// 如果用户没有邀请码，生成一个
	if user.InviteCode == "" {
		inviteCode := generateInviteCode()
		if err := db.DB.Model(&user).Update("invite_code", inviteCode).Error; err != nil {
			utils.Fail(c, http.StatusInternalServerError, "生成邀请码失败")
			return
		}
		user.InviteCode = inviteCode
	}

	// 统计邀请人数
	var inviteCount int64
	db.DB.Model(&model.InviteRecord{}).Where("inviter_id = ? AND status >= 1", userID).Count(&inviteCount)

	utils.Success(c, gin.H{
		"invite_code":  user.InviteCode,
		"invite_count": inviteCount,
	})
}

// GetInviteRecords 获取邀请记录
func GetInviteRecords(c *gin.Context) {
	userID := c.GetUint("user_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	// 查询邀请记录
	var records []model.InviteRecord
	var total int64

	db.DB.Model(&model.InviteRecord{}).Where("inviter_id = ?", userID).Count(&total)
	db.DB.Where("inviter_id = ?", userID).Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&records)

	// 获取被邀请者信息
	type InviteeInfo struct {
		model.InviteRecord
		InviteeNickname string `json:"invitee_nickname"`
		InviteeAvatar   string `json:"invitee_avatar"`
	}

	var result []InviteeInfo
	for _, record := range records {
		info := InviteeInfo{
			InviteRecord: record,
		}
		if record.InviteeID > 0 {
			var invitee model.User
			if db.DB.First(&invitee, record.InviteeID).Error == nil {
				info.InviteeNickname = invitee.Nickname
				info.InviteeAvatar = invitee.Avatar
			}
		}
		result = append(result, info)
	}

	utils.Success(c, gin.H{
		"list":  result,
		"total": total,
	})
}

// CreateInviteCode 生成新的邀请码
func CreateInviteCode(c *gin.Context) {
	userID := c.GetUint("user_id")

	inviteCode := generateInviteCode()
	record := model.InviteRecord{
		InviterID:  userID,
		InviteCode: inviteCode,
		Reward:     100,
		Status:     0,
	}

	if err := db.DB.Create(&record).Error; err != nil {
		utils.Fail(c, http.StatusInternalServerError, "创建邀请码失败")
		return
	}

	utils.Success(c, gin.H{
		"invite_code": inviteCode,
	})
}
