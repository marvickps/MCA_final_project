from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from core.database import get_db
from core.dependencies import get_session
from schemas.user import DefaultTimingRequest, DefaultTimingResponse
from models.user import User
from schemas.user import UserCreate
from schemas.auth import LoginRequest, LoginResponse
from services.user import add_default_timing, authenticate_user, create_user, get_default_timing, reset_password, update_default_timing
from core.auth import create_access_token
from core.email import save_otp, verify_otp, send_otp_email
from schemas.otp import OTPVerify

router = APIRouter(prefix="/api/users", tags=["users"])

@router.post(
    "/register",
    status_code=status.HTTP_201_CREATED,
    response_model=None
)
def register(
    user_in: UserCreate,
    otp_code: str,  # OTP code passed as a query parameter
    db: Session = Depends(get_db)
):
    # 1) Check for existing email in the User table
    existing_email = db.query(User).filter(User.email == user_in.email).first()
    if existing_email:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    existing_phone = db.query(User).filter(User.phone == user_in.phone).first()
    if existing_phone:
        raise HTTPException(
            status_code=400,
            detail="Phone number already registered"
        )
    # 2) Verify OTP
    is_valid = verify_otp(db, user_in.email, otp_code, "registration")
    if not is_valid:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired OTP"
        )
    
    # 3) Create and return
    try:
        new_user = create_user(db, user_in, verified=True)
        add_default_timing(new_user.user_id,None, db)
        return {"id": new_user.user_id, "email": new_user.email}
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

@router.post(
    "/login",
    response_model=LoginResponse,
    status_code=status.HTTP_200_OK
)
def login(creds: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, creds)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    # Create JWT with user_id in payload
    token_data = {"sub": str(user.user_id), "role_id": user.role_id}
    access_token = create_access_token(token_data)

    return {
        "access_token": access_token,
        "user_id": user.user_id,
        "role_id": user.role_id,
        "username": user.username,
        "email": user.email,
        "phone": user.phone
    }

@router.post("/login-with-otp", response_model=LoginResponse)
def login_with_otp(data: OTPVerify, db: Session = Depends(get_db)):
    # 1) Verify OTP
    is_valid = verify_otp(db, data.email, data.code, "login")
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired OTP"
        )
    
    # 2) Get user
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # 3) Create JWT
    token_data = {"sub": str(user.user_id), "role_id": user.role_id}
    access_token = create_access_token(token_data)
    
    return {
        "access_token": access_token,
        "user_id": user.user_id,
        "role_id": user.role_id,
        "username": user.username,
        "email": user.email,
        "phone": user.phone
    }

@router.post("/forgot-password")
def forgot_password(email: str, db: Session = Depends(get_db)):
    # 1) Check if email exists in the User table
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email not found"
        )
    
    # 2) Generate and send OTP
    otp_code = save_otp(db, email, "password_reset")
    email_sent = send_otp_email(email, otp_code, "password_reset")
    
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send password reset email"
        )
    
    return {"message": "Password reset OTP sent to your email"}

@router.post("/reset-password")
def reset_password_route(data: OTPVerify, new_password: str, db: Session = Depends(get_db)):
    # 1) Verify OTP
    is_valid = verify_otp(db, data.email, data.code, "password_reset")
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Invalid or expired OTP"
        )
    
    # 2) Reset password
    success = reset_password(db, data.email, new_password)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {"message": "Password reset successfully"}


@router.post('/add_default_timing/{user_id}', status_code=status.HTTP_201_CREATED)
def add_default_timing_api(user_id:int,payload: DefaultTimingRequest, db: Session = Depends(get_db)):
    try:
        return add_default_timing(user_id,payload, db)        
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add default values, {e}")
    

@router.get('/get_default_timing/{user_id}', status_code=status.HTTP_200_OK,)
async def get_default_timing_api(user_id:int, session: AsyncSession = Depends(get_session)):
    try:
        return await get_default_timing(user_id,session)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update default values, {e}")
      
     
@router.put('/update_default_timing/{setting_id}',status_code=status.HTTP_200_OK, response_model=DefaultTimingResponse)
def update_default_timing_api(setting_id:int,payload: DefaultTimingRequest, db: Session = Depends(get_db)):
    try:
        return update_default_timing(setting_id,payload,db)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update default values, {e}")
    
