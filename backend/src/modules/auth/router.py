"""
PadosiPro Backend — Auth module: schemas, service, router
"""
import logging
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request
from pydantic import BaseModel, EmailStr, Field, model_validator
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from ...config import get_settings
from ...database import get_db
from ...mailer import send_otp_email
from ...models import OtpCode, RefreshToken, User
from ...responses import created, error, ok
from ...security import (
    create_access_token,
    create_refresh_token,
    decode_access_token,
    generate_otp,
    generate_token,
    hash_password,
    sha256_hash,
    verify_password,
)

logger = logging.getLogger(__name__)
settings = get_settings()

router = APIRouter(prefix="/auth", tags=["auth"])


# ── Pydantic schemas ─────────────────────────────────────────────────────────


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    confirm_password: str = Field(..., min_length=8)
    phone_number: str | None = Field(None, min_length=10, max_length=15, pattern=r"^\+?[0-9]{10,15}$")

    @model_validator(mode="after")
    def passwords_match(self):
        if self.password != self.confirm_password:
            raise ValueError("Passwords do not match")
        return self


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)


class SendOtpRequest(BaseModel):
    phone_number: str | None = Field(None, min_length=10, max_length=15, pattern=r"^\+?[0-9]{10,15}$")
    email: EmailStr


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


# ── Helpers ──────────────────────────────────────────────────────────────────


async def _get_or_create_user(db: AsyncSession, email: str, phone: str | None = None) -> User:
    """Return existing user or create a new unverified one."""
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(email=email, phone_number=phone)
        db.add(user)
        await db.flush()  # assigns id
    elif phone and user.phone_number != phone:
        user.phone_number = phone
    return user


async def _invalidate_old_otps(db: AsyncSession, user_id: str) -> None:
    """Mark all existing OTPs for the user as used."""
    await db.execute(
        delete(OtpCode).where(OtpCode.user_id == user_id, OtpCode.used == False)  # noqa: E712
    )


async def _issue_tokens(db: AsyncSession, user: User) -> dict:
    """Create and persist access + refresh tokens, return them."""
    # Purge expired refresh tokens for this user
    now = datetime.now(timezone.utc)
    await db.execute(
        delete(RefreshToken).where(
            RefreshToken.user_id == user.id,
            RefreshToken.expires_at < now,
        )
    )

    raw_refresh = create_refresh_token(user.id)
    refresh_hash = sha256_hash(raw_refresh)
    expire = now + timedelta(days=settings.jwt_refresh_token_expire_days)

    db_refresh = RefreshToken(
        user_id=user.id,
        token_hash=refresh_hash,
        expires_at=expire,
    )
    db.add(db_refresh)

    access = create_access_token(user.id, user.email)
    return {
        "access_token": access,
        "refresh_token": raw_refresh,
        "token_type": "bearer",
    }


# ── Auth middleware helper (used by other modules) ───────────────────────────


async def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
    db: AsyncSession = Depends(get_db),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        from fastapi import HTTPException
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    token = authorization.split(" ", 1)[1]
    try:
        payload = decode_access_token(token)
        user_id: str = payload["sub"]
    except Exception:
        from fastapi import HTTPException
        raise HTTPException(status_code=401, detail="Invalid or expired access token")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        from fastapi import HTTPException
        raise HTTPException(status_code=401, detail="User not found")
    return user


# ── Routes ───────────────────────────────────────────────────────────────────


