package main

import (
	"log"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/internal/handler"
	"github.com/yourname/aimusic-backend/internal/router"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
	"github.com/yourname/aimusic-backend/pkg/ai"
)

func main() {
	// 1. 初始化配置
	if err := config.InitConfig(); err != nil {
		log.Printf("Init config failed: %v", err)
		return
	}
	log.Println("Config initialized successfully")

	// 2. 初始化MySQL
	if err := db.InitMySQL(); err != nil {
		log.Printf("Init MySQL failed: %v", err)
		return
	}
	log.Println("MySQL initialized successfully")

	// 3. 自动迁移数据库表
	if err := db.DB.AutoMigrate(
		&model.User{},
		&model.Song{},
		&model.AsyncTask{},
		&model.Comment{},
		&model.TogetherRoom{},
		&model.RoomMember{},
		&model.Post{},
		&model.PostComment{},
		&model.PostLike{},
		&model.Admin{},
		&model.AdminLoginLog{},
		&model.AdminOperationLog{},
		&model.SystemConfig{},
		&model.Audit{},
		&model.Playlist{},
		&model.PlaylistSong{},
		&model.PlaylistLike{},
		&model.PlayHistory{},
		&model.VoiceClone{},
		&model.Like{},
		&model.Follow{},
		&model.Notification{},
		&model.MembershipOrder{},
		&model.CoinTransaction{},
		&model.CoinPackage{},
		&model.VIPPlan{},
		&model.Discount{},
		&model.Banner{},
		&model.Topic{},
		&model.Report{},
		&model.UserBan{},
		&model.DailyStats{},
		&model.SystemAlert{},
		&model.Alert{},
		&model.QuotaConfig{},
		&model.MusicDiary{},
		&model.Activity{},
		&handler.ShopProduct{},
		&handler.DailyTaskRecord{},
		&model.AppVersion{},
		&handler.AdPlacement{},
		&handler.UserEvent{},
	); err != nil {
		log.Printf("Migrate tables failed: %v", err)
		return
	}
	log.Println("Database migrated successfully")

	// 3.5 初始化默认数据（VIP套餐和音币充值包）
	handler.InitDefaultData()

	// 4. 初始化Redis
	if err := db.InitRedis(); err != nil {
		log.Printf("Init Redis failed: %v", err)
		return
	}
	log.Println("Redis initialized successfully")

	// 5. 初始化AI服务
	aiService := ai.NewAIService(&config.AppConfig)
	handler.InitAIService(aiService)
	log.Println("AI Service initialized successfully")

	// 6. 初始化路由
	r := router.InitRouter(db.DB)

	// 7. 启动服务
	addr := ":8080"
	log.Printf("Server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Printf("Start server failed: %v", err)
		return
	}
}
