package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/yourname/aimusic-backend/pkg/config"
)

// AIService AI服务接口
type AIService interface {
	// GenerateLyric 生成歌词
	GenerateLyric(prompt, style, emotion, lang string) (string, error)
	
	// OptimizeLyric 优化歌词
	OptimizeLyric(lyric, style string) (string, error)
	
	// GenerateSong 生成歌曲（返回任务ID）
	GenerateSong(lyric, style, emotion, voiceID string, duration int, title string) (string, error)
	
	// GetSongGenerationProgress 获取歌曲生成进度
	GetSongGenerationProgress(taskID string) (*SongGenerationProgress, error)
}

// SongGenerationProgress 歌曲生成进度
type SongGenerationProgress struct {
	Status    string  `json:"status"`    // waiting, running, completed, failed
	Progress  int     `json:"progress"`  // 0-100
	AudioURL  string  `json:"audio_url"` // 完成后的音频URL
	CoverURL  string  `json:"cover_url"` // 封面URL
	ErrorMsg  string  `json:"error_msg"` // 错误信息
}

// aiService AI服务实现
type aiService struct {
	client *http.Client
	cfg    *config.Config
}

// NewAIService 创建AI服务
func NewAIService(cfg *config.Config) AIService {
	return &aiService{
		client: &http.Client{
			Timeout: 120 * time.Second,
		},
		cfg: cfg,
	}
}

// GenerateLyric 生成歌词
func (s *aiService) GenerateLyric(prompt, style, emotion, lang string) (string, error) {
	// 优先使用豆包API
	if s.cfg.AI.DoubaoAPIKey != "" && s.cfg.AI.DoubaoAPIKey != "your_doubao_api_key" {
		return s.generateLyricWithDoubao(prompt, style, emotion, lang)
	}
	
	// 第二选择：使用DeepSeek
	if s.cfg.AI.DeepSeekAPIKey != "" && s.cfg.AI.DeepSeekAPIKey != "your_deepseek_api_key" {
		return s.generateLyricWithDeepSeek(prompt, style, emotion, lang)
	}
	
	// 备用：使用OpenAI
	if s.cfg.AI.OpenAIAPIKey != "" && s.cfg.AI.OpenAIAPIKey != "your_openai_api_key" {
		return s.generateLyricWithOpenAI(prompt, style, emotion, lang)
	}
	
	return "", fmt.Errorf("no AI API configured for lyric generation")
}

// OptimizeLyric 优化歌词
func (s *aiService) OptimizeLyric(lyric, style string) (string, error) {
	// 优先使用豆包API
	if s.cfg.AI.DoubaoAPIKey != "" && s.cfg.AI.DoubaoAPIKey != "your_doubao_api_key" {
		return s.optimizeLyricWithDoubao(lyric, style)
	}
	
	// 第二选择：使用DeepSeek
	if s.cfg.AI.DeepSeekAPIKey != "" && s.cfg.AI.DeepSeekAPIKey != "your_deepseek_api_key" {
		return s.optimizeLyricWithDeepSeek(lyric, style)
	}
	
	// 备用：使用OpenAI
	if s.cfg.AI.OpenAIAPIKey != "" && s.cfg.AI.OpenAIAPIKey != "your_openai_api_key" {
		return s.optimizeLyricWithOpenAI(lyric, style)
	}
	
	return "", fmt.Errorf("no AI API configured for lyric optimization")
}

// generateLyricWithDoubao 使用豆包API生成歌词
func (s *aiService) generateLyricWithDoubao(prompt, style, emotion, lang string) (string, error) {
	// 标准化语言参数
	var actualLang string
	switch lang {
	case "中文", "zh", "cn", "Chinese":
		actualLang = "中文"
	case "英文", "en", "English":
		actualLang = "英文"
	default:
		actualLang = "中文" // 默认使用中文
	}
	
	// 构建请求
	systemPrompt := fmt.Sprintf(`你是一个专业的歌词创作助手。请根据用户的需求创作一首完整的歌词。
要求：
- 风格：%s
- 情绪：%s
- 语言：%s
- 结构清晰，包含主歌、副歌、桥段
- 押韵自然，富有感染力
- 字数适中，适合演唱
- **必须使用 %s 创作歌词，不要使用其他语言！**`, style, emotion, actualLang, actualLang)

	userPrompt := fmt.Sprintf("请创作一首关于\"%s\"的歌词", prompt)

	requestBody := map[string]interface{}{
		"model": s.cfg.AI.DoubaoModel,
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": userPrompt,
			},
		},
		"temperature": 0.7,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.DoubaoBaseURL+"/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.DoubaoAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	// 解析响应
	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("invalid response format")
	}

	choice, ok := choices[0].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("invalid choice format")
	}

	message, ok := choice["message"].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("invalid message format")
	}

	content, ok := message["content"].(string)
	if !ok {
		return "", fmt.Errorf("invalid content format")
	}

	return content, nil
}

