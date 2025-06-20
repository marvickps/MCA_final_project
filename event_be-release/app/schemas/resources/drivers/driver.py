from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from enum import Enum

from schemas.resources.drivers.driver_vehicle import DriverVehicleCreate, DriverVehicleResponse


class DriverCreate(BaseModel):
    client_id: int
    user_id: int
    name: str = Field(..., max_length=255)
    dl_number: str = Field(..., max_length=100)
    dl_valid_until: date
    working_hours: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = Field(None, max_length=255)
    vehicles: List[DriverVehicleCreate] = []

    @validator('dl_valid_until')
    def validate_dl_expiry(cls, v):
        if v <= date.today():
            raise ValueError('DL expiry date must be in the future')
        return v

class DriverUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    dl_number: Optional[str] = Field(None, max_length=100)
    dl_valid_until: Optional[date] = None
    working_hours: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = Field(None, max_length=255)
    is_active: Optional[bool] = None


class DriverResponse(BaseModel):
    driver_id: int
    client_id: int
    user_id: int
    name: str
    dl_number: str
    dl_valid_until: date
    working_hours: Optional[str]
    description: Optional[str]
    review_score: Optional[float]
    review_count: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    vehicles: List[DriverVehicleResponse] = []

    class Config:
        from_attributes = True

