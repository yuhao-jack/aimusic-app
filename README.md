# 🎵 音浪AI — AI音乐创作平台

<p align="center">
  <img src="frontend/assets/icons/app_icon.png" width="120" alt="Logo">
</p>

<p align="center">
  <strong>一站式AI音乐创作、社交分享、音乐社区平台</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Go-1.22-blue?logo=go" alt="Go">
  <img src="https://img.shields.io/badge/Flutter-3.38-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Vue-3-green?logo=vuedotjs" alt="Vue">
  <img src="https://img.shields.io/badge/MySQL-8.0-orange?logo=mysql" alt="MySQL">
  <img src="https://img.shields.io/badge/Redis-7-red?logo=redis" alt="Redis">
  <img src="https://img.shields.io/badge/Docker-Compose-blue?logo=docker" alt="Docker">
</p>

---

## 📖 项目简介

音浪AI是一个全栈AI音乐创作平台，集成了AI歌词生成、AI歌曲生成、音乐社交、一起听房间、会员体系、积分商城等完整功能。

### 核心特性

- 🤖 **AI创作** — 智能歌词生成、歌词优化、AI歌曲生成
- 🎧 **音乐播放** — 高品质播放、歌词同步、睡眠定时、均衡器
- 👥 **社交互动** — 动态发布、评论点赞、关注粉丝、私信通知
- 🎶 **一起听** — 实时房间、WebSocket同步、多人听歌
- 💎 **会员体系** — VIP/SVIP特权、音币系统、签到任务
- 🛒 **积分商城** — 商品兑换、限时折扣、邀请奖励
- 📊 **数据看板** — DAU/WAU/MAU、用户行为埋点、营收分析
- 🔒 **内容审核** — 敏感词检测、自动审核、人工复核

---

## 🏗️ 项目架构

```
aimusic-app/
├── backend/                # Go 后端 (Gin + GORM)
│   ├── cmd/consumer/       # Redis Streams 异步任务消费者
│   ├── internal/
│   │   ├── handler/        # API 处理器
│   │   ├── middleware/     # 中间件 (JWT/CORS/限流/审计)
│   │   ├── model/          # 数据模型
│   │   └── router/         # 路由定义
│   ├── pkg/                # 公共包 (config/db/utils/ai)
│   └── configs/            # 配置文件
│
├── frontend/               # Flutter 移动端 (GetX + Dio)
│   ├── lib/
│   │   ├── modules/        # 业务模块 (36个页面)
│   │   ├── services/       # API服务层
│   │   ├── theme/          # 主题系统
│   │   ├── utils/          # 工具类
│   │   └── widgets/        # 通用组件
│   └── assets/             # 静态资源
│
├── admin/                  # Vue 管理后台 (Element Plus)
│   ├── src/
│   │   ├── views/          # 页面组件 (42个)
│   │   ├── router/         # 路由配置
│   │   └── components/     # 公共组件
│   └── vite.config.js      # Vite配置
│
├── docker-compose.yml      # Docker 编排
├── Dockerfile              # 后端镜像
├── Dockerfile.admin        # 管理后台镜像
├── nginx/                  # Nginx配置
└── deploy.sh               # 部署脚本
```

---

## 🛠️ 技术栈

### 后端 (Go)

| 技术 | 用途 |
|------|------|
| **Gin** | HTTP框架 |
| **GORM** | ORM框架 |
| **MySQL 8.0** | 主数据库 |
| **Redis 7** | 缓存/限流/消息队列 |
| **MinIO** | 对象存储 |
| **JWT** | 身份认证 |
| **WebSocket** | 实时通信 |

### 前端 (Flutter)

| 技术 | 用途 |
|------|------|
| **GetX** | 状态管理/路由/依赖注入 |
| **Dio** | 网络请求 |
| **audioplayers** | 音频播放 |
| **cached_network_image** | 图片缓存 |
| **shared_preferences** | 本地存储 |
| **web_socket_channel** | WebSocket |

### 管理后台 (Vue)

