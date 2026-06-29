package db

import (
	"context"
	"fmt"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/go-redis/redis/v8"
)

var Redis *redis.Client
var Ctx = context.Background()

func InitRedis() error {
	addr := fmt.Sprintf("%s:%d", config.AppConfig.Redis.Host, config.AppConfig.Redis.Port)
	Redis = redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: config.AppConfig.Redis.Password,
		DB:       config.AppConfig.Redis.DB,
		PoolSize: config.AppConfig.Redis.PoolSize,
	})

	_, err := Redis.Ping(Ctx).Result()
	if err != nil {
		return err
	}

	return nil
}
