from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from core.dependencies import get_session, get_current_user, get_current_client, require_TO
from schemas.resources.hotels import (
    HotelCreate, HotelUpdate, HotelResponse, HotelSimpleResponse,
    HotelCategory, FoodType
)
from services.resources.hotels import HotelService
from schemas.paginate import PaginatedHotelResponse, PaginationParams

router = APIRouter(prefix="/api/hotels", tags=["Hotels"])

@router.post(
    "/",
    response_model=HotelResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new hotel",
    description="Create a new hotel using Google Place ID. Hotel details will be automatically fetched from Google Maps API."
)
async def create_hotel(
    data: HotelCreate,
    session: AsyncSession = Depends(get_session),
    current_user = Depends(require_TO),
    client_id: int = Depends(get_current_client)
):
    return await HotelService.create_hotel(
        session=session,
        data=data,
        client_id=client_id,
        user_id=current_user.user_id
    )

@router.get(
    "/",
    response_model=PaginatedHotelResponse,
    summary="List hotels",
    description="Get paginated list of hotels with optional filtering and search"
)
async def list_hotels(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Items per page"),
    user_id: Optional[int] = Query(None, description="Filter by user ID"),
    search: Optional[str] = Query(None, description="Search term for hotel name"),
    category: Optional[HotelCategory] = Query(None, description="Filter by hotel category"),
    food_type: Optional[FoodType] = Query(None, description="Filter by food type"),
    include_rooms: bool = Query(False, description="Include room details in response"),
    my_hotels_only: bool = Query(False, description="Show only hotels created by current user"),
    session: AsyncSession = Depends(get_session),
    current_user = Depends(get_current_user),
    client_id = Depends(get_current_client)
):
    """
    List hotels with pagination and filtering:
    
    - **page**: Page number (1-based)
    - **size**: Number of items per page (1-100)
    - **search**: Search in hotel names
    - **category**: Filter by star rating
    - **food_type**: Filter by food type
    - **include_rooms**: Include room details
    - **my_hotels_only**: Show only current user's hotels
    """
    pagination = PaginationParams(page=page, size=size)
    
    if search or category or food_type or user_id:
        return await HotelService.search_hotels(
            session=session,
            client_id=client_id,
            search_term=search,
            category=category.value if category else None,
            food_type=food_type.value if food_type else None,
            user_id=user_id,
            pagination=pagination
        )
    else:
        user_id = current_user.user_id if my_hotels_only else None
        return await HotelService.list_hotels(
            session=session,
            client_id=client_id,
            user_id=user_id,
            pagination=pagination,
            include_rooms=include_rooms
        )

@router.get(
    "/{hotel_id}",
    response_model=HotelResponse,
    summary="Get hotel by ID",
    description="Get detailed information about a specific hotel including rooms"
)
async def get_hotel(
    hotel_id: int,
    session: AsyncSession = Depends(get_session),
    current_user = Depends(get_current_user),
    client_id = Depends(get_current_client)
):
    return await HotelService.get_hotel_by_id(
        session=session,
        hotel_id=hotel_id,
        client_id=client_id,
        user_id=None,  # Allow any user in client to view
        check_owner=False
    )

@router.get(
    "/my/{hotel_id}",
    response_model=HotelResponse,
    summary="Get my hotel by ID",
    description="Get detailed information about a hotel owned by current user"
)
async def get_my_hotel(
    hotel_id: int,
    session: AsyncSession = Depends(get_session),
    current_user = Depends(get_current_user),
    client_id = Depends(get_current_client)
):
    return await HotelService.get_hotel_by_id(
        session=session,
        hotel_id=hotel_id,
        client_id=client_id,
        user_id=current_user.user_id,
        check_owner=True
    )

@router.put(
    "/{hotel_id}",
    response_model=HotelResponse,
    summary="Update hotel",
    description="Update hotel information (owner only)"
)
async def update_hotel(
    hotel_id: int,
    data: HotelUpdate,
    session: AsyncSession = Depends(get_session),
    current_user = Depends(require_TO),
    client_id: int = Depends(get_current_client)
):
    return await HotelService.update_hotel(
        session=session,
        hotel_id=hotel_id,
        data=data,
        client_id=client_id,
        user_id=current_user.user_id
    )

@router.delete(
    "/{hotel_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete hotel",
    description="Delete a hotel (TO only)"
)
async def delete_hotel(
    hotel_id: int,
    session: AsyncSession = Depends(get_session),
    current_user = Depends(require_TO),
    client_id: int = Depends(get_current_client)
):
    await HotelService.delete_hotel(
        session=session,
        hotel_id=hotel_id,
        client_id=client_id,
        user_id=current_user.user_id,
    )

@router.post(
    "/{hotel_id}/activate",
    response_model=HotelResponse,
    summary="Activate hotel",
    description="Reactivate a soft-deleted hotel (owner only)"
)
async def activate_hotel(
    hotel_id: int,
    session: AsyncSession = Depends(get_session),
    current_user = Depends(get_current_user),
    client_id = Depends(get_current_client)
):
    update_data = HotelUpdate(is_active=True)
    return await HotelService.update_hotel(
        session=session,
        hotel_id=hotel_id,
        data=update_data,
        client_id=client_id,
        user_id=current_user.user_id
    )
