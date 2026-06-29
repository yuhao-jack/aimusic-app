package handler

import (
	"fmt"
	"time"

	"github.com/yourname/aimusic-backend/internal/middleware"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/utils"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// SetupTestDB 初始化一个内存SQLite数据库用于测试
func SetupTestDB() error {
	// 使用内存SQLite — 每个连接独立，确保测试间数据隔离
	sqlDB, err := gorm.Open(sqlite.Open("file::memory:"), &gorm.Config{})
	if err != nil {
		return err
	}

	db.DB = sqlDB

	// 确保配置被初始化
	if config.AppConfig.JWT.Secret == "" {
		config.AppConfig.JWT.Secret = "aimusic2024secretkey"
	}
	if config.AppConfig.JWT.ExpireHours == 0 {
		config.AppConfig.JWT.ExpireHours = 24
	}

	// 自动迁移所有表
	err = db.DB.AutoMigrate(
		&model.User{},
		&model.Song{},
		&model.AsyncTask{},
		&model.Post{},
		&model.Comment{},
		&model.PostComment{},
		&model.PostLike{},
		&model.TogetherRoom{},
		&model.Like{},
		&model.Follow{},
		&model.Notification{},
		&model.Playlist{},
		&model.PlaylistSong{},
		&model.PlaylistLike{},
		&model.PlayHistory{},
		&model.VoiceClone{},
		&model.Admin{},
		&model.AdminLoginLog{},
		&model.AdminOperationLog{},
		&model.SystemConfig{},
		&model.Audit{},
		&model.CoinTransaction{},
		&model.SystemAlert{},
	)
	if err != nil {
		return err
	}

	fmt.Println("Test database initialized successfully")
	return nil
}

// SetupAuthTest 创建测试用户并返回JWT token
func SetupAuthTest() (uint, string, error) {
	hashedPwd, err := utils.HashPassword("123456")
	if err != nil {
		return 0, "", err
	}

	user := model.User{
		Username: "testuser",
		Nickname: "TestUser",
		Email:    "test@example.com",
		Password: hashedPwd,
		Status:   0,
	}
	if err := db.DB.Create(&user).Error; err != nil {
		return 0, "", err
	}

	phoneStr := ""
	if user.Phone != nil {
		phoneStr = *user.Phone
	}
	token, err := middleware.GenerateToken(user.ID, phoneStr)
	if err != nil {
		return 0, "", err
	}

	return user.ID, token, nil
}

// SetupSecondUser 创建第二个测试用户，用于权限测试
func SetupSecondUser() (uint, string, error) {
	hashedPwd, err := utils.HashPassword("123456")
	if err != nil {
		return 0, "", err
	}

	user := model.User{
		Username:   "otheruser",
		Nickname:   "OtherUser",
		Email:      "other@example.com",
		Password:   hashedPwd,
		Status:     0,
		InviteCode: "INVITE_OTHER_" + fmt.Sprintf("%d", time.Now().UnixNano()),
	}
	if err := db.DB.Create(&user).Error; err != nil {
		return 0, "", err
	}

	phoneStr := ""
	if user.Phone != nil {
		phoneStr = *user.Phone
	}
	token, err := middleware.GenerateToken(user.ID, phoneStr)
	if err != nil {
		return 0, "", err
	}

	return user.ID, token, nil
}

// CreateTestSong 创建一首测试歌曲
func CreateTestSong(userID uint) model.Song {
	song := model.Song{
		UserID:      userID,
		Title:       "Test Song",
		Singer:      "Test Singer",
		Lyric:       "Test lyric content",
		Style:       "pop",
		Emotion:     "happy",
		Duration:    180,
		PlayCount:   100,
		LikeCount:   10,
		Status:      1,
		IsPublic:    1,
		CopyrightID: fmt.Sprintf("test_copyright_%d", time.Now().UnixNano()),
	}
	db.DB.Create(&song)
	return song
}

// CleanupTestDB 清理测试数据库
func CleanupTestDB() {
	db.DB.Exec("PRAGMA foreign_keys = OFF")
	// 清理所有表
	tables := []string{
		"users", "songs", "async_tasks", "posts", "comments",
		"post_comments", "post_likes", "together_rooms",
		"likes", "follows", "playlists", "playlist_songs",
		"playlist_likes", "play_histories", "voice_clones",
		"notifications",
		"admins",
		"admin_login_logs",
		"admin_operation_logs",
		"system_configs",
		"audits",
	}
	for _, table := range tables {
		db.DB.Exec("DELETE FROM " + table)
	}
	db.DB.Exec("PRAGMA foreign_keys = ON")
}

// SetupTestWithTime 设置时间的辅助函数
func SetupTestWithTime() {
	// 对于PlayHistory中的播放时间，如果没有设置now，使用当前时间戳
	// 这是一个no-op helper，让测试代码更清晰
}

// getNowTimestamp 获取当前时间戳（用于PlayHistory）
func getNowTimestamp() int64 {
	return time.Now().UnixMilli()
}
