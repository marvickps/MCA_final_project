from sqlalchemy.orm import Session
from passlib.context import CryptContext
from fastapi import HTTPException, status
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession

from schemas.user import DefaultTimingData, DefaultTimingRequest, DefaultTimingResponse
from models.user import DefaultItineraryTiming
from models.user import User
from schemas.user import UserCreate
from schemas.auth import LoginRequest

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_user(db: Session, user_data: UserCreate, verified: bool = True):
    """Create a new user after verification"""
    if not verified:
        raise ValueError("Email not verified")
    
    hashed_password = get_password_hash(user_data.password)
    
    new_user = User(
        username=user_data.email.split('@')[0],  # Default username from email
        email=user_data.email,
        phone=user_data.phone,
        password_hash=hashed_password,
        role_id=user_data.role
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user

def authenticate_user(db: Session, login_data: LoginRequest):
    """Authenticate a user with email and password"""
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user:
        return False
    
    if not verify_password(login_data.password, user.password_hash):
        return False
    
    return user

def reset_password(db: Session, email: str, new_password: str):
    """Reset user password"""
    user = db.query(User).filter(User.email == email).first()
    if not user:
        return False
    
    user.password_hash = get_password_hash(new_password)
    db.commit()
    
    return True


def add_default_timing(user_id,payload, db):
    try:
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found for adding default timing")
        if payload is None:
            payload = DefaultTimingRequest()
        itinerary_settings = DefaultItineraryTiming(
                user_id=user_id,
                day_start_time = payload.day_start_time,
                place_duration = payload.place_duration,
                hotel_daytime_duration = payload.hotel_daytime_duration,
                hotel_night_duration = payload.hotel_night_duration,
                activity_duration = payload.activity_duration,
                restaurant_duration = payload.restaurant_duration,
            )
        db.add(itinerary_settings)
        db.commit()
        db.refresh(itinerary_settings)

        return {"message": "Default itinerary settings added successfully", "data": itinerary_settings}
       
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add default values, {e}")

async def get_default_timing(user_id: int, session: AsyncSession):
    """Get default itinerary timing settings for a user"""
    try:
        result = await session.execute(
            select(DefaultItineraryTiming).filter(DefaultItineraryTiming.user_id == user_id)
        )
        timing = result.scalar_one_or_none()
        if not timing:
            raise HTTPException(status_code=404, detail=f"Default setting not found for user ID = {user_id}")
        return timing
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch default values: {e}")

def update_default_timing(setting_id,payload,db):
    try:
        itinerary_settings = db.query(DefaultItineraryTiming).filter(DefaultItineraryTiming.setting_id == setting_id).first()
        if not itinerary_settings:
            raise HTTPException(status_code=404, detail="default timing details not found for setting id = {setting_id} not found")
  
        itinerary_settings.day_start_time = payload.day_start_time
        itinerary_settings.place_duration = payload.place_duration
        itinerary_settings.hotel_daytime_duration = payload.hotel_daytime_duration
        itinerary_settings.hotel_night_duration = payload.hotel_night_duration
        itinerary_settings.activity_duration = payload.activity_duration
        itinerary_settings.restaurant_duration = payload.restaurant_duration
        db.commit()
        db.refresh(itinerary_settings)

        response_data = DefaultTimingData(
            # user_id=itinerary_settings.user_id,
            day_start_time=itinerary_settings.day_start_time,
            place_duration=itinerary_settings.place_duration,
            hotel_daytime_duration=itinerary_settings.hotel_daytime_duration,
            hotel_night_duration=itinerary_settings.hotel_night_duration,
            activity_duration=itinerary_settings.activity_duration,
            restaurant_duration=itinerary_settings.restaurant_duration
        )

        return DefaultTimingResponse(
            status="success",
            message="Default values updated successfully",
            data=response_data
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update default values, {e}")