// generateLyricWithOpenAI 使用OpenAI API生成歌词
func (s *aiService) generateLyricWithOpenAI(prompt, style, emotion, lang string) (string, error) {
	// 标准化语言参数
	var actualLang string
	switch lang {
	case "中文", "zh", "cn", "Chinese":
		actualLang = "中文"
	case "英文", "en", "English":
		actualLang = "英文"
	default:
		actualLang = "中文" // 默认使用中文
	}
	
	// 类似豆包的实现，这里简化
	systemPrompt := fmt.Sprintf(`你是一个专业的歌词创作助手。请根据用户的需求创作一首完整的歌词。
要求：
- 风格：%s
- 情绪：%s
- 语言：%s
- 结构清晰，包含主歌、副歌、桥段
- **必须使用 %s 创作歌词，不要使用其他语言！**`, style, emotion, actualLang, actualLang)

	userPrompt := fmt.Sprintf("请创作一首关于\"%s\"的歌词", prompt)

	requestBody := map[string]interface{}{
		"model": s.cfg.AI.OpenAIModel,
		"messages": []map[string]string{
			{"role": "system", "content": systemPrompt},
			{"role": "user", "content": userPrompt},
		},
		"temperature": 0.7,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.OpenAIBaseURL+"/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.OpenAIAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("invalid response")
	}

	choice := choices[0].(map[string]interface{})
	message := choice["message"].(map[string]interface{})
	content := message["content"].(string)

	return content, nil
}

// generateLyricWithDeepSeek 使用DeepSeek API生成歌词
func (s *aiService) generateLyricWithDeepSeek(prompt, style, emotion, lang string) (string, error) {
	// 标准化语言参数
	var actualLang string
	switch lang {
	case "中文", "zh", "cn", "Chinese":
		actualLang = "中文"
	case "英文", "en", "English":
		actualLang = "英文"
	default:
		actualLang = "中文" // 默认使用中文
	}
	
	// 构建请求
	systemPrompt := fmt.Sprintf(`你是一个专业的歌词创作助手。请根据用户的需求创作一首完整的歌词。
要求：
- 风格：%s
- 情绪：%s
- 语言：%s
- 结构清晰，包含主歌、副歌、桥段
- 押韵自然，富有感染力
- 字数适中，适合演唱
- **必须使用 %s 创作歌词，不要使用其他语言！**`, style, emotion, actualLang, actualLang)

	userPrompt := fmt.Sprintf("请创作一首关于\"%s\"的歌词", prompt)

	requestBody := map[string]interface{}{
		"model": s.cfg.AI.DeepSeekModel,
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": userPrompt,
			},
		},
		"temperature": 0.7,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.DeepSeekBaseURL+"/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.DeepSeekAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	// 解析响应
	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("invalid response format")
	}

	choice, ok := choices[0].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("invalid choice format")
	}

	message, ok := choice["message"].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("invalid message format")
	}

	content, ok := message["content"].(string)
	if !ok {
		return "", fmt.Errorf("invalid content format")
	}

	return content, nil
}

// optimizeLyricWithDoubao 使用豆包API优化歌词
func (s *aiService) optimizeLyricWithDoubao(lyric, style string) (string, error) {
	// 构建优化提示词
	systemPrompt := `你是一个专业的歌词优化助手。请根据用户的需求优化歌词。
优化要求：
- 保持原歌词的核心主题和情感
- 优化押韵和节奏，让歌词更朗朗上口
- 提升语言的艺术性和感染力
- 让副歌更有记忆点
- 确保歌词结构清晰（主歌、副歌、桥段）
- 如果用户指定了风格，请按照指定风格优化
- **只返回优化后的歌词，不要返回其他说明文字！**`

	userPrompt := fmt.Sprintf(`请优化以下歌词，目标风格：%s

原始歌词：
%s`, style, lyric)

	requestBody := map[string]interface{}{
		"model": s.cfg.AI.DoubaoModel,
		"messages": []map[string]string{
			{
				"role":    "system",
				"content": systemPrompt,
			},
			{
				"role":    "user",
				"content": userPrompt,
			},
		},
		"temperature": 0.7,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.DoubaoBaseURL+"/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.DoubaoAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	// 解析响应
	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("invalid response format")
	}

	choice, ok := choices[0].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("invalid choice format")
	}

	message, ok := choice["message"].(map[string]interface{})
	if !ok {
		return "", fmt.Errorf("invalid message format")
	}

	content, ok := message["content"].(string)
	if !ok {
		return "", fmt.Errorf("invalid content format")
	}

	return content, nil
}

// optimizeLyricWithOpenAI 使用OpenAI API优化歌词
func (s *aiService) optimizeLyricWithOpenAI(lyric, style string) (string, error) {
	// 构建优化提示词
	systemPrompt := `你是一个专业的歌词优化助手。请根据用户的需求优化歌词。
优化要求：
- 保持原歌词的核心主题和情感
- 优化押韵和节奏，让歌词更朗朗上口
- 提升语言的艺术性和感染力
- 让副歌更有记忆点
- 确保歌词结构清晰（主歌、副歌、桥段）
- 如果用户指定了风格，请按照指定风格优化
- **只返回优化后的歌词，不要返回其他说明文字！**`

	userPrompt := fmt.Sprintf(`请优化以下歌词，目标风格：%s

原始歌词：
%s`, style, lyric)

	requestBody := map[string]interface{}{
		"model": s.cfg.AI.OpenAIModel,
		"messages": []map[string]string{
			{"role": "system", "content": systemPrompt},
			{"role": "user", "content": userPrompt},
		},
		"temperature": 0.7,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.OpenAIBaseURL+"/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.OpenAIAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("invalid response")
	}

	choice := choices[0].(map[string]interface{})
	message := choice["message"].(map[string]interface{})
	content := message["content"].(string)

	return content, nil
}

