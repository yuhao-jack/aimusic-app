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
