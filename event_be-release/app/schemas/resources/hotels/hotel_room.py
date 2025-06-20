from pydantic import BaseModel, Field, field_validator, validator
from typing import Optional
from decimal import Decimal
from datetime import datetime
from enum import Enum

# Assuming you have a RoomType enum defined somewhere
class RoomType(str, Enum):
    Single = "Single Seater"
    Double = "Double Seater"
    Triple = "Triple Seater"
    Family = "Family Room"


class HotelRoomBase(BaseModel):
    """Base schema for hotel room data"""
    room_type: RoomType = Field(..., description="Type of room")
    ac_count: int = Field(..., ge=0, description="Number of AC rooms")
    non_ac_count: int = Field(..., ge=0, description="Number of non-AC rooms")
    ac_rate_per_night: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2, description="AC room rate per night")
    non_ac_rate_per_night: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2, description="Non-AC room rate per night")
    is_available: bool = Field(default=True, description="Room availability status")

class HotelRoomCreate(HotelRoomBase):
    """Schema for creating a new hotel room"""
    pass

class HotelRoomUpdate(BaseModel):
    """Schema for updating hotel room data"""
    room_type: Optional[RoomType] = None
    ac_count: Optional[int] = Field(None, ge=0)
    non_ac_count: Optional[int] = Field(None, ge=0)
    ac_rate_per_night: Optional[Decimal] = Field(None, gt=0, max_digits=10, decimal_places=2)
    non_ac_rate_per_night: Optional[Decimal] = Field(None, gt=0, max_digits=10, decimal_places=2)
    is_available: Optional[bool] = None

class HotelRoomResponse(HotelRoomBase):
    """Schema for hotel room response data"""
    id: int
    hotel_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True