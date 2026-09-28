# NexAssist - Project Progress & Deployment Report

**Date:** 24 September 2026  
**Active Branch:** `dev` / `main` (Synced)  
**System Architecture:** FastAPI Async Backend (Python 3.13 on Render) + Cloud PostgreSQL (Supabase) + Flutter Web (Vercel) + Windows Desktop & Android + Google Gemini AI Integration

---

## 1. Executive Summary
The **NexAssist** (formerly AI IT Helpdesk) enterprise technical operations platform is fully rebranded, architected, and deployed across a production-grade cloud stack:
- **Cloud Database:** Supabase PostgreSQL with 9 Alembic tables and full demo seed data.
- **Cloud Backend:** FastAPI on Render (`https://nexassist-backend.onrender.com`) with in-process APScheduler ('The Sweep').
- **Cloud Frontend:** Flutter Web on Vercel (`https://nex-assist-five.vercel.app`) with the Calmdesk Mineral Design System.
- **Local Runners:** Windows Desktop C++ runner and Android physical device runner via ADB reverse bridge.

---

## 2. Key Accomplishments & Deliverables

### A. Cloud Infrastructure & Live Deployment
- **Supabase Cloud Database:**
  - Database schema created with 9 core tables migrated via Alembic (`teams`, `users`, `cases`, `slas`, `ai_triage_results`, `case_risk_assessments`, `escalation_events`, `knowledge_articles`, `messages`).
  - Seed script executed (`python -m backend.db.seed`) populating 6 role-based demo accounts, 4 enterprise teams, active cases, SLA policies, and SOP articles.
  - Storage bucket `attachments` initialized for case files.
- **Render Backend Web Service:**
  - Service configured on Python 3.13 with Gunicorn/Uvicorn worker.
  - Supabase connection pooling compatibility configured (`statement_cache_size=0` for asyncpg/pgBouncer).
  - Dynamic `DATABASE_URL` scheme auto-converter (`postgresql://` -> `postgresql+asyncpg://`).
  - Permissive CORS regex middleware allowing all `*.vercel.app` domains, `localhost:3000`, `localhost:8000`, and custom origins.
- **Vercel Frontend Web Deployment:**
  - Configured custom Flutter Web build script with `--dart-define=API_BASE_URL=$API_BASE_URL`.
  - Added `vercel.json` SPA rewrite rules for clean client-side routing.
  - Dynamic `AppConstants.defaultApiBaseUrl` and `candidateApiBaseUrls` extracting build-time environment variables.
  - Eliminated web-incompatible `dart:io` imports in favor of `http.ClientException` and 15s timeout.

### B. UI/UX Rebranding — Calmdesk Mineral Design System
- **Design Philosophy:** `#F7F6F3` calm mineral canvas, zero elevation, clean `#E3E1DC` borders, `#2D5BE3` cobalt primary accent, zero pure green.
- **Dual Typography System:** `Space Grotesk` for high-impact metric headers and navigation titles; `Public Sans` for readable body text and technical logs.
- **Comprehensive Screen Polish:** Overhauled Login, Executive Dashboard, Case Management, Case Detail (with Live Sweep SLA Progress), Knowledge Base (SOP articles), and Operational Insights.

---

## 3. Deployment Matrix & Live Endpoints

| Component | Platform / Host | Live URL / Target | Status |
|---|---|---|---|
| **Frontend Web** | Vercel | `https://nex-assist-five.vercel.app` | [x] Deployed |
| **Backend API** | Render | `https://nexassist-backend.onrender.com` | [x] Live |
| **API Health Check** | Render | `https://nexassist-backend.onrender.com/api/v1/health` | [x] Live |
| **Cloud Database** | Supabase | `aws-0-ap-southeast-1.pooler.supabase.com:6543` | [x] Seeded |
| **Desktop Client** | Windows C++ | `client/build/windows/runner/Release` | [x] Verified |
| **Mobile Client** | Android APK | `client/build/app/outputs/flutter-apk` | [x] Verified |

---

## 4. Demo Accounts & Verification Reference

