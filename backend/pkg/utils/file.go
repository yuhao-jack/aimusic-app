package utils

import (
	"os"
	"path/filepath"
)

// EnsureDir 确保目录存在，不存在则创建
func EnsureDir(path string) error {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return os.MkdirAll(path, 0755)
	}
	return nil
}

// EnsureFileDir 确保文件所在目录存在
func EnsureFileDir(filePath string) error {
	dir := filepath.Dir(filePath)
	return EnsureDir(dir)
}
