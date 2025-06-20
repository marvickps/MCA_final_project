from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete, func
from sqlalchemy.orm import selectinload
from models.hotels import Hotel, HotelRoom
from typing import Optional, List, Tuple

class HotelRepository:
    @staticmethod
    async def get_by_place_id(
        session: AsyncSession, 
        place_id: str, 
        client_id: int
    ) -> Optional[Hotel]:
        """Get hotel by place_id and client_id to prevent duplicates"""
        result = await session.execute(
            select(Hotel).where(
                Hotel.place_id == place_id,
                Hotel.client_id == client_id,
                Hotel.is_active == True
            )
        )
        return result.scalar_one_or_none()

    @staticmethod
    async def create(session: AsyncSession, hotel: Hotel) -> Hotel:
        """Create a new hotel"""
        session.add(hotel)
        await session.commit()
        await session.refresh(hotel)
        return hotel

    @staticmethod
    async def get_by_id(
        session: AsyncSession, 
        hotel_id: int, 
        include_rooms: bool = False
    ) -> Optional[Hotel]:
        """Get hotel by ID with optional room loading"""
        query = select(Hotel).where(Hotel.hotel_id == hotel_id)
        
        if include_rooms:
            query = query.options(selectinload(Hotel.rooms))
            
        result = await session.execute(query)
        return result.scalar_one_or_none()

    @staticmethod
    async def list_by_client(
        session: AsyncSession, 
        client_id: int,
        skip: int = 0,
        limit: int = 10,
        include_rooms: bool = False
    ) -> Tuple[List[Hotel], int]:
        """Get paginated list of hotels for a client with total count"""
        # Get total count
        count_query = select(func.count()).select_from(Hotel).where(
            Hotel.client_id == client_id,
            Hotel.is_active == True
        )
        total_result = await session.execute(count_query)
        total = total_result.scalar_one()

        # Get paginated items
        query = select(Hotel).where(
            Hotel.client_id == client_id,
            Hotel.is_active == True
        ).offset(skip).limit(limit)
        
        if include_rooms:
            query = query.options(selectinload(Hotel.rooms))
            
        result = await session.execute(query)
        hotels = result.scalars().all()
        
        return list(hotels), total

    @staticmethod
    async def list_by_user(
        session: AsyncSession, 
        user_id: int,
        client_id: int,
        skip: int = 0,
        limit: int = 10,
        include_rooms: bool = False
    ) -> Tuple[List[Hotel], int]:
        """Get paginated list of hotels for a specific user within a client"""
        # Get total count
        count_query = select(func.count()).select_from(Hotel).where(
            Hotel.client_id == client_id,
            Hotel.user_id == user_id,
            Hotel.is_active == True
        )
        total_result = await session.execute(count_query)
        total = total_result.scalar_one()

        # Get paginated items
        query = select(Hotel).where(
            Hotel.client_id == client_id,
            Hotel.user_id == user_id,
            Hotel.is_active == True
        ).offset(skip).limit(limit)
        
        if include_rooms:
            query = query.options(selectinload(Hotel.rooms))
            
        result = await session.execute(query)
        hotels = result.scalars().all()
        
        return list(hotels), total

    @staticmethod
    async def update(session: AsyncSession, hotel_id: int, data: dict) -> Optional[Hotel]:
        """Update hotel and return updated instance"""
        await session.execute(
            update(Hotel)
            .where(Hotel.hotel_id == hotel_id)
            .values(**data)
        )
        await session.commit()
        return await HotelRepository.get_by_id(session, hotel_id)

    @staticmethod
    async def hard_delete(session: AsyncSession, hotel_id: int) -> None:
        """Hard delete hotel from database"""
        await session.execute(delete(Hotel).where(Hotel.hotel_id == hotel_id))
        await session.commit()

    @staticmethod
    async def search_hotels(
        session: AsyncSession,
        client_id: int,
        place_id: Optional[str] = None,
        search_term: Optional[str] = None,
        category: Optional[str] = None,
        food_type: Optional[str] = None,
        user_id: Optional[int] = None,
        skip: int = 0,
        limit: int = 10
    ) -> Tuple[List[Hotel], int]:
        """Search hotels with optional filters including user_id"""
        query = select(Hotel).where(
            Hotel.client_id == client_id,
            Hotel.is_active == True
        )
        
        if search_term:
            query = query.where(Hotel.name.ilike(f"%{search_term}%"))
        if category:
            query = query.where(Hotel.category == category)
        if food_type:
            query = query.where(Hotel.food_type == food_type)
        if place_id:
            query = query.where(Hotel.place_id == place_id)
        if user_id:
            query = query.where(Hotel.user_id == user_id)
        print(query)
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await session.execute(count_query)
        total = total_result.scalar_one()
        
        query = query.offset(skip).limit(limit)
        result = await session.execute(query)
        hotels = result.scalars().all()
        
        return list(hotels), total
