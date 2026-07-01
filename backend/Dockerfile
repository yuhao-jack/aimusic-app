FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o aimusic-server main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o aimusic-consumer cmd/consumer/main.go

FROM alpine:latest

WORKDIR /app

RUN apk add --no-cache tzdata ca-certificates
ENV TZ=Asia/Shanghai

COPY --from=builder /app/aimusic-server /app/
COPY --from=builder /app/aimusic-consumer /app/
COPY configs /app/configs

EXPOSE 8080

CMD ["./aimusic-server"]
