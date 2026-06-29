# AGENTS.md — aimusic-app


所有产出物（注释、文档、提案、任务描述）必须使用简体中文撰写。

# 编码前思考
    不要假设。不要隐藏困惑。呈现权衡。
    明确说明假设 — 如果不确定，询问而不是猜测
    呈现多种解释 — 当存在歧义时，不要默默选择
    适时提出异议 — 如果存在更简单的方法，说出来
    困惑时停下来 — 指出不清楚的地方并要求澄清
# 简洁优先
    用最少的代码解决问题。不要过度推测。在不牺牲质量的情况下优化简洁性,不要假设。不要隐藏困惑。
    每次交互中控制信息量（包括对话历史）重写冗长的内容使其简洁
    迭代，而不是从一开始就追求完美 
    任何重要决策/修订都必须有解释性注释或日志记录 
    逐步处理复杂任务，在每一步展示工作成果
    不要添加要求之外的功能
    不要为一次性代码创建抽象
    不要添加未要求的"灵活性"或"可配置性"
    不要为不可能发生的场景做错误处理
    如果 200 行代码可以写成 50 行，重写它
    检验标准： 资深工程师会觉得这过于复杂吗？如果是，简化。
# 目标驱动执行
**定义成功标准。循环验证直到达成。**

将指令式任务转化为可验证的目标：

| 不要这样做... | 转化为... |
|--------------|-----------------|
| "添加验证" | "为无效输入编写测试，然后让它们通过" |
| "修复 bug" | "编写重现 bug 的测试，然后让它通过" |
| "重构 X" | "确保重构前后测试都能通过" |

对于多步骤任务，说明一个简短的计划：

```
1. [步骤] → 验证: [检查]
2. [步骤] → 验证: [检查]
3. [步骤] → 验证: [检查]
```
# 注意事项
- 使用英文进行命名，包括仓库、文件、变量等
- 代码注释使用中文，方法、常量、接口、枚举、结构体机其字段、核心逻辑全部都需要中文    
- 不提供过多背景信息，除非特别要求
- 使用 git 进行版本控制，小步提交commit,每一步都要生成清晰的commit message,参照Conventional Commits标准。
- 不确定时，立即询问以澄清需求
- 不要改变现有技术栈、框架或库，除非被明确要求
- 不要在不必要的情况下引入新依赖 
# 项目目标
- 代码注释清晰,项目架构组织职责分明,项目结构稳定,设计思想统一,模块边界清晰,注重接口抽象
- 技术文档齐全，数据流转有迹可追
- 采用语义化版本控制，有明确的发布计划
- 全部采用TDD(测试驱动开发)模式进行开发
- 接口层依据功能特性进行划分，与具体语言框架解耦
- 核心业务逻辑与UI、框架、设备完全解耦
- 有明确的错误码定义
- 有统一的异常处理策略
- 有统一的日志规范
- 有清晰的请求、响应、事件、异常、数据模型分层模型定义



AI music creation platform: Go backend + Flutter mobile app + Vue admin panel.

## Architecture

```
aimusic-app/
├── backend/          # Go (Gin + GORM) — API server + async consumer
├── frontend/         # Flutter (GetX + Dio) — mobile/web app
├── admin/            # Vue 3 + Vite + Element Plus — admin dashboard
├── sql/              # DB init + migration scripts
├── docker-compose.yml # MySQL 8, Redis 7, MinIO
└── start.sh          # Interactive launcher menu
```

Two backend binaries share the same codebase:
- `main.go` → `aimusic-server` (HTTP API on :8080)
- `cmd/consumer/main.go` → `aimusic-consumer` (Redis Streams task worker)

## Quick Start

```bash
# Infrastructure
docker compose up -d mysql redis minio

# Backend (from backend/)
go run main.go                    # API server
go run cmd/consumer/main.go       # Task consumer (separate terminal)

# Frontend (from frontend/)
flutter pub get && flutter run

# Admin (from admin/)
npm install && npm run dev        # Dev server proxies /api → localhost:8080
```

## Backend Commands

```bash
cd backend

# Build both binaries
go build -o aimusic-server main.go
go build -o aimusic-consumer cmd/consumer/main.go

# Run all tests (uses in-memory SQLite, no DB needed)
go test ./...

# Run a single test file
go test ./internal/handler/ -run TestFunctionName

# Lint (if golangci-lint available)
golangci-lint run
```

## Testing Quirks (Backend)

- Tests use **SQLite in-memory** via `handler.SetupTestDB()` — no MySQL/Redis required
- `handler.SetupAuthTest()` creates a test user and returns `(userID, token)` for auth'd endpoint tests
- `handler.CleanupTestDB()` wipes all tables between tests
- Admin handler tests use `AdminJWTAuth` middleware — need admin token, not user token
- Test config fallback: if `config.AppConfig.JWT.Secret` is empty, test helper sets it to `"aimusic2024secretkey"`

## Frontend Commands

```bash
cd frontend

flutter pub get                    # Install deps
flutter analyze                    # Static analysis
flutter test                       # Run widget tests
flutter build apk                  # Android build
flutter build ios                  # iOS build
dart run build_runner build        # Regenerate JSON serializable models
```

## Key Config

- **Backend config**: `backend/configs/config.yaml` (viper loads from `./configs` or `../configs`)
- **API base path**: `/api/v1/` (public) and `/api/v1/` (JWT-protected) and `/api/admin/` (admin JWT)
- **Frontend base URL**: hardcoded in `frontend/lib/utils/http_util.dart` — `localhost:8080` (web), `192.168.3.23:8080` (mobile)
- **Admin proxy**: `admin/vite.config.js` proxies `/api` → `localhost:8080`
- **DB auto-migration**: runs on server startup in `main.go` (GORM AutoMigrate) — no manual migration step needed
- **Upload path**: `./uploads` served as static at `/uploads`

## API Structure

- Public routes: auth (login/register/reset), music browse, search, playlists, creator profiles
- Private routes (JWT): user profile, AI creation (lyric/song generation), music interactions, playlists CRUD, posts, voice clone, notifications
- Admin routes (`/api/admin/`): dashboard, user/song/comment/audit/post management, system config

## Conventions

- Go module: `github.com/yourname/aimusic-backend`
- Flutter package: `aimusic_app`
- State management: GetX (services registered in `main.dart` via `Get.put()`)
- HTTP responses: `{code: 0, data: ..., msg: ...}` — `code == 0` means success
- Error handling: frontend Dio interceptor rejects responses where `code != 0`
- Token refresh: frontend handles 401 → refresh token → retry automatically
- Chinese UI throughout — comments, error messages, and user-facing strings are in Chinese