| 技术 | 用途 |
|------|------|
| **Vue 3** | 前端框架 |
| **Element Plus** | UI组件库 |
| **Vite** | 构建工具 |
| **ECharts** | 数据可视化 |
| **Axios** | HTTP客户端 |

---

## ✨ 功能特性

### 🤖 AI创作中心

- **歌词生成** — 输入主题/风格/情绪，AI智能生成歌词
- **歌词优化** — 对已有歌词进行风格优化
- **歌曲生成** — 基于歌词生成完整歌曲（异步任务）
- **任务队列** — Redis Streams + Consumer消费
- **配额管理** — 免费3次/天，VIP 10次/天，SVIP无限

### 🎧 音乐播放器

- 播放/暂停/上一首/下一首
- 进度条拖动
- 播放模式切换（顺序/随机/单曲循环）
- 歌词同步滚动 + 高亮
- 睡眠定时器
- 均衡器预设
- 封面旋转动画
- 手势操作（滑动切歌/双击点赞/长按分享）

### 👥 社交系统

- **动态** — 发布图文动态、关联话题
- **评论** — 一级/二级评论、点赞
- **关注** — 关注/粉丝、关注动态流
- **通知** — 系统通知、互动通知、未读计数
- **举报** — 内容举报、管理员处理

### 🎶 一起听房间

- 创建房间（支持密码）
- 加入/退出房间
- WebSocket实时同步（播放/暂停/切歌）
- 房间内聊天
- 踢出成员
- 社区动态

### 💎 会员体系

| 特权 | 普通用户 | VIP | SVIP |
|------|---------|-----|------|
| AI创作/天 | 3次 | 10次 | 无限 |
| 音质 | 标准 | 高品质 | 无损 |
| 下载 | ❌ | ✅ | ✅ |
| 声音克隆 | ❌ | ✅ | ✅ |
| 专属客服 | ❌ | ❌ | ✅ |
| 签到音币 | 5 | 10 | 20 |

### 🛒 商业化

- **VIP购买** — 月卡/季卡/年卡
- **音币充值** — 多档位充值包
- **每日签到** — 连续签到递增奖励
- **积分商城** — 商品兑换
- **限时折扣** — 运营配置促销
- **邀请奖励** — 双向奖励机制

### 📊 管理后台

- **仪表盘** — KPI卡片、趋势图、分布图、排行榜
- **用户管理** — 列表/详情/禁用/画像/分群
- **内容管理** — 歌曲/MV/动态/评论/房间/音色
- **内容审核** — 敏感词检测、审核通过/拒绝联动
- **商业化** — VIP套餐/音币包/订单/财务报表
- **运营管理** — Banner/话题/活动/广告位/精选歌单
- **数据统计** — DAU/WAU/MAU、留存、漏斗、营收
- **系统管理** — 配置/版本/敏感词/操作日志

---

## 🚀 快速开始

### 环境要求

- Go 1.22+
- Flutter 3.38+
- Node.js 20+
- MySQL 8.0
- Redis 7
- MinIO (可选)

### 1. 克隆项目

```bash
git clone git@gitee.com:yuhao-jack/aimusic-app.git
cd aimusic-app
```

### 2. 启动基础设施

```bash
# 使用Docker启动MySQL和Redis
docker-compose up -d mysql redis minio
```

### 3. 启动后端

```bash
cd backend

# 安装依赖
go mod tidy

# 启动API服务
go run main.go

# 启动任务消费者（新终端）
go run cmd/consumer/main.go
```

### 4. 启动管理后台

```bash
cd admin

# 安装依赖
npm install

# 启动开发服务器
npm run dev
# 访问 http://localhost:5173
```

### 5. 启动Flutter APP

```bash
cd frontend

# 安装依赖
flutter pub get

# 运行APP
flutter run

# 构建APK
flutter build apk --release
```

---

## 🐳 Docker部署

### 一键部署

```bash
# 给部署脚本执行权限
chmod +x deploy.sh

# 完整部署
./deploy.sh deploy
```

### 部署命令

