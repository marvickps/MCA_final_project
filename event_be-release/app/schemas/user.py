from datetime import time
from pydantic import BaseModel, EmailStr, validator
from typing import Optional

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    confirmPassword: str
    phone: str
    role: int
    # termsAccepted: bool

    @validator("confirmPassword")
    def passwords_match(cls, v, values):
        if "password" in values and v != values["password"]:
            raise ValueError("Passwords do not match")
        return v

    # @validator("termsAccepted")
    # def terms_must_be_true(cls, v):
    #     if not v:
    #         raise ValueError("Terms must be accepted")
    #     return v
class UserSchema(BaseModel):
    user_id: int
    email: EmailStr
    phone: Optional[str]
    role_id: int
    username: str
    is_active: int

    class Config:
        from_attributes = True


class DefaultTimingRequest(BaseModel):
    day_start_time: Optional[time] = "09:00:00"
    place_duration: Optional[int] = 3600
    hotel_daytime_duration: Optional[int] = 7200
    hotel_night_duration: Optional[int] = 28800
    activity_duration: Optional[int] = 3600
    restaurant_duration: Optional[int] = 3600


class DefaultTimingData(BaseModel):
    day_start_time: time
    place_duration: int
    hotel_daytime_duration: int
    hotel_night_duration: int
    activity_duration: int
    restaurant_duration: int

class DefaultTimingResponse(BaseModel):
    status: str
    message: str
    data: Optional[DefaultTimingData]

