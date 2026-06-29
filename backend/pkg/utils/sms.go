package utils

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/yourname/aimusic-backend/pkg/config"
)

// SendSMS 发送短信验证码，根据配置的短信服务商分发请求
func SendSMS(phone, code string) error {
	cfg := config.AppConfig.AI.SMS
	if cfg.Provider == "" {
		return fmt.Errorf("短信服务未配置")
	}

	switch cfg.Provider {
	case "aliyun":
		return sendAliyunSMS(phone, code, cfg)
	case "tencent":
		return sendTencentSMS(phone, code, cfg)
	default:
		return fmt.Errorf("不支持的短信服务商: %s", cfg.Provider)
	}
}

// sendAliyunSMS 阿里云短信发送
// 文档: https://help.aliyun.com/document_detail/101414.html
func sendAliyunSMS(phone, code string, cfg config.SMSConfig) error {
	if cfg.AccessKey == "" || cfg.SecretKey == "" {
		return fmt.Errorf("阿里云短信AccessKey或SecretKey未配置")
	}
	if cfg.SignName == "" || cfg.TemplateCode == "" {
		return fmt.Errorf("阿里云短信SignName或TemplateCode未配置")
	}

	// 阿里云短信API参数
	params := map[string]string{
		"PhoneNumbers":  phone,
		"SignName":      cfg.SignName,
		"TemplateCode":  cfg.TemplateCode,
		"TemplateParam": fmt.Sprintf(`{"code":"%s"}`, code),
	}

	// 公共参数
	publicParams := map[string]string{
		"Format":           "JSON",
		"Version":          "2017-05-25",
		"AccessKeyId":      cfg.AccessKey,
		"SignatureMethod":  "HMAC-SHA1",
		"Timestamp":        time.Now().UTC().Format("2006-01-02T15:04:05Z"),
		"SignatureVersion": "1.0",
		"Action":           "SendSms",
	}

	// 合并参数用于签名
	allParams := make(map[string]string)
	for k, v := range publicParams {
		allParams[k] = v
	}
	for k, v := range params {
		allParams[k] = v
	}

	// 生成签名（简化版本，生产环境建议使用阿里云SDK）
	signature := generateAliyunSignature(allParams, cfg.SecretKey+"&")
	allParams["Signature"] = signature

	// 构建请求URL
	apiURL := "https://dysmsapi.aliyuncs.com/"
	query := url.Values{}
	for k, v := range allParams {
		query.Set(k, v)
	}
	fullURL := apiURL + "?" + query.Encode()

	// 发送请求
	resp, err := http.Get(fullURL)
	if err != nil {
		return fmt.Errorf("发送阿里云短信请求失败: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取阿里云短信响应失败: %v", err)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return fmt.Errorf("解析阿里云短信响应失败: %v", err)
	}

	// 检查返回码
	if code, ok := result["Code"].(string); ok && code != "OK" {
		msg, _ := result["Message"].(string)
		return fmt.Errorf("阿里云短信发送失败: %s - %s", code, msg)
	}

	return nil
}

// generateAliyunSignature 生成阿里云API签名
func generateAliyunSignature(params map[string]string, accessKeySecret string) string {
	// 按参数名排序
	sortedKeys := make([]string, 0, len(params))
	for k := range params {
		sortedKeys = append(sortedKeys, k)
	}
	// 简单排序
	for i := 0; i < len(sortedKeys); i++ {
		for j := i + 1; j < len(sortedKeys); j++ {
			if sortedKeys[i] > sortedKeys[j] {
				sortedKeys[i], sortedKeys[j] = sortedKeys[j], sortedKeys[i]
			}
		}
	}

	// 构建待签名字符串
	var queryParts []string
	for _, k := range sortedKeys {
		queryParts = append(queryParts, url.QueryEscape(k)+"="+url.QueryEscape(params[k]))
	}
	queryString := strings.Join(queryParts, "&")
	stringToSign := "GET&" + url.QueryEscape("/") + "&" + url.QueryEscape(queryString)

	// HMAC-SHA1签名
	mac := hmac.New(sha256.New, []byte(accessKeySecret))
	mac.Write([]byte(stringToSign))
	return hex.EncodeToString(mac.Sum(nil))
}

// sendTencentSMS 腾讯云短信发送
// 文档: https://cloud.tencent.com/document/product/382/55981
func sendTencentSMS(phone, code string, cfg config.SMSConfig) error {
	if cfg.AccessKey == "" || cfg.SecretKey == "" {
		return fmt.Errorf("腾讯云短信SecretId或SecretKey未配置")
	}
	if cfg.SignName == "" || cfg.TemplateCode == "" {
		return fmt.Errorf("腾讯云短信SignName或TemplateCode未配置")
	}

	// 腾讯云短信API请求体
	requestBody := map[string]interface{}{
		"PhoneNumberSet": []string{phone},
		"SmsSdkAppId":    cfg.AccessKey,
		"SignName":       cfg.SignName,
		"TemplateId":     cfg.TemplateCode,
		"TemplateParamSet": []string{code},
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		return fmt.Errorf("序列化腾讯云短信请求失败: %v", err)
	}

	// 发送请求（简化版本，生产环境建议使用腾讯云SDK）
	apiURL := "https://sms.tencentcloudapi.com"
	req, err := http.NewRequest("POST", apiURL, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("创建腾讯云短信请求失败: %v", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-TC-Action", "SendSms")
	req.Header.Set("X-TC-Version", "2021-01-11")
	req.Header.Set("X-TC-Region", "ap-guangzhou")
	req.Header.Set("X-TC-Timestamp", fmt.Sprintf("%d", time.Now().Unix()))

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("发送腾讯云短信请求失败: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取腾讯云短信响应失败: %v", err)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return fmt.Errorf("解析腾讯云短信响应失败: %v", err)
	}

	// 检查响应状态
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("腾讯云短信请求失败，状态码: %d", resp.StatusCode)
	}

	return nil
}