```bash
./deploy.sh start    # 启动服务
./deploy.sh stop     # 停止服务
./deploy.sh restart  # 重启服务
./deploy.sh build    # 重新构建
./deploy.sh deploy   # 完整部署
./deploy.sh logs     # 查看日志
./deploy.sh status   # 查看状态
```

### 域名配置

| 服务 | 域名 |
|------|------|
| 管理后台 | `music-plt.rich-thinker.asia` |
| API服务 | `music-api.rich-thinker.asia` |

---

## 📡 API文档

### 公开接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/user/register` | 用户注册 |
| POST | `/api/v1/user/login` | 密码登录 |
| POST | `/api/v1/user/login/phone` | 手机登录 |
| POST | `/api/v1/user/refresh-token` | 刷新Token |
| GET | `/api/v1/music/recommend` | 推荐歌曲 |
| GET | `/api/v1/music/daily-recommend` | 每日推荐 |
| GET | `/api/v1/music/charts` | 音乐榜单 |
| GET | `/api/v1/music/search` | 搜索歌曲 |
| GET | `/api/v1/search/hot` | 热搜关键词 |
| GET | `/api/v1/playlist/featured` | 精选歌单 |
| GET | `/api/v1/system/config` | 系统配置 |
| GET | `/api/v1/system/version-check` | 版本检查 |

### 用户接口 (需JWT)

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/user/info` | 用户信息 |
| POST | `/api/v1/ai/lyric/generate` | 生成歌词 |
| POST | `/api/v1/ai/song/generate` | 生成歌曲 |
| POST | `/api/v1/music/:id/like` | 点赞歌曲 |
| POST | `/api/v1/post/create` | 发布动态 |
| POST | `/api/v1/membership/buy-vip` | 购买VIP |
| POST | `/api/v1/membership/check-in` | 每日签到 |
| POST | `/api/v1/events/track` | 行为埋点 |

### 管理接口 (需Admin JWT)

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/dashboard/stats` | 仪表盘统计 |
| GET | `/api/admin/dashboard/trend` | 趋势数据 |
| GET | `/api/admin/users` | 用户列表 |
| GET | `/api/admin/songs` | 歌曲列表 |
| GET | `/api/admin/ai-tasks` | AI任务列表 |
| GET | `/api/admin/ai-tasks/stats` | AI任务统计 |
| POST | `/api/admin/ai-tasks/batch-retry` | 批量重试 |
| GET | `/api/admin/sensitive-words` | 敏感词列表 |
| POST | `/api/admin/sensitive-words` | 保存敏感词 |
| GET | `/api/admin/system/version` | 版本配置 |
| GET | `/api/admin/finance/report` | 财务报表 |
| GET | `/api/admin/analytics/dau` | DAU统计 |

---

## 🗄️ 数据库设计

### 核心表

| 表名 | 说明 |
|------|------|
| `users` | 用户表 |
| `songs` | 歌曲表 |
| `playlists` | 歌单表 |
| `posts` | 动态表 |
| `comments` | 评论表 |
| `likes` | 点赞表 |
| `follows` | 关注关系表 |
| `async_tasks` | 异步任务表 |
| `play_histories` | 播放历史表 |
| `together_rooms` | 一起听房间表 |
| `room_members` | 房间成员表 |
| `notifications` | 通知表 |

### 商业化表

| 表名 | 说明 |
|------|------|
| `membership_orders` | 会员订单表 |
| `coin_transactions` | 音币交易表 |
| `vip_plans` | VIP套餐表 |
| `coin_packages` | 音币充值包表 |
| `discounts` | 限时折扣表 |
| `check_in_records` | 签到记录表 |

### 运营表

| 表名 | 说明 |
|------|------|
| `banners` | Banner表 |
| `topics` | 话题表 |
| `activities` | 活动表 |
| `ad_placements` | 广告位表 |
| `system_configs` | 系统配置表 |
| `app_versions` | 版本管理表 |
| `sensitive_words` | 敏感词表 |
| `audits` | 审核记录表 |
| `reports` | 举报表 |
| `user_bans` | 封禁表 |
| `operation_logs` | 操作日志表 |
| `user_events` | 用户行为事件表 |

