from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from datetime import datetime
import enum

from schemas.resources.hotels.hotel_room import HotelRoomResponse

class HotelCategory(str, enum.Enum):
    NA = "N/A"
    three = "3"
    four = "4"
    five = "5"

class FoodType(str, enum.Enum):
    NA = "N/A"
    Veg = "Veg"
    NonVeg = "Non-Veg"
    Both = "Both"
    
class HotelBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255, description="Hotel name")
    place_id: str = Field(..., min_length=1, max_length=100, description="Google Place ID")
    address: Optional[str] = Field(None, description="Hotel address")
    food_type: FoodType
    category: HotelCategory
    special_view_info: Optional[str] = Field(None, max_length=255, description="Special view information")
    latitude: Optional[float] = Field(None, ge=-90, le=90, description="Latitude coordinate")
    longitude: Optional[float] = Field(None, ge=-180, le=180, description="Longitude coordinate")
    photo_url: Optional[str] = Field(None, max_length=1000, description="Hotel photo URL")
    google_rating: Optional[float] = Field(None, ge=0, le=5, description="Google rating (0-5)")
    is_active: bool = Field(default=True, description="Hotel active status")

class HotelCreate(BaseModel):
    place_id: str = Field(..., min_length=1, max_length=100)
    food_type: FoodType = FoodType.NA
    category: HotelCategory = HotelCategory.NA
    special_view_info: Optional[str] = Field(None, max_length=255)

class HotelUpdate(BaseModel):
    food_type: Optional[FoodType] = None
    category: Optional[HotelCategory] = None
    special_view_info: Optional[str] = Field(None, max_length=255)
    is_active: Optional[bool] = None

class HotelResponse(HotelBase):
    model_config = ConfigDict(from_attributes=True)

    hotel_id: int
    client_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    rooms: List[HotelRoomResponse] = Field(default_factory=list, description="List of hotel rooms")

# Simplified response schemas (without nested relationships)
class HotelSimpleResponse(HotelBase):
    model_config = ConfigDict(from_attributes=True)
    
    hotel_id: int
    client_id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

class HotelRoomWithHotelResponse(HotelRoomResponse):
    hotel: Optional[HotelSimpleResponse] = None