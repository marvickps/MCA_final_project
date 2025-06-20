from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import date, datetime
from decimal import Decimal
from enum import Enum

class DriverReviewCreate(BaseModel):
    driver_id: int
    user_id: int
    rating: int = Field(..., ge=1, le=5)
    title: Optional[str] = Field(None, max_length=200)
    comment: Optional[str] = None
    driving_rating: Optional[int] = Field(None, ge=1, le=5)