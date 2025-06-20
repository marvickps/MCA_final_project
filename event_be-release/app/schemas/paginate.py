from pydantic import BaseModel, Field
from typing import List, Generic, TypeVar, Optional
from math import ceil

from schemas.resources.drivers.driver import DriverResponse
from schemas.resources.drivers.driver_vehicle import DriverReviewResponse
from schemas.resources.hotels.hotel import HotelResponse
from schemas.resources.hotels.hotel_room import HotelRoomResponse

T = TypeVar('T')

class PaginationParams(BaseModel):
    """Schema for pagination parameters"""
    page: int = Field(default=1, ge=1, description="Page number (1-based)")
    size: int = Field(default=10, ge=1, le=100, description="Items per page")
    
    @property
    def offset(self) -> int:
        """Calculate offset for database queries"""
        return (self.page - 1) * self.size

class PaginatedResponse(BaseModel, Generic[T]):
    """Generic paginated response schema"""
    items: List[T]
    total: int = Field(description="Total number of items")
    page: int = Field(description="Current page number")
    size: int = Field(description="Items per page")
    pages: int = Field(description="Total number of pages")
    has_next: bool = Field(description="Whether there is a next page")
    has_prev: bool = Field(description="Whether there is a previous page")
    
    @classmethod
    def create(cls, items: List[T], total: int, page: int, size: int):
        """Create paginated response from items and pagination info"""
        pages = ceil(total / size) if total > 0 else 1
        
        return cls(
            items=items,
            total=total,
            page=page,
            size=size,
            pages=pages,
            has_next=page < pages,
            has_prev=page > 1
        )

PaginatedHotelRoomResponse = PaginatedResponse[HotelRoomResponse]
PaginatedHotelResponse = PaginatedResponse[HotelResponse]
PaginatedDriverResponse = PaginatedResponse[DriverResponse]
PaginatedDriverReviewResponse = PaginatedResponse[DriverReviewResponse]
