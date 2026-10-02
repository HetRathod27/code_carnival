from fastapi import FastAPI, status
from fastapi.responses import JSONResponse

from api.app.core.db import check_db_ready
from api.app.core.errors import register_error_handlers
from api.app.routers import admin, citizen, desk, officer

app = FastAPI(
    title="QueueLess API",
    version="1.0.0",
    description="Predict waiting time at government offices + remote virtual tokens",
)

# Register uniform error format
register_error_handlers(app)

# Include functional routers
app.include_router(citizen.router)
app.include_router(officer.router)
app.include_router(desk.router)
app.include_router(admin.router)


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
