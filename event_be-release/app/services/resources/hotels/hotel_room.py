from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from typing import Optional

from models.hotels import HotelRoom
from schemas.resources.hotels import HotelRoomCreate, HotelRoomUpdate
from schemas.paginate import PaginationParams, PaginatedHotelRoomResponse
from repository.resources.hotels import HotelRoomRepository
from schemas.resources.hotels.hotel_room import HotelRoomResponse

class HotelRoomService:
    """Service class for hotel room business logic"""
    @staticmethod
    async def create_room(
            session: AsyncSession,
            hotel_id: int,
            data: HotelRoomCreate
    ) -> HotelRoom:
        """Create a new hotel room after verifying hotel ownership"""
        room = HotelRoom(
            hotel_id=hotel_id,
            room_type=data.room_type,
            ac_count=data.ac_count,
            non_ac_count=data.non_ac_count,
            ac_rate_per_night=data.ac_rate_per_night,
            non_ac_rate_per_night=data.non_ac_rate_per_night,
            is_available=data.is_available
        )

        return await HotelRoomRepository.create(session, room)

    @staticmethod
    async def get_room_or_404(
            session: AsyncSession,
            room_id: int,
    ) -> HotelRoom:
        """Get room by ID and verify ownership"""
        # Get room with hotel relationship loaded
        stmt = (
            select(HotelRoom)
            .where(HotelRoom.id == room_id)
        )
        result = await session.execute(stmt)
        room = result.scalar_one_or_none()

        if not room:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Room not found or access denied"
            )

        return room
    
    @staticmethod
    async def search_rooms(
        session: AsyncSession,
        hotel_id: int,
        room_type: Optional[str] = None,
        is_available: Optional[bool] = None,
        min_rate: Optional[float] = None,
        max_rate: Optional[float] = None,
        pagination: PaginationParams = PaginationParams(),
    ) -> PaginatedHotelRoomResponse:
        rooms, total = await HotelRoomRepository.search_rooms(
            session=session,
            hotel_id=hotel_id,
            room_type=room_type,
            is_available=is_available,
            min_rate=min_rate,
            max_rate=max_rate,
            skip=pagination.offset,
            limit=pagination.size,
        )
        return PaginatedHotelRoomResponse.create(
            items=[HotelRoomResponse.model_validate(r) for r in rooms],
            total=total,
            page=pagination.page,
            size=pagination.size,
        )

    @staticmethod
    async def update_room(
            session: AsyncSession,
            room_id: int,
            data: HotelRoomUpdate,
    ) -> HotelRoom:
        """Update room after verifying ownership and validating data"""
        await HotelRoomService.get_room_or_404(session, room_id)

        # Convert Pydantic model to dict, excluding None values
        update_data = data.model_dump(exclude_unset=True, exclude_none=True)
        return await HotelRoomRepository.update(session, room_id, update_data)

    @staticmethod
    async def delete_room(
            session: AsyncSession,
            room_id: int
    ) -> None:
        """Delete room after verifying ownership"""
        # Verify ownership first
        await HotelRoomService.get_room_or_404(session, room_id)

        await HotelRoomRepository.delete(session, room_id)

    @staticmethod
    async def get_room_by_id(
            session: AsyncSession,
            room_id: int
    ) -> HotelRoom:
        """Get a single room by ID (wrapper for get_room_or_404)"""
        return await HotelRoomService.get_room_or_404(session, room_id)

    @staticmethod
    async def check_room_availability(
            session: AsyncSession,
            room_id: int
    ) -> bool:
        """Check if a room is available"""
        room = await HotelRoomService.get_room_or_404(session, room_id)
        return room.is_available
