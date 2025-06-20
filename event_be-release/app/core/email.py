import os
import smtplib
from email.message import EmailMessage
import random
import string
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from models.otp import OTP

# Email configuration settings
GMAIL_USERNAME = "rajdeepotpvedaion@gmail.com"
GMAIL_PASSWORD = "nloo ooey asqj clgx"
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 465

def generate_otp():
    """Generate a random 6-digit OTP"""
    return ''.join(random.choices(string.digits, k=6))

def save_otp(db: Session, email: str, purpose: str, expiry_minutes: int = 10):
    """Save a new OTP to the database"""
    # Generate a new OTP
    otp_code = generate_otp()
    
    # Set expiry time
    expires_at = datetime.utcnow() + timedelta(minutes=expiry_minutes)
    
    # Create OTP record
    new_otp = OTP(
        email=email,
        code=otp_code,
        purpose=purpose,
        expires_at=expires_at
    )
    
    # Save to database
    db.add(new_otp)
    db.commit()
    db.refresh(new_otp)
    
    return otp_code

def verify_otp(db: Session, email: str, code: str, purpose: str):
    """Verify if OTP is valid and not expired"""
    # Find the most recent unused OTP for this email and purpose
    otp = db.query(OTP).filter(
        OTP.email == email,
        OTP.code == code,
        OTP.purpose == purpose,
        OTP.is_used == 0,
        OTP.expires_at > datetime.utcnow()
    ).order_by(OTP.created_at.desc()).first()
    
    if not otp:
        return False
    
    # Mark as used
    otp.is_used = 1
    db.commit()
    
    return True

def send_email(to_email: str, subject: str, content: str):
    """Send an email using Gmail SMTP with SSL"""
    msg = EmailMessage()
    msg.set_content(content)
    msg["Subject"] = subject
    msg["From"] = GMAIL_USERNAME
    msg["To"] = to_email
    
    try:
        with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
            server.login(GMAIL_USERNAME, GMAIL_PASSWORD)
            server.send_message(msg)
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

def send_otp_email(email: str, otp: str, purpose: str):
    """Send OTP via email"""
    subject_mapping = {
        "registration": "Verify Your Email for Registration",
        "login": "Your Login OTP Code",
        "password_reset": "Password Reset OTP Code"
    }
    
    content_mapping = {
        "registration": f"Your email verification code is: {otp}. This code will expire in 10 minutes.",
        "login": f"Your login verification code is: {otp}. This code will expire in 10 minutes.",
        "password_reset": f"Your password reset code is: {otp}. This code will expire in 10 minutes."
    }
    
    subject = subject_mapping.get(purpose, "Your OTP Code")
    content = content_mapping.get(purpose, f"Your OTP code is: {otp}")
    
    return send_email(email, subject, content)