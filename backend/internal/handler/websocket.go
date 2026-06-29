package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"
	"github.com/yourname/aimusic-backend/internal/model"
	"github.com/yourname/aimusic-backend/pkg/config"
	"github.com/yourname/aimusic-backend/pkg/db"
)

// 允许的 Origin 白名单（从配置文件读取）
func getAllowedOriginsMap() map[string]bool {
	origins := map[string]bool{}
	// 优先使用配置文件中的 CORS 来源列表
	if len(config.AppConfig.CORS.AllowedOrigins) > 0 {
		for _, o := range config.AppConfig.CORS.AllowedOrigins {
			origins[o] = true
		}
	} else {
		// 默认值
		origins["http://localhost:3000"] = true
		origins["http://localhost:5173"] = true
		origins["http://localhost:8080"] = true
	}
	return origins
}

// WebSocket 升级器
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		if origin == "" {
			return true
		}
		// 开发环境允许所有来源
		if config.AppConfig.Server.Mode == "debug" || config.AppConfig.Server.Mode == "" {
			return true
		}
		return getAllowedOriginsMap()[origin]
	},
}

// WSMessage WebSocket 消息结构
type WSMessage struct {
	Type    string      `json:"type"`    // play/pause/seek/switch_song/chat/heartbeat/user_join/user_leave
	Payload interface{} `json:"payload"` // 消息负载
	UserID  uint        `json:"user_id"` // 发送者ID
	RoomID  uint        `json:"room_id"` // 房间ID
}

// WSClient WebSocket 客户端连接
type WSClient struct {
	Conn       *websocket.Conn
	RoomID     uint
	UserID     uint
	msgTokens  int       // 当前秒内剩余的消息令牌
	lastRefill time.Time // 上次补充令牌的时间
	mu         sync.Mutex // 保护令牌相关字段
}

// RoomManager 房间连接管理器（线程安全）
type RoomManager struct {
	rooms map[uint]map[*WSClient]bool
	mu    sync.RWMutex
}

// 全局房间管理器
var roomManager = &RoomManager{
	rooms: make(map[uint]map[*WSClient]bool),
}

// AddClient 将客户端添加到房间
func (rm *RoomManager) AddClient(client *WSClient) {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	if rm.rooms[client.RoomID] == nil {
		rm.rooms[client.RoomID] = make(map[*WSClient]bool)
	}
	rm.rooms[client.RoomID][client] = true
}

// RemoveClient 从房间移除客户端
func (rm *RoomManager) RemoveClient(client *WSClient) {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	if clients, ok := rm.rooms[client.RoomID]; ok {
		delete(clients, client)
		if len(clients) == 0 {
			delete(rm.rooms, client.RoomID)
		}
	}
}

// Broadcast 向房间内广播消息（排除发送者），写入失败时清理客户端
func (rm *RoomManager) Broadcast(roomID uint, sender *WSClient, msg []byte) {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	if clients, ok := rm.rooms[roomID]; ok {
		for client := range clients {
			if client != sender {
				if err := client.Conn.WriteMessage(websocket.TextMessage, msg); err != nil {
					// 标记失败客户端，后续清理
					client.Conn.Close()
				}
			}
		}
	}
}

// BroadcastAll 向房间内广播消息（包括发送者），写入失败时清理客户端
func (rm *RoomManager) BroadcastAll(roomID uint, msg []byte) {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	if clients, ok := rm.rooms[roomID]; ok {
		for client := range clients {
			if err := client.Conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				client.Conn.Close()
			}
		}
	}
}

// GetRoomMemberCount 获取房间在线人数
func (rm *RoomManager) GetRoomMemberCount(roomID uint) int {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	if clients, ok := rm.rooms[roomID]; ok {
		return len(clients)
	}
	return 0
}