@router.post("/register")
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Register user with email and password (bcrypt).
    Sends a 6-digit OTP to email for verification.
    """
    email = body.email.lower().strip()
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if user and user.is_email_verified:
        return error("USER_ALREADY_EXISTS", "An account with this email already exists. Please log in.", 400)

    hashed_pw = hash_password(body.password)

    if user is None:
        user = User(
            email=email,
            password_hash=hashed_pw,
            phone_number=body.phone_number,
        )
        db.add(user)
        await db.flush()
    else:
        user.password_hash = hashed_pw
        if body.phone_number:
            user.phone_number = body.phone_number

    await _invalidate_old_otps(db, user.id)
    otp = generate_otp()
    otp_hash = sha256_hash(otp)
    expires_at = datetime.utcnow() + timedelta(minutes=settings.otp_expire_minutes)

    db_otp = OtpCode(user_id=user.id, code_hash=otp_hash, expires_at=expires_at)
    db.add(db_otp)
    await db.commit()

    try:
        await send_otp_email(email, otp, user.name or "")
    except Exception as e:
        logger.error(f"Email send failed: {e}")
        return error("EMAIL_SEND_FAILED", "Failed to send OTP email. Please try again.", 500)

    return created({"email": email, "is_email_verified": False}, "Registration successful. Please verify your email with the OTP.")


@router.post("/login")
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Login for returning users with email and password.
    If email is unverified, dispatches a new OTP and requires verification.
    """
    email = body.email.lower().strip()
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.password_hash):
        return error("INVALID_CREDENTIALS", "Invalid email or password.", 401)

    if not user.is_email_verified:
        await _invalidate_old_otps(db, user.id)
        otp = generate_otp()
        otp_hash = sha256_hash(otp)
        expires_at = datetime.utcnow() + timedelta(minutes=settings.otp_expire_minutes)
        db_otp = OtpCode(user_id=user.id, code_hash=otp_hash, expires_at=expires_at)
        db.add(db_otp)
        await db.commit()

        try:
            await send_otp_email(email, otp, user.name or "")
        except Exception:
            pass

        return error(
            "EMAIL_NOT_VERIFIED",
            "Please verify your email before logging in. A new OTP has been sent.",
            403,
            data={"email": email, "needs_verification": True},
        )

    tokens = await _issue_tokens(db, user)
    await db.commit()

    return ok(
        {
            **tokens,
            "user": _user_dict(user),
            "is_profile_complete": user.is_profile_complete,
        },
        "Logged in successfully.",
    )


@router.post("/send-otp")
async def send_otp(body: SendOtpRequest, db: AsyncSession = Depends(get_db)):
    """
    Given email (+ optional phone), send a 6-digit OTP to email.
    Creates user if not exists.
    """
    email = body.email.lower().strip()
    phone = body.phone_number.strip() if body.phone_number else None

    user = await _get_or_create_user(db, email, phone)

    # ── Resend cooldown check ────────────────────────────────────────────────
    result = await db.execute(
        select(OtpCode)
        .where(OtpCode.user_id == user.id, OtpCode.used == False)  # noqa: E712
        .order_by(OtpCode.created_at.desc())
        .limit(1)
    )
    latest_otp = result.scalar_one_or_none()
    if latest_otp:
        cooldown_end = latest_otp.created_at + timedelta(seconds=settings.otp_resend_cooldown_seconds)
        # Make both naive UTC for comparison
        now_naive = datetime.utcnow()
        if cooldown_end > now_naive:
            seconds_left = int((cooldown_end - now_naive).total_seconds())
            return error(
                "RESEND_COOLDOWN",
                f"Please wait {seconds_left} seconds before requesting a new OTP.",
            )

    # ── Invalidate old OTPs ──────────────────────────────────────────────────
    await _invalidate_old_otps(db, user.id)

    # ── Generate new OTP ─────────────────────────────────────────────────────
    otp = generate_otp()
    otp_hash = sha256_hash(otp)
    expires_at = datetime.utcnow() + timedelta(minutes=settings.otp_expire_minutes)

    db_otp = OtpCode(user_id=user.id, code_hash=otp_hash, expires_at=expires_at)
    db.add(db_otp)
    await db.commit()

    # ── Send email ───────────────────────────────────────────────────────────
    try:
        await send_otp_email(email, otp, user.name or "")
    except Exception as e:
        logger.error(f"Email send failed: {e}")
        return error("EMAIL_SEND_FAILED", "Failed to send OTP email. Please try again.", 500)

    return ok({"email": email}, "OTP sent to your email address.")


