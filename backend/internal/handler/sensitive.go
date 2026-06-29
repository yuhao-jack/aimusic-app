package handler

import (
	"strings"

	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// sensitiveWords 敏感词列表（政治/色情/暴力/广告等）
// 实际生产环境应从数据库或配置文件加载，这里提供基础词库
var sensitiveWords = []string{
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

// CheckSensitiveWords 检测文本中是否包含敏感词
// 返回匹配到的敏感词列表，如果没有匹配返回空切片
func CheckSensitiveWords(text string) []string {
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
	db.DB.Create(&audit)
	return true
}
