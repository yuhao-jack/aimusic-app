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

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    exit 1
fi

# 设置 COMPOSE_CMD
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# 创建 .env 文件（如果不存在）
if [ ! -f .env ]; then
    echo -e "${YELLOW}创建 .env 文件...${NC}"
    cat > .env << EOF
# MySQL
MYSQL_ROOT_PASSWORD=1qaz@WSX3edc

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
EOF
    echo -e "${GREEN}.env 文件已创建${NC}"
fi

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
        $COMPOSE_CMD down
        $COMPOSE_CMD build --no-cache
        $COMPOSE_CMD up -d
        echo -e "${GREEN}部署完成${NC}"
        echo ""
        echo "管理后台: https://music-plt.rich-thinker.asia"
        echo "API 服务: https://music-api.rich-thinker.asia"
        ;;
    logs)
        $COMPOSE_CMD logs -f ${2:-""}
        ;;
    status)
        echo -e "${YELLOW}服务状态:${NC}"
        $COMPOSE_CMD ps
        ;;
    *)
        echo "用法: $0 {start|stop|restart|build|deploy|logs|status}"
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
