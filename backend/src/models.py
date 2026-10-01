"""
PadosiPro Backend — SQLAlchemy Models
"""
import uuid
from datetime import datetime
from sqlalchemy import (
    Boolean, Column, DateTime, ForeignKey,
    Integer, String, Text, UniqueConstraint,
)
from sqlalchemy.orm import DeclarativeBase, relationship


def _new_uuid() -> str:
    return str(uuid.uuid4())


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=_new_uuid)
    email = Column(String, unique=True, nullable=False, index=True)
    phone_number = Column(String, nullable=True)
    name = Column(String, nullable=True)
    address = Column(Text, nullable=True)
    society = Column(String, nullable=True)       # Society / building
    flat_unit = Column(String, nullable=True)     # Flat / unit
    gate_notes = Column(Text, nullable=True)      # Gate entry notes
    business_name = Column(String, nullable=True)
    password_hash = Column(String, nullable=True)
    is_email_verified = Column(Boolean, default=False, nullable=False)
    is_profile_complete = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    otp_codes = relationship("OtpCode", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    selected_tasks = relationship("UserTask", back_populates="user", cascade="all, delete-orphan")
    requests = relationship("UserRequest", back_populates="user", cascade="all, delete-orphan")


class OtpCode(Base):
    __tablename__ = "otp_codes"

    id = Column(String, primary_key=True, default=_new_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    code_hash = Column(String, nullable=False)   # SHA-256 hash of 6-digit OTP
    expires_at = Column(DateTime, nullable=False)
    attempts = Column(Integer, default=0, nullable=False)
    used = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="otp_codes")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(String, primary_key=True, default=_new_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String, nullable=False, unique=True)  # SHA-256 of refresh token
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="refresh_tokens")


class Category(Base):
    __tablename__ = "categories"

    id = Column(String, primary_key=True, default=_new_uuid)
    name = Column(String, nullable=False)
    subtitle = Column(String, nullable=True)
    icon = Column(String, nullable=False)   # emoji or icon name
    is_coming_soon = Column(Boolean, default=False, nullable=False)
    order = Column(Integer, default=0)

    tasks = relationship("Task", back_populates="category")


class Task(Base):
    __tablename__ = "tasks"

    id = Column(String, primary_key=True, default=_new_uuid)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category_id = Column(String, ForeignKey("categories.id"), nullable=False, index=True)

    category = relationship("Category", back_populates="tasks")
    user_tasks = relationship("UserTask", back_populates="task", cascade="all, delete-orphan")


class UserTask(Base):
    __tablename__ = "user_tasks"

    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    task_id = Column(String, ForeignKey("tasks.id", ondelete="CASCADE"), primary_key=True)

    user = relationship("User", back_populates="selected_tasks")
    task = relationship("Task", back_populates="user_tasks")


class UserRequest(Base):
    __tablename__ = "user_requests"

    id = Column(String, primary_key=True, default=_new_uuid)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    category_name = Column(String, nullable=False)
    service_name = Column(String, nullable=False)
    timing = Column(String, nullable=False, default="Standard")  # Standard, Same day, Express, Scheduled
    notes = Column(Text, nullable=True)
    status = Column(String, nullable=False, default="We are looking at it")
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="requests")
