#!/bin/bash

# AI 音乐 APP - 快速启动脚本
# 用于快速启动后端和前端进行端到端测试

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

echo "🎵 AI 音乐 APP - 快速启动"
echo "================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：显示菜单
show_menu() {
    echo "请选择要启动的服务："
    echo "1) 🚀 启动后端服务"
    echo "2) 📱 启动前端应用"
    echo "3) 🔧 同时启动后端和前端"
    echo "4) 🧪 运行健康检查"
    echo "5) 📋 显示项目文档"
    echo "6) ❌ 退出"
    echo ""
    read -p "请输入选项 (1-6): " choice
}

# 函数：启动后端
start_backend() {
    echo ""
    echo -e "${GREEN}🚀 启动后端服务...${NC}"
    echo "------------------------"
    
    cd "$BACKEND_DIR"
    
    # 检查是否有编译好的二进制
    if [ -f "./aimusic-server" ]; then
        echo "使用编译好的二进制文件..."
        echo "后端服务将启动在 http://0.0.0.0:8080"
        echo ""
        echo "按 Ctrl+C 停止服务"
        echo ""
        ./aimusic-server
    else
        echo "使用 go run 启动..."
        if [ -f "go.mod" ]; then
            echo "下载依赖..."
            go mod download
        fi
        echo "后端服务将启动在 http://0.0.0.0:8080"
        echo ""
        echo "按 Ctrl+C 停止服务"
        echo ""
        go run cmd/main.go
    fi
}

# 函数：启动前端
start_frontend() {
    echo ""
    echo -e "${GREEN}📱 启动前端应用...${NC}"
    echo "------------------------"
    
    cd "$FRONTEND_DIR"
    
    # 检查 Flutter 是否安装
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}错误: Flutter 未安装${NC}"
        echo "请先安装 Flutter: https://flutter.dev/docs/get-started/install"
        return 1
    fi
    
    echo "检查 Flutter 环境..."
    flutter --version
    echo ""
    
    # 获取 Flutter 设备
    echo "可用设备："
    flutter devices
    echo ""
    
    # 安装依赖
    echo "安装依赖..."
    flutter pub get
    echo ""
    
    echo "前端应用即将启动..."
    echo "按 Ctrl+C 停止服务"
    echo ""
    flutter run
}

# 函数：健康检查
health_check() {
    echo ""
    echo -e "${GREEN}🧪 运行健康检查...${NC}"
    echo "------------------------"
    
    # 检查后端是否在运行
    echo "检查后端服务..."
    if curl -s "http://localhost:8080/health" > /dev/null; then
        echo -e "${GREEN}✅ 后端服务运行正常${NC}"
        echo "响应："
        curl -s "http://localhost:8080/health"
        echo ""
    else
        echo -e "${YELLOW}⚠️  后端服务未运行或无法访问${NC}"
        echo "请先启动后端服务（选项 1）"
    fi
    
    echo ""
    
    # 检查项目文件
    echo "检查项目文件..."
    check_file "$PROJECT_ROOT/DESIGN.md" "设计系统文档"
    check_file "$PROJECT_ROOT/APP_TESTING_GUIDE.md" "测试指南"
    check_file "$PROJECT_ROOT/PROJECT_READINESS.md" "项目完成度总结"
    check_file "$BACKEND_DIR/go.mod" "后端 Go 模块"
    check_file "$FRONTEND_DIR/pubspec.yaml" "前端 Flutter 配置"
}

# 函数：检查文件
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $2 存在${NC}"
    else
        echo -e "${RED}❌ $2 缺失${NC}"
    fi
}

# 函数：显示文档
show_docs() {
    echo ""
    echo -e "${GREEN}📋 项目文档${NC}"
    echo "------------------------"
    echo ""
    echo "📁 项目根目录: $PROJECT_ROOT"
    echo ""
    echo "📄 重要文档："
    echo "  1. DESIGN.md"
    echo "     - 完整的设计系统规范"
    echo "     - 详细的用户流程（第 9 节）"
    echo "     - AI 组件提示（第 10 节）"
    echo ""
    echo "  2. APP_TESTING_GUIDE.md"
    echo "     - 端到端测试指南"
    echo "     - 100+ 检查项"
    echo "     - 边缘场景测试"
    echo ""
    echo "  3. PROJECT_READINESS.md"
    echo "     - 项目完成度总结"
    echo "     - API 对照清单"
    echo "     - 优先级建议"
    echo ""
    echo "  4. README.md"
    echo "     - 项目介绍"
    echo "     - 技术架构"
    echo "     - 启动说明"
    echo ""
    
    read -p "是否查看某个文档？(输入文件名或回车跳过): " doc_file
    if [ -n "$doc_file" ] && [ -f "$PROJECT_ROOT/$doc_file" ]; then
        if command -v less &> /dev/null; then
            less "$PROJECT_ROOT/$doc_file"
        else
            cat "$PROJECT_ROOT/$doc_file"
        fi
    fi
}

# 主循环
while true; do
    show_menu
    case $choice in
        1)
            start_backend
            ;;
        2)
            start_frontend
            ;;
        3)
            echo -e "${YELLOW}⚠️  同时启动后端和前端需要两个终端窗口${NC}"
            echo "建议："
            echo "  终端 1: 运行选项 1（启动后端）"
            echo "  终端 2: 运行选项 2（启动前端）"
            echo ""
            read -p "按回车继续..."
            ;;
        4)
            health_check
            echo ""
            read -p "按回车继续..."
            ;;
        5)
            show_docs
            ;;
        6)
            echo -e "${GREEN}👋 再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择${NC}"
            echo ""
            ;;
    esac
done
