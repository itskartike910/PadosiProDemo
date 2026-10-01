"""
PadosiPro Backend — Email sender (aiosmtplib)

Dev mode (no SMTP credentials):
  • OTP is printed clearly to the server console — copy-paste it to test
  • No external services needed during development

Gmail SMTP setup (free, 5 min):
  1. Enable 2-Step Verification on your Google account
  2. Go to https://myaccount.google.com/apppasswords
  3. Create an app password → copy the 16-char password
  4. In .env:
       SMTP_HOST=smtp.gmail.com
       SMTP_PORT=587
       SMTP_USERNAME=your@gmail.com
       SMTP_PASSWORD=xxxx xxxx xxxx xxxx
       SMTP_FROM_EMAIL=your@gmail.com
       SMTP_FROM_NAME=PadosiPro
"""
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import aiosmtplib

from .config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


async def send_otp_email(to_email: str, otp: str, user_name: str = "") -> None:
    """Send OTP email. Falls back to console log if SMTP not configured."""
    greeting = f"Hi {user_name}," if user_name else "Hello,"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background: #F5F0E8; margin: 0; padding: 0; }}
        .container {{ max-width: 480px; margin: 40px auto; background: #fff; border-radius: 16px;
                      box-shadow: 0 4px 24px rgba(0,0,0,0.08); overflow: hidden; }}
        .header {{ background: #3D7A6B; padding: 32px; text-align: center; }}
        .header h1 {{ color: #fff; font-size: 28px; margin: 0; letter-spacing: -0.5px; }}
        .header p  {{ color: rgba(255,255,255,0.8); margin: 4px 0 0; font-size: 14px; }}
        .body {{ padding: 32px; }}
        .otp-box {{ background: #F5F0E8; border-radius: 12px; padding: 24px;
                    text-align: center; margin: 24px 0; }}
        .otp {{ font-size: 42px; font-weight: 800; letter-spacing: 10px;
                color: #3D7A6B; font-family: monospace; }}
        .note {{ color: #888; font-size: 13px; margin-top: 8px; }}
        .footer {{ text-align: center; padding: 16px; color: #aaa; font-size: 12px;
                   border-top: 1px solid #eee; }}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PadosiPro</h1>
          <p>Your Lifestyle Manager</p>
        </div>
        <div class="body">
          <p>{greeting}</p>
          <p>Use the code below to verify your email address. This code is valid for
             <strong>10 minutes</strong> and can only be used once.</p>
          <div class="otp-box">
            <div class="otp">{otp}</div>
            <div class="note">Do not share this code with anyone.</div>
          </div>
          <p>If you didn't request this, please ignore this email.</p>
        </div>
        <div class="footer">PadosiPro · Lifestyle Management · India</div>
      </div>
    </body>
    </html>
    """

    text_body = f"{greeting}\n\nYour PadosiPro OTP is: {otp}\n\nValid for 10 minutes. Do not share."

    # ── Always print OTP to console for easy dev testing ─────────────────────
    logger.warning(
        "\n" + "=" * 50 +
        f"\n  📬  OTP for {to_email}"
        f"\n  🔐  Code: {otp}"
        "\n" + "=" * 50
    )

    # ── Dev mode: no SMTP configured ─────────────────────────────────────────
    if not settings.smtp_username:
        logger.info("ℹ️  No SMTP configured. OTP printed above. "
                    "Set SMTP_USERNAME in .env to send real emails.")
        return

    # ── Production: send via SMTP ─────────────────────────────────────────────
    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"{otp} is your PadosiPro verification code"
    msg["From"]    = f"{settings.smtp_from_name} <{settings.smtp_from_email}>"
    msg["To"]      = to_email

    msg.attach(MIMEText(text_body, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            username=settings.smtp_username,
            password=settings.smtp_password,
            start_tls=True,
        )
        logger.info(f"✅ OTP email sent to {to_email}")
    except Exception as e:
        logger.error(f"❌ Failed to send OTP email to {to_email}: {e}")
        raise
