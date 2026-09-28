from fastapi import APIRouter
from backend.api.health import router as health_router
from backend.api.v1.admin.routes import router as admin_router
from backend.api.v1.ai.routes import router as ai_router
from backend.api.v1.auth.routes import router as auth_router
from backend.api.v1.cases.routes import router as cases_router
from backend.api.v1.downloads.routes import router as downloads_router
from backend.api.v1.knowledge.routes import router as knowledge_router
from backend.api.v1.reports.routes import router as reports_router

api_v1_router = APIRouter()

# Register core endpoints
api_v1_router.include_router(health_router)
api_v1_router.include_router(auth_router, prefix="/auth", tags=["Auth"])
api_v1_router.include_router(cases_router, prefix="/cases", tags=["Cases"])
api_v1_router.include_router(ai_router, prefix="/ai", tags=["AI"])
api_v1_router.include_router(knowledge_router, prefix="/knowledge", tags=["Knowledge"])
api_v1_router.include_router(reports_router, prefix="/reports", tags=["Reports"])
api_v1_router.include_router(admin_router, prefix="/admin", tags=["Admin"])
api_v1_router.include_router(downloads_router, prefix="/downloads", tags=["Downloads"])
