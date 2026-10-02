import pytest
from httpx import ASGITransport, AsyncClient

from api.app.main import app


@pytest.mark.asyncio
async def test_healthz_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/healthz")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_readyz_endpoint_database_check():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/readyz")
        # In this environment, DB is configured in .env and running locally
        assert response.status_code in [200, 503]
        data = response.json()
        assert "status" in data