| Role | Email | Password | Assigned Scope |
|---|---|---|---|
| **Admin** | `admin@ithelpdesk.com` | `AdminPassword123!` | Global administration, team & user management |
| **Manager** | `manager@ithelpdesk.com` | `ManagerPassword123!` | Queue triage, escalation overrides, SLA telemetry |
| **Operator (Pune)** | `operator.pune@ithelpdesk.com` | `OperatorPassword123!` | Pune hardware/network case handling |
| **Operator (BLR)** | `operator.blr@ithelpdesk.com` | `OperatorPassword123!` | Bengaluru cloud/identity case handling |
| **Knowledge Owner** | `knowledge.owner@ithelpdesk.com` | `KnowledgePassword123!` | SOP article curation & publishing |
| **Requester** | `requester@ithelpdesk.com` | `RequesterPassword123!` | Self-service portal & ticket submission |

---

## 5. Production Diagnostic Session — 24 September 2026

### A. Issue Detected
- **Symptom:** Vercel frontend (`https://nex-assist-five.vercel.app`) displayed `"Connection failed. Please verify the server is reachable."` on the login page.
- **Health Endpoint Response:** `{"status":"degraded","db":"error","environment":"local"}` — backend was live on Render but could not connect to Supabase database.

### B. Root Cause Analysis
| # | Finding | Severity |
|---|---|---|
| 1 | `DATABASE_URL` environment variable **missing** on Render. Only `SUPABASE_URL` (REST API URL) was set. Backend fell back to `localhost:5432` default, which doesn't exist on Render. | 🔴 Critical |
| 2 | `ENVIRONMENT` env var not set on Render — defaulted to `local`, causing 24h JWT expiry and skipped production startup validation. | 🟡 Medium |

### C. Resolution Plan
1. **Add `DATABASE_URL`** to Render Environment tab with Supabase **Session pooler** connection string (port `5432`).
2. **Add `SYNC_DATABASE_URL`** with the same connection string (backend auto-translates scheme for sync Alembic engine).
3. **Set `ENVIRONMENT=production`** on Render.
4. **Supabase project confirmed ACTIVE** — not paused (verified via Supabase Dashboard, project `hlbsbjqiuddvxqeamjft`).

### D. Pooler Migration Decision
- **Previous:** Transaction pooler (`port 6543`) documented in architecture.
- **Current:** Migrated to **Session pooler** (`port 5432`) per user preference — supports prepared statements natively. `statement_cache_size=0` retained in `session.py` for backward compatibility (no-op on Session pooler).

---

## 6. Frontend Dynamic Theming & UI/UX Polish — 24 September 2026