// optimizeLyricWithDeepSeek 使用DeepSeek API优化歌词
func (s *aiService) optimizeLyricWithDeepSeek(lyric, style string) (string, error) {
	// 构建优化提示词
	systemPrompt := `你是一个专业的歌词优化助手。请根据用户的需求优化歌词。
优化要求：
- 保持原歌词的核心主题和情感
- 优化押韵和节奏，让歌词更朗朗上口
- 提升语言的艺术性和感染力
- 让副歌更有记忆点
- 确保歌词结构清晰（主歌、副歌、桥段）
- 如果用户指定了风格，请按照指定风格优化
- **只返回优化后的歌词，不要返回其他说明文字！**`

	userPrompt := fmt.Sprintf(`请优化以下歌词，目标风格：%s

原始歌词：
%s`, style, lyric)

	requestBody := map[string]interface{}{
		"model": s.cfg.AI.DeepSeekModel,
		"messages": []map[string]string{
			{"role": "system", "content": systemPrompt},
			{"role": "user", "content": userPrompt},
		},
		"temperature": 0.7,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.DeepSeekBaseURL+"/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.DeepSeekAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	choices, ok := result["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return "", fmt.Errorf("invalid response")
	}

	choice := choices[0].(map[string]interface{})
	message := choice["message"].(map[string]interface{})
	content := message["content"].(string)

	return content, nil
}

// GenerateSong 生成歌曲
func (s *aiService) GenerateSong(lyric, style, emotion, voiceID string, duration int, title string) (string, error) {
	// 使用Suno API
	if s.cfg.AI.SunoAPIKey != "" && s.cfg.AI.SunoAPIKey != "your_suno_api_key" {
		return s.generateSongWithSuno(lyric, style, emotion, voiceID, duration, title)
	}
	
	return "", fmt.Errorf("no AI API configured for song generation")
}

// generateSongWithSuno 使用Suno API生成歌曲
func (s *aiService) generateSongWithSuno(lyric, style, emotion, voiceID string, duration int, title string) (string, error) {
	// Suno API调用实现
	// 这里是Suno API的调用结构，具体根据Suno API文档调整
	requestBody := map[string]interface{}{
		"prompt":    lyric,
		"style":     style,
		"title":     title,
		"duration":  duration,
		"make_instrumental": false,
	}

	jsonBody, _ := json.Marshal(requestBody)

	req, err := http.NewRequest("POST", s.cfg.AI.SunoBaseURL+"/api/generate", bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.SunoAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusAccepted {
		return "", fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}

	// 解析任务ID
	taskID, ok := result["id"].(string)
	if !ok {
		// 尝试其他字段
		if taskIDNum, ok := result["task_id"].(float64); ok {
			taskID = fmt.Sprintf("%.0f", taskIDNum)
		} else {
			return "", fmt.Errorf("task_id not found in response")
		}
	}

	return taskID, nil
}

// GetSongGenerationProgress 获取歌曲生成进度
func (s *aiService) GetSongGenerationProgress(taskID string) (*SongGenerationProgress, error) {
	// 使用Suno API查询进度
	if s.cfg.AI.SunoAPIKey != "" && s.cfg.AI.SunoAPIKey != "your_suno_api_key" {
		return s.getSongProgressWithSuno(taskID)
	}
	
	return nil, fmt.Errorf("no AI API configured")
}

// getSongProgressWithSuno 使用Suno API查询进度
func (s *aiService) getSongProgressWithSuno(taskID string) (*SongGenerationProgress, error) {
	req, err := http.NewRequest("GET", s.cfg.AI.SunoBaseURL+"/api/generate/"+taskID, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.SunoAPIKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error: %s", string(body))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}

	// 解析进度
	status, _ := result["status"].(string)
	progress, _ := result["progress"].(float64)
	audioURL, _ := result["audio_url"].(string)
	coverURL, _ := result["cover_url"].(string)
	errorMsg, _ := result["error"].(string)

	// 状态映射
	var mappedStatus string
	switch status {
	case "queued", "pending":
		mappedStatus = "waiting"
	case "processing", "running":
		mappedStatus = "running"
	case "completed", "success":
		mappedStatus = "completed"
	case "failed", "error":
		mappedStatus = "failed"
	default:
		mappedStatus = status
	}

	return &SongGenerationProgress{
		Status:    mappedStatus,
		Progress:  int(progress),
		AudioURL:  audioURL,
		CoverURL:  coverURL,
		ErrorMsg:  errorMsg,
	}, nil
}