@router.post("/verify-otp")
async def verify_otp(body: VerifyOtpRequest, db: AsyncSession = Depends(get_db)):
    """
    Verify the 6-digit OTP. On success, mark email verified and return JWT tokens.
    """
    email = body.email.lower().strip()

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if user is None:
        return error("USER_NOT_FOUND", "No account found for this email.", 404)

    # ── Find valid OTP ───────────────────────────────────────────────────────
    result = await db.execute(
        select(OtpCode)
        .where(OtpCode.user_id == user.id, OtpCode.used == False)  # noqa: E712
        .order_by(OtpCode.created_at.desc())
        .limit(1)
    )
    otp_record = result.scalar_one_or_none()

    if otp_record is None:
        return error("OTP_NOT_FOUND", "No active OTP found. Please request a new one.")

    now = datetime.utcnow()
    if otp_record.expires_at < now:
        otp_record.used = True
        await db.commit()
        return error("OTP_EXPIRED", "This OTP has expired. Please request a new one.")

    if otp_record.attempts >= settings.otp_max_attempts:
        otp_record.used = True
        await db.commit()
        return error(
            "OTP_MAX_ATTEMPTS",
            "Too many incorrect attempts. Please request a new OTP.",
        )

    # ── Verify the hash ──────────────────────────────────────────────────────
    if sha256_hash(body.otp) != otp_record.code_hash:
        otp_record.attempts += 1
        remaining = settings.otp_max_attempts - otp_record.attempts
        await db.commit()
        return error(
            "OTP_INVALID",
            f"Incorrect OTP. {remaining} attempt(s) remaining.",
        )

    # ── Mark verified ────────────────────────────────────────────────────────
    otp_record.used = True
    user.is_email_verified = True
    await db.flush()

    tokens = await _issue_tokens(db, user)
    await db.commit()

    return ok(
        {
            **tokens,
            "user": _user_dict(user),
            "is_profile_complete": user.is_profile_complete,
        },
        "Email verified. Logged in successfully.",
    )


@router.post("/refresh")
async def refresh_token(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    """Rotate refresh token — revoke old, issue new pair."""
    token_hash = sha256_hash(body.refresh_token)
    now = datetime.now(timezone.utc)
    now_naive = datetime.utcnow()

    result = await db.execute(
        select(RefreshToken).where(
            RefreshToken.token_hash == token_hash,
            RefreshToken.expires_at > now_naive,
        )
    )
    db_token = result.scalar_one_or_none()
    if db_token is None:
        return error("INVALID_REFRESH_TOKEN", "Refresh token is invalid or expired.", 401)

    user_result = await db.execute(select(User).where(User.id == db_token.user_id))
    user = user_result.scalar_one_or_none()
    if user is None:
        return error("USER_NOT_FOUND", "User not found.", 401)

    # Revoke old token
    await db.delete(db_token)
    tokens = await _issue_tokens(db, user)
    await db.commit()

    return ok(tokens, "Tokens refreshed.")


@router.post("/logout")
async def logout(body: LogoutRequest, db: AsyncSession = Depends(get_db)):
    """Revoke the refresh token."""
    token_hash = sha256_hash(body.refresh_token)
    await db.execute(
        delete(RefreshToken).where(RefreshToken.token_hash == token_hash)
    )
    await db.commit()
    return ok(message="Logged out successfully.")


@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    """Return the current authenticated user."""
    return ok(_user_dict(current_user))


# ── Private helpers ───────────────────────────────────────────────────────────


def _user_dict(user: User) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "phone_number": user.phone_number,
        "name": user.name,
        "address": user.address,
        "society": user.society,
        "flat_unit": user.flat_unit,
        "gate_notes": user.gate_notes,
        "business_name": user.business_name,
        "is_email_verified": user.is_email_verified,
        "is_profile_complete": user.is_profile_complete,
        "created_at": user.created_at.isoformat() if user.created_at else None,
    }
