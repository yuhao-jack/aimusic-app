package utils

import (
	"fmt"
	"log"
	"net/smtp"

	"github.com/yourname/aimusic-backend/pkg/config"
)

// SendEmail 发送邮件
func SendEmail(to, subject, body string) error {
	cfg := config.AppConfig.AI.Email
	if cfg.SMTPHost == "" {
		return fmt.Errorf("邮件服务未配置")
	}

	addr := fmt.Sprintf("%s:%d", cfg.SMTPHost, cfg.SMTPPort)
	auth := smtp.PlainAuth("", cfg.SMTPUser, cfg.SMTPPassword, cfg.SMTPHost)

	msg := []byte(fmt.Sprintf("From: %s <%s>\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n%s",
		cfg.FromName, cfg.SMTPUser, to, subject, body))

	return smtp.SendMail(addr, auth, cfg.SMTPUser, []string{to}, msg)
}

// SendVerificationCode 发送验证码邮件
func SendVerificationCode(to, code string) error {
	subject := "音浪AI - 验证码"
	body := fmt.Sprintf(`
    <div style="font-family: sans-serif; max-width: 400px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #333;">音浪AI</h2>
        <p>您的验证码是：</p>
        <div style="font-size: 32px; font-weight: bold; color: #8E99A4; letter-spacing: 8px; padding: 16px; background: #f5f5f5; text-align: center; border-radius: 8px;">%s</div>
        <p style="color: #666; font-size: 13px;">验证码10分钟内有效，请勿泄露给他人。</p>
    </div>
    `, code)

	err := SendEmail(to, subject, body)
	if err != nil {
		log.Printf("发送验证码邮件失败: %v, 收件人: %s", err, to)
		return err
	}
	return nil
}
