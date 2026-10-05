from contextlib import asynccontextmanager

from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from api.app.core.config import settings
from api.app.core.db import check_db_ready
from api.app.core.errors import register_error_handlers
from api.app.routers import admin, citizen, desk, internal, officer, v1_core


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Production security guard: DevAuth is strictly forbidden in production
    if settings.ENVIRONMENT == "production":
        raise RuntimeError("CRITICAL SECURITY ERROR: DevAuth and dev endpoints cannot run in ENVIRONMENT=production")
    yield


app = FastAPI(
    title="QueueLess API",
    version="1.0.0",
    description="Predict waiting time at government offices + remote virtual tokens",
    lifespan=lifespan,
)

# Register uniform error format
register_error_handlers(app)

# Allow CORS for web and mobile clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include functional routers
app.include_router(citizen.router)
app.include_router(officer.router)
app.include_router(desk.router)
app.include_router(admin.router)
app.include_router(internal.router)
app.include_router(v1_core.router)


@app.get("/healthz", status_code=status.HTTP_200_OK, tags=["System"])
async def healthz() -> dict[str, str]:
    """Liveness probe: verifies process is alive."""
    return {"status": "ok"}


@app.get("/readyz", tags=["System"])
async def readyz() -> JSONResponse:
    """Readiness probe: verifies database connectivity."""
    is_ready = await check_db_ready()
    if is_ready:
        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ready"})
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"status": "unhealthy", "reason": "database unreachable"},
    )
