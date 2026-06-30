# ============================================================================
# Go 后端 Dockerfile — 多阶段构建
# ============================================================================

# 阶段1: 编译
FROM golang:1.26-alpine AS builder

WORKDIR /build

# 安装基础编译依赖
RUN apk add --no-cache gcc musl-dev

# 复制 go.mod 和 go.sum
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# 复制源代码
COPY backend/ .

# 编译（禁用CGO，生产环境使用MySQL不需要CGO）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o aimusic-server main.go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o aimusic-consumer cmd/consumer/main.go

# 阶段2: 运行
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

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
