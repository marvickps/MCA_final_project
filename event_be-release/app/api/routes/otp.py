from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.database import get_db
from schemas.otp import OTPRequest, OTPVerify, OTPResponse
from core.email import save_otp, verify_otp, send_otp_email

router = APIRouter(prefix="/api/otp", tags=["otp"])

@router.post("/generate", response_model=OTPResponse)
def generate_otp_route(request: OTPRequest, purpose: str, db: Session = Depends(get_db)):
    """Generate and send OTP for various purposes"""
    if purpose not in ["registration", "login", "password_reset"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP purpose"
        )
    
    try:
        # Generate and save OTP
        otp_code = save_otp(db, request.email, purpose)
        
        # Send OTP via email
        email_sent = send_otp_email(request.email, otp_code, purpose)
        
        if not email_sent:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send OTP email"
            )
        
        return {
            "message": "OTP sent successfully to your email",
            "success": True
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating OTP: {str(e)}"
        )

@router.post("/verify", response_model=OTPResponse)
def verify_otp_route(data: OTPVerify, purpose: str, db: Session = Depends(get_db)):
    """Verify OTP for various purposes"""
    if purpose not in ["registration", "login", "password_reset"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid OTP purpose"
        )
    
    is_valid = verify_otp(db, data.email, data.code, purpose)
    
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP"
        )
    
    return {
        "message": "OTP verified successfully",
        "success": True
    }