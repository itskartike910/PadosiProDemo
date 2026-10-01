"""
PadosiPro Backend — Integration tests: auth & request endpoints
"""
import uuid
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport

from src.main import app


@pytest_asyncio.fixture
async def client():
    """Create an async test client."""
    from src.database import create_tables
    await create_tables()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.asyncio
async def test_send_otp_creates_user(client: AsyncClient):
    email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    response = await client.post("/api/v1/auth/send-otp", json={
        "phone_number": "+919876543210",
        "email": email,
    })
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "OTP sent" in data["message"]


@pytest.mark.asyncio
async def test_send_otp_invalid_email(client: AsyncClient):
    response = await client.post("/api/v1/auth/send-otp", json={
        "phone_number": "+919876543210",
        "email": "not-an-email",
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_send_otp_invalid_phone(client: AsyncClient):
    response = await client.post("/api/v1/auth/send-otp", json={
        "phone_number": "123",
        "email": "test@example.com",
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_register_and_login_flow(client: AsyncClient):
    email = f"reg_{uuid.uuid4().hex[:8]}@example.com"
    password = "StrongPassword123"

    # 1. Register with email & password
    reg_res = await client.post("/api/v1/auth/register", json={
        "email": email,
        "password": password,
        "confirm_password": password,
    })
    assert reg_res.status_code == 201
    assert reg_res.json()["data"]["is_email_verified"] is False

    # 2. Login before verification should be blocked with 403
    unverified_res = await client.post("/api/v1/auth/login", json={
        "email": email,
        "password": password,
    })
    assert unverified_res.status_code == 403
    assert unverified_res.json()["error"]["code"] == "EMAIL_NOT_VERIFIED"


@pytest.mark.asyncio
async def test_register_mismatched_password(client: AsyncClient):
    response = await client.post("/api/v1/auth/register", json={
        "email": "mismatch@example.com",
        "password": "Password123",
        "confirm_password": "DifferentPassword123",
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_invalid_credentials(client: AsyncClient):
    response = await client.post("/api/v1/auth/login", json={
        "email": "nonexistent@example.com",
        "password": "WrongPassword123",
    })
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "INVALID_CREDENTIALS"


@pytest.mark.asyncio
async def test_verify_otp_wrong_user(client: AsyncClient):
    response = await client.post("/api/v1/auth/verify-otp", json={
        "email": f"nobody_{uuid.uuid4().hex[:6]}@example.com",
        "otp": "123456",
    })
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "USER_NOT_FOUND"


@pytest.mark.asyncio
async def test_verify_otp_invalid_format(client: AsyncClient):
    response = await client.post("/api/v1/auth/verify-otp", json={
        "email": "test@example.com",
        "otp": "12345",  # 5 digits
    })
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_logout_with_invalid_token(client: AsyncClient):
    response = await client.post("/api/v1/auth/logout", json={
        "refresh_token": "totally-fake-token",
    })
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_get_tasks_returns_categories(client: AsyncClient):
    response = await client.get("/api/v1/tasks")
    assert response.status_code == 200
    assert response.json()["success"] is True
    categories = response.json()["data"]
    assert len(categories) >= 4
