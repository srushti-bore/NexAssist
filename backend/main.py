import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path

# Ensure root repository directory is on sys.path
root_dir = str(Path(__file__).resolve().parent.parent)
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.api.v1.router import api_v1_router
from backend.core.config import settings
from backend.core.exceptions import register_exception_handlers
from backend.scheduler.sweep import shutdown_scheduler, start_scheduler

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("it_helpdesk.main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle event handler for FastAPI startup and shutdown."""
    logger.info(f"Starting {settings.PROJECT_NAME} in [{settings.ENVIRONMENT}] mode...")
    
    # Validate environment variables per SRS §3.3
    settings.validate_startup_env()

    # Start in-process APScheduler for SLA/Risk sweeps per SRS §3.5
    start_scheduler()

    yield

    # Teardown logic
    logger.info("Shutting down scheduler...")
    shutdown_scheduler()
    logger.info("Application shutdown complete.")


def create_application() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title=settings.PROJECT_NAME,
        openapi_url=f"{settings.API_V1_STR}/openapi.json" if settings.DEBUG else None,
        docs_url=f"{settings.API_V1_STR}/docs" if settings.DEBUG else None,
        redoc_url=f"{settings.API_V1_STR}/redoc" if settings.DEBUG else None,
        lifespan=lifespan,
    )

    # Configure CORS (allow local dev, Vercel deployments, and custom configured origins)
    cors_origins = list(settings.ALLOWED_ORIGINS) if isinstance(settings.ALLOWED_ORIGINS, list) else []
    for origin in [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "http://localhost",
        "http://127.0.0.1",
        "https://nex-assist-five.vercel.app",
        "https://nexassist.vercel.app",
    ]:
        if origin not in cors_origins:
            cors_origins.append(origin)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$|^https://.*\.vercel\.app$",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register standard error envelope handlers per SRS §3.6
    register_exception_handlers(app)

    # Mount API v1 router
    app.include_router(api_v1_router, prefix=settings.API_V1_STR)

    # Mount static files if directory exists
    static_dir = Path(__file__).resolve().parent / "static"
    if static_dir.exists():
        from fastapi.staticfiles import StaticFiles
        app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

    return app


app = create_application()
