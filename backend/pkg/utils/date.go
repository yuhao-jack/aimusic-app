package utils

import "time"

// GetTodayDate 获取今天的日期字符串 yyyy-mm-dd
func GetTodayDate() string {
	return time.Now().Format("2006-01-02")
}

// GetCurrentTimestamp 获取当前时间戳
func GetCurrentTimestamp() int64 {
	return time.Now().Unix()
}
