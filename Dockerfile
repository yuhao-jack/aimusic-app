# ============================================================================
# Go 后端 Dockerfile — 多阶段构建
# ============================================================================

# 阶段1: 编译
FROM golang:1.23-alpine AS builder

WORKDIR /build

# 安装CGO依赖（SQLite需要CGO）
RUN apk add --no-cache gcc musl-dev sqlite-dev

# 复制 go.mod 和 go.sum
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# 复制源代码
COPY backend/ .

# 编译（启用CGO以支持SQLite）
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o aimusic-server main.go
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o aimusic-consumer cmd/consumer/main.go

# 阶段2: 运行
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata sqlite-libs

WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /build/aimusic-server .
COPY --from=builder /build/aimusic-consumer .

# 复制配置文件
COPY backend/configs/ ./configs/

# 创建上传目录
RUN mkdir -p /app/uploads

# 设置时区
ENV TZ=Asia/Shanghai

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["./aimusic-server"]
