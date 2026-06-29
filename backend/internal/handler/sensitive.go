package handler

import (
	"encoding/json"
	"log"
	"strings"
	"sync"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// defaultSensitiveWords 硬编码的默认敏感词列表（政治/色情/暴力/广告等）
// 作为数据库配置缺失时的兜底默认值
var defaultSensitiveWords = []string{
	// 政治敏感
	"习近平", "毛泽东", "六四", "天安门", "法轮功", "台独", "藏独", "疆独",
	"共产党", "反华", "颠覆", "分裂国家",
	// 色情
	"色情", "裸体", "性交", "嫖娼", "卖淫", "淫秽", "黄色网站",
	// 暴力
	"杀人", "爆炸", "恐怖袭击", "枪击", "绑架", "贩卖人口",
	// 广告/诈骗
	"加微信", "加QQ", "免费领", "日赚万元", "兼职赚钱", "刷单",
	"代开发票", "办证", "贷款套现", "赌博平台", "网赌",
	// 毒品
	"冰毒", "大麻", "海洛因", "摇头丸", "吸毒",
}

// sensitiveWords 当前生效的敏感词列表（从数据库加载或使用默认值）
var sensitiveWords = defaultSensitiveWords

// sensitiveWordsOnce 确保只从数据库加载一次
var sensitiveWordsOnce sync.Once

// loadSensitiveWords 从 system_configs 表加载敏感词列表
// key: sensitive_words，value: JSON数组字符串
// 加载失败时保留硬编码默认值
func loadSensitiveWords() {
	sensitiveWordsOnce.Do(func() {
		var cfg model.SystemConfig
		if err := db.DB.Where("`key` = ?", "sensitive_words").First(&cfg).Error; err != nil {
			// 数据库中无配置，使用默认值
			return
		}
		if cfg.Value == "" {
			return
		}
		var words []string
		if err := json.Unmarshal([]byte(cfg.Value), &words); err != nil {
			// JSON解析失败，使用默认值
			log.Printf("解析敏感词配置失败，使用默认值: %v", err)
			return
		}
		if len(words) > 0 {
			sensitiveWords = words
		}
	})
}

// ReloadSensitiveWords 强制重新从数据库加载敏感词（供后台管理调用）
func ReloadSensitiveWords() {
	sensitiveWordsOnce = sync.Once{}
	loadSensitiveWords()
}

// CheckSensitiveWords 检测文本中是否包含敏感词
// 返回匹配到的敏感词列表，如果没有匹配返回空切片
func CheckSensitiveWords(text string) []string {
	loadSensitiveWords()
	var matched []string
	lowerText := strings.ToLower(text)
	for _, word := range sensitiveWords {
		if strings.Contains(lowerText, strings.ToLower(word)) {
			matched = append(matched, word)
		}
	}
	return matched
}

// CreateAuditIfNeeded 如果检测到敏感词，自动创建审核记录
// contentType: "post" 或 "comment"
// contentID: 内容的ID
// userID: 发布者ID
// content: 内容文本
// 返回值: true 表示命中敏感词（需审核）
func CreateAuditIfNeeded(contentType string, contentID uint, userID uint, content string) bool {
	matched := CheckSensitiveWords(content)
	if len(matched) == 0 {
		return false
	}

	audit := model.Audit{
		ContentType: contentType,
		ContentID:   contentID,
		UserID:      userID,
		Content:     content,
		Status:      0, // 待审核
	}
	if err := db.DB.Create(&audit).Error; err != nil {
		log.Printf("创建审核记录失败: content_type=%s, content_id=%d, user_id=%d, err=%v", contentType, contentID, userID, err)
		return false
	}
	return true
}
