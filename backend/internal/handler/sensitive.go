package handler

import (
	"encoding/json"
	"log"
	"strings"
	"sync"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// defaultSensitiveWords 硬编码的默认敏感词列表
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

// sensitiveWords 当前生效的敏感词列表
var sensitiveWords = defaultSensitiveWords

// sensitiveWordsMu 保护 sensitiveWords 的并发读写
var sensitiveWordsMu sync.RWMutex

// sensitiveWordsLoaded 标记是否已从数据库加载
var sensitiveWordsLoaded bool

// loadSensitiveWords 从 system_configs 表加载敏感词列表
func loadSensitiveWords() {
	sensitiveWordsMu.Lock()
	defer sensitiveWordsMu.Unlock()

	if sensitiveWordsLoaded {
		return
	}

	var cfg model.SystemConfig
	if err := db.DB.Where("`key` = ?", "sensitive_words").First(&cfg).Error; err != nil {
		sensitiveWordsLoaded = true
		return
	}
	if cfg.Value == "" {
		sensitiveWordsLoaded = true
		return
	}
	var words []string
	if err := json.Unmarshal([]byte(cfg.Value), &words); err != nil {
		log.Printf("解析敏感词配置失败，使用默认值: %v", err)
		sensitiveWordsLoaded = true
		return
	}
	if len(words) > 0 {
		sensitiveWords = words
	}
	sensitiveWordsLoaded = true
}

// ReloadSensitiveWords 强制重新从数据库加载敏感词
func ReloadSensitiveWords() {
	sensitiveWordsMu.Lock()
	sensitiveWordsLoaded = false
	sensitiveWordsMu.Unlock()
	loadSensitiveWords()
}

// CheckSensitiveWords 检测文本中是否包含敏感词
func CheckSensitiveWords(text string) []string {
	loadSensitiveWords()

	sensitiveWordsMu.RLock()
	words := sensitiveWords
	sensitiveWordsMu.RUnlock()

	var matched []string
	lowerText := strings.ToLower(text)
	for _, word := range words {
		if strings.Contains(lowerText, strings.ToLower(word)) {
			matched = append(matched, word)
		}
	}
	return matched
}

// CreateAuditIfNeeded 如果检测到敏感词，自动创建审核记录
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
		Status:      0,
	}
	if err := db.DB.Create(&audit).Error; err != nil {
		log.Printf("创建审核记录失败: content_type=%s, content_id=%d, user_id=%d, err=%v", contentType, contentID, userID, err)
		return false
	}
	return true
}
