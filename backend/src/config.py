"""
PadosiPro Backend — Configuration
"""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # App
    app_name: str = "PadosiPro"
    app_version: str = "1.0.0"
    debug: bool = True
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"

    # Database
    database_url: str = "sqlite+aiosqlite:///./padosipro.db"

    # JWT
    jwt_secret_key: str = "CHANGE_ME_super_secret_jwt_key_minimum_32_chars"
    jwt_access_token_expire_minutes: int = 15
    jwt_refresh_token_expire_days: int = 7
    jwt_algorithm: str = "HS256"

    # OTP
    otp_expire_minutes: int = 10
    otp_max_attempts: int = 5
    otp_resend_cooldown_seconds: int = 30

    # Email
    smtp_host: str = "smtp.ethereal.email"
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = "noreply@padosipro.com"
    smtp_from_name: str = "PadosiPro"

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()