---

## 📁 代码统计

| 模块 | 文件数 | 代码行数 |
|------|--------|---------|
| Go后端 | 81 | 20,811 |
| Flutter前端 | 152 | 47,077 |
| Vue管理后台 | 42 | 6,713 |
| **总计** | **275** | **74,601** |

---

## 🔐 测试账号

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 普通用户 | testuser | 123456 |
| VIP用户 | vipuser | 123456 |
| SVIP用户 | svipuser | 123456 |
| 管理员 | admin | admin |

---

## 📝 配置说明

### 后端配置 (backend/configs/config.yaml)

```yaml
server:
  port: 8080
  mode: release

mysql:
  host: ${DB_HOST:-127.0.0.1}
  port: ${DB_PORT:-3306}
  username: ${DB_USER:-root}
  password: ${DB_PASSWORD:-your_password}
  database: ${DB_NAME:-aimusic}

redis:
  host: ${REDIS_HOST:-127.0.0.1}
  port: ${REDIS_PORT:-6379}
  password: ${REDIS_PASSWORD:-}

jwt:
  secret: ${JWT_SECRET:-your_secret_key}
  expire_hours: 24
  refresh_expire_hours: 168
```

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `DB_HOST` | MySQL主机 | 127.0.0.1 |
| `DB_PORT` | MySQL端口 | 3306 |
| `DB_USER` | MySQL用户 | root |
| `DB_PASSWORD` | MySQL密码 | - |
| `DB_NAME` | 数据库名 | aimusic |
| `REDIS_HOST` | Redis主机 | 127.0.0.1 |
| `REDIS_PORT` | Redis端口 | 6379 |
| `REDIS_PASSWORD` | Redis密码 | - |
| `JWT_SECRET` | JWT密钥 | - |
| `DOUBAO_API_KEY` | 豆包API密钥 | - |
| `SUNO_API_KEY` | Suno API密钥 | - |

---

## 🧪 测试

### 后端测试

```bash
cd backend

# 运行所有测试
go test ./...

# 运行特定测试
go test ./internal/handler/ -run TestFunctionName

# 查看测试覆盖率
go test -cover ./...
```

### 前端测试

```bash
cd frontend

# 静态分析
flutter analyze

# 运行测试
flutter test
```

---

## 📦 构建

### 后端构建

```bash
cd backend

# 构建API服务
go build -o aimusic-server main.go

# 构建任务消费者
go build -o aimusic-consumer cmd/consumer/main.go
```

### 前端构建

```bash
cd frontend

# Android APK
flutter build apk --release

# iOS (需要Xcode)
flutter build ios --release --no-codesign
```

### 管理后台构建

```bash
cd admin

# 构建生产版本
npm run build

# 输出: dist/
```

---

## 🔧 开发规范

### Git提交规范

```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建/工具相关
```

### 代码规范

- **Go**: 遵循 Go 官方规范，使用 gofmt 格式化
- **Dart**: 遵循 Flutter 官方规范，使用 dart format 格式化
- **Vue**: 遵循 Vue 官方规范，使用 ESLint 检查

### 注释规范

- 中文注释
- 方法/常量/接口/枚举/结构体必须注释
- 核心逻辑必须注释

---

## 🚀 服务器配置指南

### 性能架构分析

```
┌─────────────────────────────────────────────────────────────┐
│                        Nginx (反向代理)                      │
│                    静态资源 + HTTPS终止                      │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Flutter APP │    │  Admin Vue   │    │   Go Backend │
│   (客户端)    │    │  (管理后台)   │    │   (API服务)   │
└──────────────┘    └──────────────┘    └──────────────┘
                                                │
                          ┌─────────────────────┼─────────────────────┐
                          ▼                     ▼                     ▼
                   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
                   │    MySQL     │    │    Redis     │    │    MinIO     │
                   │   (数据库)    │    │   (缓存)     │    │  (文件存储)   │
                   └──────────────┘    └──────────────┘    └──────────────┘
```