// HandleTogetherWS 处理一起听房间的 WebSocket 连接
func HandleTogetherWS(c *gin.Context) {
	roomIDStr := c.Param("room_id")
	roomID, err := strconv.ParseUint(roomIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "msg": "房间ID格式错误"})
		return
	}

	// 验证房间存在
	var room model.TogetherRoom
	if err := db.DB.First(&room, roomID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "msg": "房间不存在"})
		return
	}

	// 从查询参数获取 token
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "msg": "缺少认证token"})
		return
	}

	// 解析 token
	userID, err := parseWSToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "msg": "token无效或已过期"})
		return
	}

	// 升级 HTTP 为 WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	defer conn.Close()

	client := &WSClient{
		Conn:       conn,
		RoomID:     uint(roomID),
		UserID:     userID,
		msgTokens:  3,                      // 初始3个令牌
		lastRefill: time.Now(),             // 初始补充时间
	}
	roomManager.AddClient(client)
	defer roomManager.RemoveClient(client)

	// 广播用户加入
	joinMsg, _ := json.Marshal(WSMessage{
		Type:    "user_join",
		UserID:  userID,
		RoomID:  uint(roomID),
		Payload: map[string]interface{}{"online_count": roomManager.GetRoomMemberCount(uint(roomID))},
	})
	roomManager.Broadcast(uint(roomID), client, joinMsg)

	// 心跳设置
	conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	// 心跳协程
	go func() {
		ticker := time.NewTicker(30 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}()

	// 消息读取循环
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			leaveMsg, _ := json.Marshal(WSMessage{
				Type:    "user_leave",
				UserID:  userID,
				RoomID:  uint(roomID),
				Payload: map[string]interface{}{"online_count": roomManager.GetRoomMemberCount(uint(roomID)) - 1},
			})
			roomManager.Broadcast(uint(roomID), client, leaveMsg)
			break
		}

		var wsMsg WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			continue
		}
		wsMsg.UserID = userID
		wsMsg.RoomID = uint(roomID)

		// 频率限制：同一用户每秒最多3条消息
		if !client.checkAndConsumeToken() {
			// 超过频率限制，忽略消息
			continue
		}

		switch wsMsg.Type {
		case "play", "pause", "seek", "switch_song":
			// 播放控制：广播给其他人
			broadcastMsg, _ := json.Marshal(wsMsg)
			roomManager.Broadcast(uint(roomID), client, broadcastMsg)
			// 同步房间状态到数据库（使用事务保证原子性）
			tx := db.DB.Begin()
			switch wsMsg.Type {
			case "play":
				if err := tx.Model(&model.TogetherRoom{}).Where("id = ?", roomID).Update("now_playing", 1).Error; err != nil {
					tx.Rollback()
					continue
				}
			case "pause":
				if err := tx.Model(&model.TogetherRoom{}).Where("id = ?", roomID).Update("now_playing", 0).Error; err != nil {
					tx.Rollback()
					continue
				}
			case "switch_song":
				if payload, ok := wsMsg.Payload.(map[string]interface{}); ok {
					if songID, ok := payload["song_id"].(float64); ok {
						if err := tx.Model(&model.TogetherRoom{}).Where("id = ?", roomID).Update("song_id", uint(songID)).Error; err != nil {
							tx.Rollback()
							continue
						}
					}
				}
			}
			tx.Commit()
		case "chat":
			// 聊天：广播给所有人
			broadcastMsg, _ := json.Marshal(wsMsg)
			roomManager.BroadcastAll(uint(roomID), broadcastMsg)
		case "heartbeat":
			pongMsg, _ := json.Marshal(WSMessage{
				Type:    "heartbeat_ack",
				UserID:  userID,
				RoomID:  uint(roomID),
				Payload: map[string]interface{}{"online_count": roomManager.GetRoomMemberCount(uint(roomID))},
			})
			conn.WriteMessage(websocket.TextMessage, pongMsg)
		default:
			broadcastMsg, _ := json.Marshal(wsMsg)
			roomManager.Broadcast(uint(roomID), client, broadcastMsg)
		}
	}
}

// parseWSToken 解析 WebSocket 连接中的 JWT token
func parseWSToken(tokenStr string) (uint, error) {
	claims := &struct {
		UserID uint `json:"user_id"`
		jwt.RegisteredClaims
	}{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
		return []byte(config.AppConfig.JWT.Secret), nil
	})
	if err != nil || !token.Valid {
		return 0, err
	}
	return claims.UserID, nil
}

// checkAndConsumeToken 检查并消耗消息令牌（令牌桶算法）
// 每秒最多3条消息，超过限制返回false
func (c *WSClient) checkAndConsumeToken() bool {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(c.lastRefill)

	// 每秒补充3个令牌
	tokensToAdd := int(elapsed.Seconds()) * 3
	if tokensToAdd > 0 {
		c.msgTokens += tokensToAdd
		if c.msgTokens > 3 {
			c.msgTokens = 3 // 最多保留3个令牌
		}
		c.lastRefill = now
	}

	// 检查是否有可用令牌
	if c.msgTokens <= 0 {
		return false
	}

	// 消耗一个令牌
	c.msgTokens--
	return true
}
