package config

import (
	"strings"

	"github.com/spf13/viper"
)

type Config struct {
	Server ServerConfig `mapstructure:"server"`
	MySQL  MySQLConfig  `mapstructure:"mysql"`
	Redis  RedisConfig  `mapstructure:"redis"`
	JWT    JWTConfig    `mapstructure:"jwt"`
	OSS    OSSConfig    `mapstructure:"oss"`
	Upload UploadConfig `mapstructure:"upload"`
	AI     AIConfig     `mapstructure:"ai"`
	CORS   CORSConfig   `mapstructure:"cors"`
}

// CORSConfig 跨域配置
type CORSConfig struct {
	AllowedOrigins []string `mapstructure:"allowed_origins"` // 允许的来源列表
}

type ServerConfig struct {
	Port       int    `mapstructure:"port"`
	Mode       string `mapstructure:"mode"`
	APIVersion string `mapstructure:"api_version"` // API版本前缀，如 /api/v1
}

type MySQLConfig struct {
	Host         string `mapstructure:"host"`
	Port         int    `mapstructure:"port"`
	Username     string `mapstructure:"username"`
	Password     string `mapstructure:"password"`
	Database     string `mapstructure:"database"`
	Charset      string `mapstructure:"charset"`
	MaxOpenConns int    `mapstructure:"max_open_conns"`
	MaxIdleConns int    `mapstructure:"max_idle_conns"`
}

type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
	PoolSize int    `mapstructure:"pool_size"`
}

type JWTConfig struct {
	Secret             string `mapstructure:"secret"`
	ExpireHours        int    `mapstructure:"expire_hours"`
	RefreshExpireHours int    `mapstructure:"refresh_expire_hours"`
}

type OSSConfig struct {
	Endpoint  string `mapstructure:"endpoint"`
	AccessKey string `mapstructure:"access_key"`
	SecretKey string `mapstructure:"secret_key"`
	Bucket    string `mapstructure:"bucket"`
	Domain    string `mapstructure:"domain"`
}

type AIConfig struct {
	// 歌词生成 - 豆包API
	DoubaoAPIKey    string `mapstructure:"doubao_api_key"`
	DoubaoBaseURL   string `mapstructure:"doubao_base_url"`
	DoubaoModel     string `mapstructure:"doubao_model"`
	
	// 歌词生成 - OpenAI/ChatGPT (备用)
	OpenAIAPIKey    string `mapstructure:"openai_api_key"`
	OpenAIBaseURL   string `mapstructure:"openai_base_url"`
	OpenAIModel     string `mapstructure:"openai_model"`
	
	// 歌词生成 - DeepSeek (新增)
	DeepSeekAPIKey  string `mapstructure:"deepseek_api_key"`
	DeepSeekBaseURL string `mapstructure:"deepseek_base_url"`
	DeepSeekModel   string `mapstructure:"deepseek_model"`
	
	// 歌曲生成 - Suno API
	SunoAPIKey      string `mapstructure:"suno_api_key"`
	SunoBaseURL     string `mapstructure:"suno_base_url"`
	
	// 歌曲生成 - 自研/其他音乐AI (备用)
	MusicAPIKey     string `mapstructure:"music_api_key"`
	MusicBaseURL    string `mapstructure:"music_base_url"`
	
	// 短信验证码
	SMS             SMSConfig  `mapstructure:"sms"`
	
	// 邮件验证码
	Email           EmailConfig `mapstructure:"email"`
}

type SMSConfig struct {
	Provider     string `mapstructure:"provider"`
	AccessKey    string `mapstructure:"access_key"`
	SecretKey    string `mapstructure:"secret_key"`
	SignName     string `mapstructure:"sign_name"`
	TemplateCode string `mapstructure:"template_code"`
}

type EmailConfig struct {
	SMTPHost     string `mapstructure:"smtp_host"`
	SMTPPort     int    `mapstructure:"smtp_port"`
	SMTPUser     string `mapstructure:"smtp_user"`
	SMTPPassword string `mapstructure:"smtp_password"`
	FromName     string `mapstructure:"from_name"`
}

type UploadConfig struct {
	Path    string `mapstructure:"path"`
	BaseURL string `mapstructure:"base_url"`
}

var AppConfig Config

func InitConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath("../configs")

	if err := viper.ReadInConfig(); err != nil {
		return err
	}

	// 启用环境变量覆盖：允许通过环境变量注入敏感配置（如 MYSQL_PASSWORD、JWT_SECRET 等）
	// 环境变量名格式：将配置key中的"."替换为"_"并大写，如 mysql.password → MYSQL_PASSWORD
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	viper.AutomaticEnv()

	if err := viper.Unmarshal(&AppConfig); err != nil {
		return err
	}

	return nil
}