### 资源消耗计算公式

#### 1. 内存需求计算

```
总内存 = Go后端 + MySQL + Redis + MinIO + Nginx + 系统预留

Go后端内存:
  基础内存 = 50MB
  每并发连接 = 2KB
  公式: 后端内存 = 50MB + (并发数 × 2KB)

MySQL内存:
  基础内存 = 512MB
  每连接内存 = 10MB (innodb_buffer_pool_size / max_connections)
  公式: MySQL内存 = 512MB + (连接数 × 10MB)

Redis内存:
  基础内存 = 64MB
  缓存数据 = 用户数 × 1KB (平均每用户缓存)
  公式: Redis内存 = 64MB + (用户数 × 1KB)

总内存公式:
  总内存 = (50MB + 并发×2KB) + (512MB + 连接×10MB) + (64MB + 用户×1KB) + 256MB(MinIO) + 64MB(Nginx) + 1GB(系统)
```

#### 2. CPU需求计算

```
Go后端CPU:
  基础 = 1核
  每1000并发 = +1核
  公式: 后端CPU = 1 + ceil(并发数 / 1000)

MySQL CPU:
  基础 = 1核
  每500 QPS = +1核
  公式: MySQL CPU = 1 + ceil(QPS / 500)

总CPU公式:
  总CPU = Go后端CPU + MySQL CPU + 1核(Redis+其他)
```

#### 3. 磁盘需求计算

```
数据库存储:
  每用户数据 = 10KB (用户表+关联数据)
  每首歌曲 = 5MB (音频文件) + 2KB (元数据)
  每条动态 = 1KB + 500KB (图片，平均3张)
  公式: 数据库存储 = 用户×10KB + 歌曲×5MB + 动态×500KB

日志存储:
  每天日志 = 100MB (基础) + 1MB/万请求
  公式: 日志存储 = 天数 × (100MB + 请求数/10000 × 1MB)

总磁盘公式:
  总磁盘 = 数据库存储 + 日志存储 + 备份空间(20%) + 系统(20GB)
```

#### 4. 带宽需求计算

```
API带宽:
  每请求平均 = 2KB (JSON响应)
  公式: API带宽 = 并发数 × 2KB × 8 / 1000 = Mbps

音频流带宽:
  每用户 = 128kbps (标准音质)
  公式: 音频带宽 = 同时在线听歌用户 × 128kbps / 1000 = Mbps

总带宽公式:
  总带宽 = API带宽 + 音频带宽 + 静态资源带宽(20%)
```

### 不同规模配置建议

#### 小型规模 (1,000用户，100并发)

| 组件 | CPU | 内存 | 磁盘 | 带宽 |
|------|-----|------|------|------|
| Go后端 | 2核 | 512MB | 20GB | 10Mbps |
| MySQL | 1核 | 1GB | 50GB | - |
| Redis | 1核 | 256MB | 5GB | - |
| MinIO | - | 256MB | 100GB | - |
| Nginx | 1核 | 128MB | 10GB | - |
| **总计** | **4核** | **2GB** | **185GB** | **10Mbps** |

**推荐配置**: 4核8GB云服务器 + 100GB SSD + 10Mbps带宽

**云服务参考**:
- 阿里云: ecs.c6.xlarge (4核8GB) ≈ ¥300/月
- 腾讯云: S5.MEDIUM4 (4核8GB) ≈ ¥280/月
- 华为云: c6.large.2 (4核8GB) ≈ ¥290/月

#### 中型规模 (10,000用户，1,000并发)

| 组件 | CPU | 内存 | 磁盘 | 带宽 |
|------|-----|------|------|------|
| Go后端 | 4核 | 2GB | 50GB | 50Mbps |
| MySQL | 2核 | 4GB | 200GB | - |
| Redis | 1核 | 1GB | 20GB | - |
| MinIO | 1核 | 1GB | 500GB | - |
| Nginx | 1核 | 256MB | 20GB | - |
| **总计** | **9核** | **8.25GB** | **790GB** | **50Mbps** |

