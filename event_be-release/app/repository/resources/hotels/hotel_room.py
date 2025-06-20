from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, status
from typing import Optional, List, Tuple

from models.hotels.hotel import Hotel
from models.hotels.hotel_room import HotelRoom
from schemas.paginate import PaginationParams

class HotelRoomRepository:
    """Repository class for HotelRoom operations"""

    @staticmethod
    async def create(session: AsyncSession, room: HotelRoom) -> HotelRoom:
        """Create a new hotel room"""
        session.add(room)
        await session.commit()
        await session.refresh(room)
        return room

    @staticmethod
    async def get_by_id(session: AsyncSession, room_id: int) -> Optional[HotelRoom]:
        """Get hotel room by ID with related data"""
        stmt = (
            select(HotelRoom)
            .where(HotelRoom.id == room_id)
        )
        result = await session.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def search_rooms(
        session: AsyncSession,
        hotel_id: int,
        room_type: Optional[str] = None,
        is_available: Optional[bool] = None,
        min_rate: Optional[float] = None,
        max_rate: Optional[float] = None,
        skip: int = 0,
        limit: int = 10,
    ) -> Tuple[List[HotelRoom], int]:
        """Search hotel rooms with optional filters, joining Hotel for client filtering"""
        query = select(HotelRoom).join(Hotel).where(
            HotelRoom.hotel_id == hotel_id,
            Hotel.is_active == True
        )
        
        if room_type is not None:
            query = query.where(HotelRoom.room_type == room_type)
        if is_available is not None:
            query = query.where(HotelRoom.is_available == is_available)
        if min_rate is not None:
            query = query.where(
                HotelRoom.ac_rate_per_night >= min_rate,
                HotelRoom.non_ac_rate_per_night >= min_rate
            )
        if max_rate is not None:
            query = query.where(
                HotelRoom.ac_rate_per_night <= max_rate,
                HotelRoom.non_ac_rate_per_night <= max_rate
            )

        count_query = select(func.count()).select_from(query.subquery())
        total = (await session.execute(count_query)).scalar_one()

        query = query.offset(skip).limit(limit)
        result = await session.execute(query)
        rooms = result.scalars().all()

        return rooms, total

    @staticmethod
    async def update(session: AsyncSession, room_id: int, update_data: dict) -> HotelRoom:
        """Update hotel room with provided data"""
        room = await HotelRoomRepository.get_by_id(session, room_id)
        if not room:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

        for field, value in update_data.items():
            if hasattr(room, field):
                setattr(room, field, value)

        await session.commit()
        await session.refresh(room)
        return room

    @staticmethod
    async def delete(session: AsyncSession, room_id: int) -> None:
        """Delete hotel room"""
        room = await HotelRoomRepository.get_by_id(session, room_id)
        if not room:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")

        await session.delete(room)
        await session.commit()

    @staticmethod
    async def get_room_count_by_hotel(session: AsyncSession, hotel_id: int) -> int:
        """Get total room count for a hotel"""
        stmt = (
            select(HotelRoom.ac_count, HotelRoom.non_ac_count)
            .where(HotelRoom.hotel_id == hotel_id)
        )
        result = await session.execute(stmt)
        all_counts = result.all()
        total_count = sum(ac + non_ac for ac, non_ac in all_counts) if all_counts else 0
        return total_count

    @staticmethod
    async def get_rooms_by_price_range(
        session: AsyncSession, 
        hotel_id: int, 
        min_price: float, 
        max_price: float
    ) -> List[HotelRoom]:
        """Get rooms within a specific price range for a hotel"""
        stmt = (
            select(HotelRoom)
            .where(
                HotelRoom.hotel_id == hotel_id,
                HotelRoom.cost_per_night >= min_price,
                HotelRoom.cost_per_night <= max_price
            )
            .order_by(HotelRoom.cost_per_night)
        )
        result = await session.execute(stmt)
        return list(result.scalars().all())