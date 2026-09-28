# NexAssist - Technical Debt & Architectural Resolutions

**Last Updated:** 24 September 2026  
**Status:** Managed / Production-Ready

---

## 1. Resolved Technical Debt

### A. Dynamic API Base URL for Web Deployments
- **Context:** Flutter Web compilation bakes `--dart-define` parameters at build time. Previously `AppConstants.defaultApiBaseUrl` was hardcoded to `http://localhost:8000/api/v1`, which caused browser security alerts on Vercel (`Access other devices on your local network`) and request timeouts.
- **Resolution:**
  1. Updated `AppConstants.defaultApiBaseUrl` to evaluate `const String.fromEnvironment('API_BASE_URL')` first.
  2. Isolated `AppConstants.candidateApiBaseUrls` so Web exclusively targets the configured production URL and skips local private network probes (`10.x.x.x` / `10.0.2.2`).
  3. Replaced `dart:io` in `ApiClient` with standard `http.ClientException` and 15s timeout to ensure 100% web-safe execution.

### B. Supabase PostgreSQL & pgBouncer Pooling Support
- **Context:** Supabase uses pgBouncer transaction poolers on port 6543, which reject named prepared statements from `asyncpg`. Additionally, standard Supabase connection strings use the `postgresql://` scheme instead of `postgresql+asyncpg://`.
- **Resolution:**
  1. Added `@field_validator` in `backend/core/config.py` to auto-translate `postgresql://` and `postgres://` into `postgresql+asyncpg://` for async SQLAlchemy engine and `postgresql://` for sync Alembic engine.
  2. Configured `connect_args={"statement_cache_size": 0}` in `backend/db/session.py` to disable prepared statement caching when using asyncpg with Supabase poolers.

### C. Cross-Origin Resource Sharing (CORS) on Render
- **Context:** Render backend initially allowed only localhost origins. Requests originating from `https://nex-assist-five.vercel.app` were blocked by browser pre-flight CORS checks.
- **Resolution:** Updated `CORSMiddleware` in `backend/main.py` with `allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$|^https://.*\.vercel\.app$"` to dynamically allow all current and future Vercel preview/production deployments.

### D. Missing DATABASE_URL on Render (Degraded Health)
- **Context:** After Render deployment, the backend health endpoint returned `{"status":"degraded","db":"error","environment":"local"}`. The Vercel frontend displayed "Connection failed. Please verify the server is reachable."
- **Root Cause:** Only `SUPABASE_URL` (REST API URL: `https://hlbsbjqiuddvxqeamjft.supabase.co`) was set on Render. The critical `DATABASE_URL` (direct PostgreSQL connection string) was missing, causing the backend to fall back to its default `localhost:5432` connection which doesn't exist on Render.
- **Resolution:**
  1. Add `DATABASE_URL` and `SYNC_DATABASE_URL` to Render Environment tab with Supabase Session pooler connection string.
  2. Set `ENVIRONMENT=production` to enable strict startup validation and 15-minute JWT expiry.

### E. Supabase Pooler Mode Migration (Transaction → Session)
- **Context:** Architecture originally documented Transaction pooler (`port 6543`). Transaction pooler rejects named prepared statements, requiring `statement_cache_size=0` workaround in `asyncpg`.
- **Resolution:** Migrated to **Session pooler** (`port 5432`) which natively supports prepared statements and provides per-connection session state. `statement_cache_size=0` retained in `backend/db/session.py` for backward compatibility — acts as a no-op on Session pooler and won't break anything.

### F. Hardcoded Static UI Colors vs. Dark Mode Switcher
- **Context:** Screens and widgets directly referenced static `AppColors` constants (`AppColors.surface`, `AppColors.background`, `AppColors.textPrimary`), which caused white backgrounds and dark text to persist when switching to Dark Mode.
- **Resolution:**
  1. Created `AppThemeContextExtension` on `BuildContext` with dynamic getters (`context.surfaceColor`, `context.cardColor`, `context.scaffoldBg`, `context.textPrimary`, `context.textSecondary`, `context.textTertiary`, `context.borderColor`, `context.containerBg`, `context.hoverBg`).
  2. Refactored all screens (`Dashboard`, `CaseList`, `CaseDetail`, `Reports`, `Knowledge`, `CaseCreate`, `AssignDialog`, `DraftDialog`, `Login`, `Register`) to consume dynamic context tokens.
  3. Eliminated all static hardcoded color dependencies.

### G. Clean Post-Login Theme Control
- **Context:** Theme mode toggle on the login page introduced unnecessary visual noise prior to authentication.
- **Resolution:** Removed mode toggle from the login card and placed it cleanly in the post-login application header, desktop top bar, mobile app bar, and tablet rail within `ResponsiveLayout`.

### H. Multiplatform Binary Distribution (.exe & .apk)
- **Context:** Users needed a functional, 1-tap download option for the standalone Windows desktop installer (`.exe`) and Android application (`.apk`) directly from the authenticated dashboard.
- **Resolution:**
  1. Generated release binaries: Windows installer `NexAssist-Setup.exe` (10.7 MB) and Android package `NexAssist-Android.apk` (52.2 MB).
  2. Placed static binaries in `client/web/downloads/` for direct, browser-native downloads on Vercel.
  3. Implemented backend stream endpoints (`/api/v1/downloads/windows`, `/api/v1/downloads/android`, and `/api/v1/downloads/info`) in FastAPI.
  4. Built `DownloadAppsDialog` interactive modal and linked it to the top-right header tray across Desktop Top Bar, Mobile AppBar, Tablet Rail, and Dashboard Screen header.

---

## 2. Active Technical Debt & Planned Improvements

| Area | Item | Impact | Recommended Resolution |
|---|---|---|---|
| **Storage** | Supabase Storage Attachment Upload | Low | Complete multi-part file upload direct to Supabase Storage S3 bucket instead of memory buffer. |
| **Scheduler** | Multi-Worker Sweep Locking | Medium | Add `SELECT FOR UPDATE SKIP LOCKED` on case SLA queries if scaling backend horizontally to multiple Render instances. |
| **Realtime** | WebSocket Case Updates | Low | Add Supabase Realtime / WebSocket stream to replace 30-second polling for active case queues. |
| **Cache** | Redis Layer | Low | Optional Redis instance for token blacklisting and high-frequency knowledge base query caching. |
| **Env Config** | Render Env Var Audit | Low | Periodically verify all required env vars (`DATABASE_URL`, `SYNC_DATABASE_URL`, `ENVIRONMENT`, `SECRET_KEY`, `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_KEY`) are set and valid on Render dashboard. |