**推荐配置**: 
- 方案A: 8核16GB云服务器 + 500GB SSD + 50Mbps (单机)
- 方案B: 2台4核8GB + RDS MySQL + 云Redis + OSS (分布式)

**云服务参考**:
- 阿里云: ecs.c6.2xlarge (8核16GB) ≈ ¥800/月 + RDS MySQL ≈ ¥400/月
- 腾讯云: S5.LARGE8 (8核16GB) ≈ ¥750/月 + 云数据库 ≈ ¥380/月

#### 大型规模 (100,000用户，10,000并发)

| 组件 | CPU | 内存 | 磁盘 | 带宽 |
|------|-----|------|------|------|
| Go后端 ×3 | 12核 | 6GB | 150GB | 200Mbps |
| MySQL主从 | 8核 | 16GB | 1TB | - |
| Redis集群 | 4核 | 8GB | 100GB | - |
| MinIO集群 | 4核 | 4GB | 5TB | - |
| Nginx ×2 | 4核 | 2GB | 50GB | - |
| **总计** | **32核** | **36GB** | **6.3TB** | **200Mbps** |

**推荐配置**:
- 3台8核16GB (Go后端集群)
- RDS MySQL高可用版 (8核32GB)
- 云Redis集群版 (4节点)
- OSS对象存储
- SLB负载均衡
- CDN加速

**云服务参考**:
- 阿里云: ≈ ¥5,000-8,000/月
- 腾讯云: ≈ ¥4,500-7,500/月

#### 超大规模 (1,000,000用户，50,000并发)

| 组件 | 数量 | 单机配置 | 总资源 |
|------|------|---------|--------|
| Go后端 | 5-10台 | 16核32GB | 80-160核, 160-320GB |
| MySQL | 主从+读写分离 | 16核64GB | 32核128GB |
| Redis | 集群6节点 | 8核32GB | 48核192GB |
| MinIO | 分布式集群 | 8核16GB | 随规模扩展 |
| Nginx/SLB | 2-3台 | 4核8GB | 负载均衡 |
| CDN | 全国节点 | - | 静态资源加速 |

**推荐架构**:
- Kubernetes集群部署
- 微服务拆分（用户服务、音乐服务、AI服务、社交服务）
- 数据库分库分表
- 消息队列（Kafka/RocketMQ）
- 分布式缓存
- 全链路监控

**云服务参考**: ≈ ¥30,000-80,000/月

### 关键配置参数

#### Go后端配置 (config.yaml)

```yaml
server:
  port: 8080
  mode: release

mysql:
  max_open_conns: 100      # 最大连接数 = CPU核数 × 2 + 磁盘数
  max_idle_conns: 20       # 空闲连接数 = max_open_conns / 5

redis:
  pool_size: 100           # 连接池大小 = 并发数 / 10
```

#### MySQL配置 (my.cnf)

```ini
[mysqld]
# 连接配置
max_connections = 500              # 最大连接数 = 预期并发 × 1.5
max_connect_errors = 100000        # 最大连接错误数

# InnoDB配置
innodb_buffer_pool_size = 4G       # 缓冲池 = 总内存 × 70%
innodb_log_file_size = 256M        # 日志文件大小
innodb_flush_log_at_trx_commit = 1 # 事务提交刷盘策略
innodb_flush_method = O_DIRECT     # 直接IO

# 查询缓存
query_cache_type = 0               # MySQL 8.0已移除
tmp_table_size = 64M               # 临时表大小
max_heap_table_size = 64M          # 内存表大小

# 慢查询
slow_query_log = 1
long_query_time = 1                # 慢查询阈值(秒)
```

#### Redis配置 (redis.conf)

```ini
# 内存配置
maxmemory 2gb                      # 最大内存 = 预期缓存数据 × 1.5
maxmemory-policy allkeys-lru       # 内存淘汰策略

# 连接配置
maxclients 10000                   # 最大连接数
timeout 300                        # 空闲超时(秒)

# 持久化
appendonly yes                     # AOF持久化
appendfsync everysec               # 每秒刷盘
```

