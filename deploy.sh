#!/bin/bash
# ============================================================================
# AI Music Platform — 部署脚本
# ============================================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  AI Music Platform 部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 检查 Docker - 使用 which 命令更可靠
if ! which docker > /dev/null 2>&1; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    echo "请先安装Docker: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}Docker 未运行，正在启动...${NC}"
    sudo systemctl start docker
    sleep 3
fi

echo -e "${GREEN}✓ Docker 已安装: $(docker --version)${NC}"

# 检查 Docker Compose
COMPOSE_CMD=""
if docker compose version > /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✓ Docker Compose (插件模式)${NC}"
elif which docker-compose > /dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓ Docker Compose (独立模式)${NC}"
else
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    echo "请安装Docker Compose:"
    echo "  sudo curl -L 'https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)' -o /usr/local/bin/docker-compose"
    echo "  sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

# 创建 .env 文件（如果不存在）
if [ ! -f .env ]; then
    echo -e "${YELLOW}创建 .env 文件...${NC}"
    cat > .env << 'EOF'
# MySQL
MYSQL_ROOT_PASSWORD=1qaz@WSX3edc

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

# JWT密钥（生产环境必须修改）
JWT_SECRET=aimusic2024secretkey_change_in_production

# AI服务密钥（可选）
DOUBAO_API_KEY=
SUNO_API_KEY=
EOF
    echo -e "${GREEN}.env 文件已创建${NC}"
fi

echo ""

# 解析命令
case "$1" in
    start)
        echo -e "${YELLOW}启动服务...${NC}"
        $COMPOSE_CMD up -d
        echo -e "${GREEN}服务已启动${NC}"
        echo ""
        echo "管理后台: https://music-plt.rich-thinker.asia"
        echo "API 服务: https://music-api.rich-thinker.asia"
        ;;
    stop)
        echo -e "${YELLOW}停止服务...${NC}"
        $COMPOSE_CMD down
        echo -e "${GREEN}服务已停止${NC}"
        ;;
    restart)
        echo -e "${YELLOW}重启服务...${NC}"
        $COMPOSE_CMD restart
        echo -e "${GREEN}服务已重启${NC}"
        ;;
    build)
        echo -e "${YELLOW}构建镜像...${NC}"
        $COMPOSE_CMD build --no-cache
        echo -e "${GREEN}镜像构建完成${NC}"
        ;;
    deploy)
        echo -e "${YELLOW}完整部署...${NC}"
        echo ""
        echo -e "${YELLOW}[1/3] 停止旧服务...${NC}"
        $COMPOSE_CMD down 2>/dev/null || true
        
        echo -e "${YELLOW}[2/3] 构建镜像（首次可能需要几分钟）...${NC}"
        $COMPOSE_CMD build --no-cache
        
        echo -e "${YELLOW}[3/3] 启动服务...${NC}"
        $COMPOSE_CMD up -d
        
        echo ""
        echo -e "${GREEN}等待服务启动...${NC}"
        sleep 10
        
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  部署完成！${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "服务状态:"
        $COMPOSE_CMD ps
        echo ""
        echo "访问地址:"
        echo "  管理后台: https://music-plt.rich-thinker.asia"
        echo "  API 服务: https://music-api.rich-thinker.asia"
        echo "  Swagger:  https://music-api.rich-thinker.asia/swagger/"
        echo ""
        echo "常用命令:"
        echo "  ./deploy.sh logs     - 查看日志"
        echo "  ./deploy.sh status   - 查看状态"
        echo "  ./deploy.sh restart  - 重启服务"
        ;;
    logs)
        $COMPOSE_CMD logs -f ${2:-""}
        ;;
    status)
        echo -e "${YELLOW}服务状态:${NC}"
        $COMPOSE_CMD ps
        echo ""
        echo -e "${YELLOW}端口监听:${NC}"
        netstat -tlnp 2>/dev/null | grep -E "8080|3000|3306|6379" || ss -tlnp | grep -E "8080|3000|3306|6379"
        ;;
    *)
        echo "用法: bash $0 {start|stop|restart|build|deploy|logs|status}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动所有服务"
        echo "  stop    - 停止所有服务"
        echo "  restart - 重启所有服务"
        echo "  build   - 重新构建镜像"
        echo "  deploy  - 完整部署（构建+启动）"
        echo "  logs    - 查看日志（可指定服务名）"
        echo "  status  - 查看服务状态"
        exit 1
        ;;
esac
