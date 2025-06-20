from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException, status
from models.hotels import Hotel
from repository.resources.hotels import HotelRepository
from schemas.resources.hotels import (
    HotelCreate, HotelUpdate, HotelResponse,
)
from schemas.paginate import PaginatedHotelResponse, PaginationParams
from typing import Optional

class HotelService:
    @staticmethod
    async def create_hotel(
        session: AsyncSession,
        data: HotelCreate,
        client_id: int,
        user_id: int
    ) -> HotelResponse:

        from services.google_maps_service import create_hotel_from_google_maps_api
        
        existing_hotel = await HotelRepository.get_by_place_id(session, data.place_id, client_id)
        if existing_hotel:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Hotel with this place_id already exists for your account"
            )
        
        google_data = await create_hotel_from_google_maps_api(data.place_id)
        if not google_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to fetch hotel details from Google Maps API"
            )

        hotel = Hotel(
            client_id=client_id,
            user_id=user_id,
            place_id=data.place_id,
            name=google_data.get("name", ""),
            address=google_data.get("address", ""),
            food_type=data.food_type,
            category=data.category,
            special_view_info=data.special_view_info,
            latitude=google_data.get("latitude"),
            longitude=google_data.get("longitude"),
            photo_url=google_data.get("photo_url", ""),
            google_rating=google_data.get("rating"),  # Fixed: was "google_rating"
        )
        
        created_hotel = await HotelRepository.create(session, hotel)
        return HotelResponse.model_validate(created_hotel)

    @staticmethod
    async def get_hotel_or_404(
        session: AsyncSession,
        hotel_id: int,
        client_id: int,
        user_id: Optional[int] = None,
        check_owner: bool = True,
        include_rooms: bool = False
    ) -> Hotel:
        """Get hotel with ownership validation"""
        hotel = await HotelRepository.get_by_id(session, hotel_id, include_rooms)
        
        if not hotel:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail="Hotel not found"
            )
            
        if hotel.client_id != client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="Access denied for this client"
            )
            
        if check_owner and user_id and hotel.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN, 
                detail="You do not own this hotel"
            )
            
        return hotel

    @staticmethod
    async def get_hotel_by_id(
        session: AsyncSession,
        hotel_id: int,
        client_id: int,
        user_id: Optional[int] = None,
        check_owner: bool = True
    ) -> HotelResponse:
        """Get single hotel by ID"""
        hotel = await HotelService.get_hotel_or_404(
            session, hotel_id, client_id, user_id, check_owner, include_rooms=True
        )
        return HotelResponse.model_validate(hotel)

    @staticmethod
    async def get_hotel_by_place_id(
        session: AsyncSession,
        place_id: str,
        client_id: int,
        user_id: Optional[int] = None,
        check_owner: bool = True
    ) -> HotelResponse:
        """Get single hotel by place ID"""
        hotel = await HotelService.get_hotel_or_404(
            session, place_id=place_id, client_id=client_id, user_id=user_id, check_owner=check_owner, include_rooms=True
        )
        return HotelResponse.model_validate(hotel)


    @staticmethod
    async def list_hotels(
        session: AsyncSession,
        client_id: int,
        user_id: Optional[int] = None,
        pagination: PaginationParams = PaginationParams(),
        include_rooms: bool = False
    ) -> PaginatedHotelResponse:
        """List hotels with pagination"""
        if user_id:
            hotels, total = await HotelRepository.list_by_user(
                session, user_id, client_id, 
                pagination.offset, pagination.size, include_rooms
            )
        else:
            hotels, total = await HotelRepository.list_by_client(
                session, client_id, 
                pagination.offset, pagination.size, include_rooms
            )
        
        # Convert to Pydantic models
        hotel_responses = [
            HotelResponse.model_validate(hotel) for hotel in hotels
        ]
        
        return PaginatedHotelResponse.create(
            items=hotel_responses,
            total=total,
            page=pagination.page,
            size=pagination.size
        )

    @staticmethod
    async def search_hotels(
        session: AsyncSession,
        client_id: int,
        place_id: Optional[str] = None,
        search_term: Optional[str] = None,
        category: Optional[str] = None,
        food_type: Optional[str] = None,
        user_id: Optional[int] = None,
        pagination: PaginationParams = PaginationParams()
    ) -> PaginatedHotelResponse:
        """Search hotels with filters including user ID"""
        hotels, total = await HotelRepository.search_hotels(
            session, client_id, place_id, search_term, category, food_type,
            user_id, pagination.offset, pagination.size
        )

        hotel_responses = [
            HotelResponse.model_validate(hotel) for hotel in hotels
        ]

        return PaginatedHotelResponse.create(
            items=hotel_responses,
            total=total,
            page=pagination.page,
            size=pagination.size
        )

    @staticmethod
    async def update_hotel(
        session: AsyncSession,
        hotel_id: int,
        data: HotelUpdate,
        client_id: int,
        user_id: int
    ) -> HotelResponse:
        """Update hotel"""
        # Check ownership and existence
        await HotelService.get_hotel_or_404(session, hotel_id, client_id, user_id)

        update_data = data.model_dump(exclude_unset=True)
        updated_hotel = await HotelRepository.update(session, hotel_id, update_data)
        
        if not updated_hotel:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hotel not found after update"
            )
            
        return HotelResponse.model_validate(updated_hotel)

    @staticmethod
    async def delete_hotel(
        session: AsyncSession,
        hotel_id: int,
        client_id: int,
        user_id: int,
    ) -> None:
        """Delete hotel (soft or hard delete)"""
        await HotelService.get_hotel_or_404(session, hotel_id, client_id, user_id)
        
        await HotelRepository.hard_delete(session, hotel_id)