### 性能优化建议

#### 1. 数据库优化

- 为常用查询字段添加索引
- 使用连接池，避免频繁创建连接
- 读写分离，主库写从库读
- 定期优化表和分析慢查询

#### 2. 缓存策略

```
缓存层级:
  L1: 进程内缓存 (热数据，5分钟过期)
  L2: Redis缓存 (温数据，1小时过期)
  L3: 数据库 (冷数据)

缓存Key设计:
  cache:{resource}:{id}:{version}
  例: cache:song:123:v1
```

#### 3. 并发处理

```go
// Go并发最佳实践
// 1. 使用goroutine池限制并发数
pool := make(chan struct{}, 1000)

// 2. 使用context控制超时
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

// 3. 使用sync.WaitGroup等待并发完成
var wg sync.WaitGroup
for _, task := range tasks {
    wg.Add(1)
    go func(t Task) {
        defer wg.Done()
        process(t)
    }(task)
}
wg.Wait()
```

#### 4. 限流配置

```yaml
# API限流规则
rate_limits:
  login: 5/分钟/IP         # 登录接口
  register: 10/分钟/IP     # 注册接口
  api: 100/分钟/用户       # 普通API
  ai: 2/分钟/用户          # AI创作接口
  upload: 10/分钟/用户     # 上传接口
```

### 监控指标

#### 关键指标

| 指标 | 正常范围 | 告警阈值 |
|------|---------|---------|
| API响应时间 | < 200ms | > 500ms |
| 错误率 | < 0.1% | > 1% |
| CPU使用率 | < 70% | > 85% |
| 内存使用率 | < 80% | > 90% |
| 数据库连接数 | < 80% | > 90% |
| Redis内存 | < 70% | > 85% |

#### 监控工具

- **Prometheus + Grafana**: 指标收集和可视化
- **ELK Stack**: 日志收集和分析
- **Sentry**: 错误追踪和报警
- **APM**: 应用性能监控

### 扩容策略

#### 水平扩容 (推荐)

```
扩容触发条件:
  - CPU使用率 > 70% 持续5分钟
  - 内存使用率 > 80% 持续5分钟
  - API响应时间 > 500ms 持续1分钟
  - 错误率 > 1% 持续1分钟

扩容步骤:
  1. 增加Go后端实例
  2. 更新负载均衡配置
  3. 健康检查通过后加入集群
```

#### 垂直扩容

```
扩容触发条件:
  - 数据库连接数接近上限
  - Redis内存接近上限
  - 单机资源不足

扩容步骤:
  1. 升级服务器配置
  2. 调整数据库/Redis参数
  3. 重启服务
```

### 成本估算

| 规模 | 月活用户 | 并发数 | 月成本(阿里云) | 月成本(腾讯云) |
|------|---------|--------|---------------|---------------|
| 小型 | 1,000 | 100 | ¥500-800 | ¥450-750 |
| 中型 | 10,000 | 1,000 | ¥2,000-3,500 | ¥1,800-3,200 |
| 大型 | 100,000 | 10,000 | ¥8,000-15,000 | ¥7,000-13,000 |
| 超大 | 1,000,000 | 50,000 | ¥50,000-100,000 | ¥45,000-90,000 |

> 注：以上为估算，实际成本取决于具体配置、流量峰值、存储需求等因素。

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 👥 贡献者

- **yuhao-jack** - 项目负责人

---

## 📞 联系方式

- 邮箱: yuhao@example.com
- 项目地址: https://gitee.com/yuhao-jack/aimusic-app

---

## 🙏 致谢

感谢以下开源项目:

- [Gin](https://github.com/gin-gonic/gin) - Go HTTP框架
- [GORM](https://gorm.io) - Go ORM框架
- [Flutter](https://flutter.dev) - 跨平台UI框架
- [GetX](https://pub.dev/packages/get) - Flutter状态管理
- [Vue.js](https://vuejs.org) - 渐进式JavaScript框架
- [Element Plus](https://element-plus.org) - Vue 3 UI组件库
