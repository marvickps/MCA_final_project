from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from enum import Enum


class RateUnitEnum(str, Enum):
    PerKm = "Per KM"
    PerDay = "Per Day"

class VehicleCategoryEnum(str, Enum):
    Sedan = "Sedan"
    SUV = "SUV"
    Minibus = "Minibus"
    Bus = "Bus"

class DriverVehicleCreate(BaseModel):
    vehicle_name: str = Field(..., max_length=255)
    category: VehicleCategoryEnum
    is_ac: bool = True
    rate_unit: RateUnitEnum
    rate: Decimal = Field(..., gt=0)
    is_available: bool = True
    
    
class DriverVehicleResponse(BaseModel):
    id: int
    vehicle_name: str
    category: VehicleCategoryEnum
    is_ac: bool
    rate_unit: RateUnitEnum
    rate: Decimal
    is_available: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DriverReviewResponse(BaseModel):
    review_id: int
    driver_id: int
    user_id: int
    rating: int
    title: Optional[str]
    comment: Optional[str]
    driving_rating: Optional[int]
    is_visible: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
