# ==============================================================================
# QueueLess FastAPI Service — Production Dockerfile
# ==============================================================================

# Build Stage
FROM python:3.13-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies into a wheel directory or virtualenv
COPY pyproject.toml .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    fastapi>=0.115.0 \
    uvicorn[standard]>=0.32.0 \
    pydantic>=2.10.0 \
    pydantic-settings>=2.6.0 \
    sqlalchemy[asyncio]>=2.0.36 \
    asyncpg>=0.30.0 \
    alembic>=1.14.0 \
    httpx>=0.28.0

# Runtime Stage
FROM python:3.13-slim AS runner

WORKDIR /app

# Install runtime libpq for asyncpg/Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed python packages from builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Create non-root unprivileged service user
RUN groupadd -r queueless && useradd -r -g queueless -d /app -s /sbin/nologin queueless

# Copy source code and migrations
COPY api /app/api
COPY openapi /app/openapi

RUN chown -R queueless:queueless /app

USER queueless

EXPOSE 8000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ENVIRONMENT=production

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1

CMD ["uvicorn", "api.app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
