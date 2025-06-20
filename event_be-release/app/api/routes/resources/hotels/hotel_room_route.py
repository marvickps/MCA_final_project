from fastapi import APIRouter, Depends, Path, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from core.dependencies import get_session, require_TO, get_current_client, get_current_user

from models.hotels.hotel_room import RoomType
from schemas.resources.hotels import (
    HotelRoomCreate,
    HotelRoomResponse,
    HotelRoomUpdate
)
from schemas.paginate import PaginatedHotelRoomResponse, PaginationParams
from services.resources.hotels import HotelRoomService


router = APIRouter(prefix="/api/hotels/{hotel_id}/rooms", tags=["Rooms"])

@router.post(
    "/",
    response_model=HotelRoomResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new hotel room"
)
async def create_room(
    hotel_id: int,
    data: HotelRoomCreate,
    session: AsyncSession = Depends(get_session),
    current_user=Depends(require_TO),
    client_id: int = Depends(get_current_client),
):
    """Create a new hotel room with specified configuration"""
    return await HotelRoomService.create_room(
        session,
        hotel_id=hotel_id,
        data=data
    )

@router.get(
    "/",
    response_model=PaginatedHotelRoomResponse,
    summary="List hotel rooms",
    description="Get paginated list of hotel rooms with optional filtering"
)
async def list_hotel_rooms(
    hotel_id: int,
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Items per page"),
    room_type: Optional[RoomType] = Query(None, description="Filter by room type"),
    is_available: Optional[bool] = Query(None, description="Filter by availability"),
    min_rate: Optional[float] = Query(None, ge=0, description="Minimum nightly rate"),
    max_rate: Optional[float] = Query(None, ge=0, description="Maximum nightly rate"),
    session: AsyncSession = Depends(get_session),
    current_user=Depends(get_current_user),
    client_id=Depends(get_current_client),
):
    """
    List hotel rooms with pagination and filtering:

    - **page**: 1-based page number
    - **size**: items per page (1-100)
    - **hotel_id**: only rooms from this hotel
    - **room_type**: filter by room type
    - **is_available**: only available/unavailable rooms
    - **min_rate**, **max_rate**: nightly rate range
    """
    pagination = PaginationParams(page=page, size=size)

    return await HotelRoomService.search_rooms(
        session=session,
        hotel_id=hotel_id,
        room_type=room_type.value if room_type else None,
        is_available=is_available,
        min_rate=min_rate,
        max_rate=max_rate,
        pagination=pagination,
    )

@router.get(
    "/{room_id}",
    response_model=HotelRoomResponse,
    summary="Get a specific room"
)
async def get_room(
    hotel_id: int,
    room_id: int,
    session: AsyncSession = Depends(get_session),
    current_user=Depends(get_current_user),
    client_id: int = Depends(get_current_client),
):
    """Get details of a specific room"""
    return await HotelRoomService.get_room_or_404(
        session,
        room_id=room_id
    )

@router.put(
    "/{room_id}",
    response_model=HotelRoomResponse,
    summary="Update a hotel room"
)
async def update_room(
    hotel_id: int,
    room_id: int,
    data: HotelRoomUpdate,
    session: AsyncSession = Depends(get_session),
    current_user=Depends(require_TO),
    client_id: int = Depends(get_current_client),
):
    """Update room details"""
    return await HotelRoomService.update_room(
        session,
        room_id=room_id,
        data=data,
    )

@router.delete(
    "/{room_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a hotel room"
)
async def delete_room(
    hotel_id: int,
    room_id: int,
    session: AsyncSession = Depends(get_session),
    current_user=Depends(require_TO),
    client_id: int = Depends(get_current_client),
):
    """Delete a room from the hotel"""
    await HotelRoomService.delete_room(
        session,
        room_id=room_id
    )