### A. Architectural Theming Refactor (Zero Hardcoded Colors)
- **Problem Statement:** Incomplete theme transitions where static constants (`AppColors.surface`, `AppColors.background`, `AppColors.textPrimary`, `AppColors.textSecondary`, etc.) prevented dark mode palette application on cards, modals, and list items.
- **Implementation:**
  - Implemented `AppThemeContextExtension` on `BuildContext` in [`client/lib/shared/constants/app_colors.dart`](file:///d:/NexAssist/client/lib/shared/constants/app_colors.dart):
    - `context.isDarkMode`: Resolves theme brightness dynamically.
    - `context.surfaceColor`: Switches between `#FFFFFF` (Light) and `#0F172A` (Dark).
    - `context.cardColor`: Switches between `#FFFFFF` (Light) and `#1E293B` (Dark).
    - `context.scaffoldBg`: Switches between `#FAFAFA` (Light) and `#0F172A` (Dark).
    - `context.textPrimary`: Switches between `#111827` (Light) and `#F8FAFC` (Dark).
    - `context.textSecondary`: Switches between `#4B5563` (Light) and `#94A3B8` (Dark).
    - `context.textTertiary`: Switches between `#9CA3AF` (Light) and `#64748B` (Dark).
    - `context.borderColor`: Switches between `#E5E7EB` (Light) and `#334155` (Dark).
    - `context.containerBg`: Switches between `#F9FAFB` (Light) and `#1E293B` (Dark).
    - `context.hoverBg`: Dynamic card and row hover backdrop.
  - Refactored all application screens to consume dynamic context tokens:
    - [`dashboard_screen.dart`](file:///d:/NexAssist/client/lib/features/dashboard/dashboard_screen.dart)
    - [`case_list_screen.dart`](file:///d:/NexAssist/client/lib/features/cases/case_list_screen.dart)
    - [`case_detail_screen.dart`](file:///d:/NexAssist/client/lib/features/cases/case_detail_screen.dart)
    - [`reports_screen.dart`](file:///d:/NexAssist/client/lib/features/reports/reports_screen.dart)
    - [`knowledge_screen.dart`](file:///d:/NexAssist/client/lib/features/knowledge/knowledge_screen.dart)
    - [`case_create_screen.dart`](file:///d:/NexAssist/client/lib/features/cases/case_create_screen.dart)
    - [`assign_dialog.dart`](file:///d:/NexAssist/client/lib/features/cases/assign_dialog.dart)
    - [`draft_dialog.dart`](file:///d:/NexAssist/client/lib/features/ai/draft_dialog.dart)
    - [`login_screen.dart`](file:///d:/NexAssist/client/lib/features/auth/login_screen.dart)
    - [`register_screen.dart`](file:///d:/NexAssist/client/lib/features/auth/register_screen.dart)

### B. Shell & Post-Login Theme Switcher
- **Login Shell Simplification:** Removed theme switcher icon from login view to keep initial authentication screen minimal, secure, and distraction-free.
- **Post-Login Integration:** Positioned Light/Dark mode switcher icon inside [`responsive_layout.dart`](file:///d:/NexAssist/client/lib/shared/widgets/responsive_layout.dart) on:
  - Desktop: Top Bar action tray.
  - Mobile: App Bar header.
  - Tablet: Navigation Rail trailing slot.
- **Smooth Toggle:** Interacts with `ThemeController` via `Provider`, triggering instantaneous animated theme transitions across all widgets.

### C. Motion & Liquid Glassmorphism
- **LiquidGlassPanel:** Adaptive translucent backdrop filters (`sigmaX: 12, sigmaY: 12`) rendering pristine white glass tint in Light mode and deep obsidian glass tint in Dark mode.
- **GSAP-style Choreography:** Micro-staggered `GSAPFadeSlide` animations and shimmer loaders (`GSAPShimmerLoader`) rendering on KPI cards, tables, and AI narrative summaries.
- **Zero Pure Green Compliance:** All success states, resolution badges, and match chips strictly utilize Slate-Teal (`#0D9488`).

### D. Quality Assurance & Validation
- `flutter analyze lib`: **0 issues found** (Clean).
- `flutter test`: **12/12 tests passed** (including Design System token compliance, model deserialization, widget interactions, responsive layout, and DownloadAppsDialog tests).
- Automated continuous delivery verified via Vercel GitHub integration on `main` branch.

---

## 7. Native App Downloads Delivery (.exe & .apk) — 28 September 2026

### A. Direct 1-Tap Client Downloads
- **Interactive UI Modal:** Built [`download_apps_dialog.dart`](file:///d:/NexAssist/client/lib/shared/widgets/download_apps_dialog.dart) featuring dedicated cards for:
  - **Windows Desktop Client (.exe):** `NexAssist-Setup.exe` (10.7 MB, 64-bit standalone installer).
  - **Android Mobile Package (.apk):** `NexAssist-Android.apk` (52.2 MB, ARM64 & x86_64 package).
- **Top-Right Header Access:**
  - Integrated a sleek `"Download Apps"` action trigger on the Top Global Bar in [`responsive_layout.dart`](file:///d:/NexAssist/client/lib/shared/widgets/responsive_layout.dart) for Desktop/Web.
  - Added dedicated download action buttons in Mobile AppBar and Tablet Navigation Rail.
  - Added quick-access download button in the top-right header tray of [`dashboard_screen.dart`](file:///d:/NexAssist/client/lib/features/dashboard/dashboard_screen.dart).

### B. Dual-Channel Static & API Distribution
- **Web Static Hosting:** Placed binaries in [`client/web/downloads/`](file:///d:/NexAssist/client/web/downloads) for direct, zero-proxy browser downloads on Vercel (`/downloads/NexAssist-Setup.exe` and `/downloads/NexAssist-Android.apk`).
- **Backend API Endpoints:** Implemented [`backend/api/v1/downloads/routes.py`](file:///d:/NexAssist/backend/api/v1/downloads/routes.py) with endpoints:
  - `GET /api/v1/downloads/info` (Metadata, file size, availability).
  - `GET /api/v1/downloads/windows` (FileResponse stream for `.exe`).
  - `GET /api/v1/downloads/android` (FileResponse stream for `.apk`).
- **Static Asset Mount:** Mounted `/static` directory in [`backend/main.py`](file:///d:/NexAssist/backend/main.py).

### C. Testing & Verification
- `flutter analyze lib`: **0 issues found** (Clean).
- `flutter test`: **12/12 tests passed** (including `download_apps_dialog_test.dart`).
- `pytest backend/tests/unit/test_downloads.py`: **3/3 passed**.

