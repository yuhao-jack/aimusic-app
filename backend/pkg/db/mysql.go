package db

import (
	"fmt"
	"github.com/yourname/aimusic-backend/pkg/config"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitMySQL() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=%s&parseTime=True&loc=Local",
		config.AppConfig.MySQL.Username,
		config.AppConfig.MySQL.Password,
		config.AppConfig.MySQL.Host,
		config.AppConfig.MySQL.Port,
		config.AppConfig.MySQL.Database,
		config.AppConfig.MySQL.Charset,
	)

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return err
	}

	sqlDB.SetMaxOpenConns(config.AppConfig.MySQL.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.AppConfig.MySQL.MaxIdleConns)

	DB = db
	return nil
}
