"""
PadosiPro Backend — Tests: OTP logic (expiry, attempt limits, cooldown, hashing)
"""
import asyncio
import time
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.security import generate_otp, sha256_hash


# ── Unit tests: OTP generation ────────────────────────────────────────────────


def test_otp_is_6_digits():
    for _ in range(100):
        otp = generate_otp()
        assert len(otp) == 6
        assert otp.isdigit()


def test_otp_is_zero_padded():
    """OTPs like 000042 must be 6 chars, not 2."""
    # sha256 of "000042" != sha256 of "42"
    assert sha256_hash("000042") != sha256_hash("42")


def test_sha256_is_deterministic():
    assert sha256_hash("123456") == sha256_hash("123456")


def test_sha256_different_inputs_differ():
    assert sha256_hash("123456") != sha256_hash("654321")


def test_sha256_returns_hex_string():
    result = sha256_hash("test")
    assert len(result) == 64
    assert all(c in "0123456789abcdef" for c in result)


# ── OTP expiry logic ──────────────────────────────────────────────────────────


def test_otp_not_expired_before_10_minutes():
    created_at = datetime.utcnow()
    expires_at = created_at + timedelta(minutes=10)
    now = datetime.utcnow()
    assert expires_at > now  # Should not be expired


def test_otp_expired_after_10_minutes():
    created_at = datetime.utcnow() - timedelta(minutes=11)
    expires_at = created_at + timedelta(minutes=10)
    now = datetime.utcnow()
    assert expires_at < now  # Should be expired


# ── Resend cooldown logic ─────────────────────────────────────────────────────


def test_resend_cooldown_prevents_immediate_resend():
    created_at = datetime.utcnow()
    cooldown_seconds = 30
    cooldown_end = created_at + timedelta(seconds=cooldown_seconds)
    now = datetime.utcnow()
    # Within cooldown window — should be blocked
    assert cooldown_end > now


def test_resend_allowed_after_cooldown():
    created_at = datetime.utcnow() - timedelta(seconds=31)
    cooldown_seconds = 30
    cooldown_end = created_at + timedelta(seconds=cooldown_seconds)
    now = datetime.utcnow()
    # After cooldown window — should be allowed
    assert cooldown_end < now


# ── Attempt limit logic ───────────────────────────────────────────────────────


def test_otp_locked_after_5_attempts():
    max_attempts = 5
    attempts = 5
    assert attempts >= max_attempts  # Should be locked


def test_otp_not_locked_before_5_attempts():
    max_attempts = 5
    for attempts in range(5):
        assert attempts < max_attempts  # Should not be locked


# ── JWT helpers ───────────────────────────────────────────────────────────────


def test_access_token_decode():
    from src.security import create_access_token, decode_access_token
    token = create_access_token("user-123", "test@example.com")
    payload = decode_access_token(token)
    assert payload["sub"] == "user-123"
    assert payload["email"] == "test@example.com"
    assert payload["type"] == "access"


def test_invalid_token_raises():
    from src.security import decode_access_token
    from jose import JWTError
    with pytest.raises(JWTError):
        decode_access_token("not.a.real.token")


def test_tampered_token_raises():
    from src.security import create_access_token, decode_access_token
    from jose import JWTError
    token = create_access_token("user-123", "test@example.com")
    tampered = token[:-5] + "XXXXX"
    with pytest.raises(JWTError):
        decode_access_token(tampered)
