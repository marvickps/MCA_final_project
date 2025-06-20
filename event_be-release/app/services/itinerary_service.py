# app/services/hotel_service.py
import secrets
from sqlalchemy.ext.asyncio import AsyncSession
from services.resources.hotels.hotel import HotelService
from schemas.resources.hotels.hotel import HotelCreate, HotelResponse
from repository.user import fetch_by_user_id
from services.user import get_default_timing
from repository.itinerary_repository import get_item, get_itinerary_item
from schemas.itinerary import AddItineraryItem
from fastapi import HTTPException, status
import requests
from sqlalchemy import Null, asc, desc, select, update
from services import google_maps_service
# from models import itinerary_modal
from sqlalchemy.orm import Session
from core.config import GOOGLE_MAPS_API_KEY
# from models import hotel_model, place_modal, restaurant_modal
from datetime import date, datetime, timedelta, time
from collections import defaultdict
# from logger import logger
from typing import Any, Dict, List, Optional, Union

from services.hotel_service import create_hotel_from_google_maps_api
from models.location_modal import Location
from services.location_service import create_location_from__google_maps_api
from services.place_service import create_place_from_google_maps_api
from services.restaurant_service import create_restaurant_from_google_maps_api
from schemas.itinerary import ItineraryInput
from models.itinerary_modal import Itinerary, ItineraryDays, ItineraryItem, ItineraryShareCode
from models.hotels.hotel import FoodType, Hotel, HotelCategory
from models.place_modal import Place
from models.restaurant_modal import Restaurant



async def create_share_code(itinerary_id, session: AsyncSession):
    code = secrets.token_urlsafe(10)

    # Create a new entry
    new_share = ItineraryShareCode(
        itinerary_id=itinerary_id,
        share_code=code
    )
    # Add to DB and commit
    session.add(new_share)
    await session.flush()
    await session.commit()
    await session.refresh(new_share)
    return new_share.share_code

async def calculate_next_arrival_time(arrival_time:time, stay_duration:int, travel_duration:int ):
    dummy_datetime = datetime.combine(datetime.today() , arrival_time)
    total_duration = timedelta(seconds=stay_duration + travel_duration)
    eta = dummy_datetime + total_duration
    return eta.time()

async def get_item_details(item, item_type, session: AsyncSession):
    if item_type == "hotel":
        item_detail = await session.execute(
            select(Hotel).where(Hotel.hotel_id == item.hotel_id)
        )
    elif item_type == "restaurant":
        item_detail = await session.execute(
            select(Restaurant).where(Restaurant.restaurant_id == item.restaurant_id)
        )
    elif item_type == "place" or item_type == "starting_point":
        item_detail = await session.execute(
            select(Place).where(Place.p_id == item.p_id)
        )
    return item_detail.scalar_one_or_none()  # Added scalar_one_or_none() to get the actual model instance



async def recalculate_itinerary_timings(ordered_items, session):
    for index, current_item in enumerate(ordered_items):
        if index == 0: 
            continue
        last_item = ordered_items[index - 1]

        origin = await get_item_details(last_item, last_item.type.value, session) 
        destination = await get_item_details(current_item, current_item.type.value, session)

        if not origin or not destination:
            raise HTTPException(
                status_code=404,
                detail=f"Origin or destination not found for itinerary item at index {index}"
            )

        data = await google_maps_service.get_distance_matrix_details(origin.place_id, destination.place_id)

        new_time = await calculate_next_arrival_time(last_item.time, last_item.stay_duration, data["duration"])

        current_item.time = new_time
        current_item.distance_from_previous_stop = data["distance"]
        current_item.duration_from_previous_stop = data["duration"]

    # Commit once after updating all items for better performance
    await session.commit()

    # Refresh all items asynchronously
    for item in ordered_items:
        await session.refresh(item)

    return ordered_items


async def add_item(item_id, item, request, session: AsyncSession):
    hotel_id = None
    restaurant_id = None
    p_id = None

    timing = await get_default_timing(request.user_id, session)
    if not timing:
        raise HTTPException(status_code=404, detail=f"default timing not found user ID = {request.user_id}")

    if request.type.lower() == "hotel":
        hotel_id = item_id
        stay_duration = timing.hotel_daytime_duration
    elif request.type.lower() == "restaurant":
        restaurant_id = item_id
        stay_duration = timing.restaurant_duration
    elif request.type.lower() == "place":
        p_id = item_id
        stay_duration = timing.place_duration
    else:
        raise HTTPException(status_code=400, detail="Invalid item type")

    stmt = (
        select(ItineraryItem)
        .where(ItineraryItem.itinerary_day_id == request.itinerary_day_id)
        .order_by(ItineraryItem.order_index.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    last_item = result.scalar_one_or_none()

    # Determine origin and next item's arrival time
    if last_item:
        origin = await get_item_details(last_item, last_item.type, session)
        new_time = await calculate_next_arrival_time(last_item.time, last_item.stay_duration, 0)
        new_order = last_item.order_index + 1
    else:
        origin = item
        new_time = timing.start_time or datetime.strptime("09:00", "%H:%M").time()  # Default fallback
        new_order = 1

    if not origin or not origin.place_id or not request.place_id:
        raise HTTPException(status_code=400, detail="Missing place ID for distance calculation")

    data = await google_maps_service.get_distance_matrix_details(origin.place_id, request.place_id)
    distance = data["distance"]
    duration = data["duration"]

    item_data = {
        "itinerary_day_id": request.itinerary_day_id,
        "time": new_time,
        "distance_from_previous_stop": distance,
        "duration_from_previous_stop": duration,
        "order_index": new_order,
        "type": request.type,
        "hotel_id": hotel_id,
        "restaurant_id": restaurant_id,
        "p_id": p_id,
        "stay_duration": stay_duration,
    }

    new_item = ItineraryItem(**item_data)
    session.add(new_item)

    await session.flush()
    await session.refresh(new_item)
    await session.commit()
    return new_item


async def create_itinerary(
    user_id: int, 
    itineraryName: str, 
    location_id: int,startDate: date,endDate: date, p_id: int, session: AsyncSession) -> Itinerary:
    new_itinerary = Itinerary(
        user_id=user_id,
        title=itineraryName,
        location_id=location_id, 
        start_date=startDate,
        end_date=endDate,
        starting_point=p_id,
        created_at=datetime.now()
    )
    session.add(new_itinerary)
    await session.flush()  # Ensure itinerary_id is available
    await session.refresh(new_itinerary)
    return new_itinerary

async def create_itinerary_days(
    itinerary_id: int,
    startDate: date,
    endDate: date,
    session: AsyncSession
) -> List[ItineraryDays]:
    current_date = startDate
    day_number = 1
    itinerary_days = []
    
    while current_date <= endDate:
        itinerary_days.append(
            ItineraryDays(
                itinerary_id=itinerary_id,
                day_number=day_number,
                date=current_date
            )
        )
        current_date += timedelta(days=1)
        day_number += 1

    session.add_all(itinerary_days)   # Correct: no await
    await session.flush()             # Correct: await async call

    
    for day in itinerary_days:
        await session.refresh(day)
        
    return itinerary_days

async def create_itinerary_items(
    user_id:int,
    itinerary_day_id: int,
    day_number: int,
    p_id: int,
    hotel_id: int,
    place_place_id: str,
    hotel_place_id: str,
    session: AsyncSession
) -> List[ItineraryItem]:

    timing = await get_default_timing(user_id, session)
    if not timing:
        raise HTTPException(status_code=404, detail=f"default timing not found user ID = {user_id}")
    
    items = []
    if day_number == 1:
        place_item = ItineraryItem(
            itinerary_day_id=itinerary_day_id,
            time=time(9, 0),
            order_index=0,
            type="starting_point",
            p_id=p_id,
            stay_duration=0
        )
        session.add(place_item)
        await session.flush()
        items.append(place_item)
        data = await google_maps_service.get_distance_matrix_details(place_place_id, hotel_place_id)
        distance = data["distance"]
        duration = data["duration"]
        new_time = await calculate_next_arrival_time(place_item.time, place_item.stay_duration, duration)
        hotel_item = ItineraryItem(
            itinerary_day_id=itinerary_day_id,
            time=new_time,
            distance_from_previous_stop=distance,
            duration_from_previous_stop=duration,
            order_index=1,
            type="hotel",
            hotel_id=hotel_id,
            stay_duration=timing.hotel_daytime_duration
        )
        session.add(hotel_item)
        items.append(hotel_item)
    else:
        hotel_item = ItineraryItem(
            itinerary_day_id=itinerary_day_id,
            time=time(9, 0),
            order_index=1,
            type="hotel",
            hotel_id=hotel_id,
            stay_duration=0
        )
        session.add(hotel_item)
        items.append(hotel_item)
    await session.flush()

    for item in items:
        await session.refresh(item)
    return items

async def create_initial_itinerary(
    session: AsyncSession,
    client_id: int,
    user_id: Optional[int],
    itineraryName: str,
    itineraryPlaceID: str,
    accommodation: str,
    startingPoint: str,
    startDate: date,
    endDate: date,
) -> Itinerary:
    try:
        # Check or create hotel
        hotel_result = await session.execute(
            select(Hotel).where(
                Hotel.place_id == accommodation,
                Hotel.client_id == client_id,
                Hotel.user_id == user_id
            )
        )
        hotel = hotel_result.scalar_one_or_none()

        if not hotel:
            hotel_data = HotelCreate(
                food_type=FoodType.Veg,
                category=HotelCategory.three,
                place_id=accommodation,
                special_view_info=None,
            )
            hotel = await HotelService.create_hotel(
                session=session,
                data=hotel_data,
                client_id=client_id,
                user_id=user_id
            )

        if not hotel:
            raise HTTPException(status_code=500, detail="Hotel creation failed and could not be found.")

        # ✅ Check or create location
        location_result = await session.execute(
            select(Location).where(Location.place_id == itineraryPlaceID)
        )
        location = location_result.scalar_one_or_none()

        if not location:
            location = await create_location_from__google_maps_api(itineraryPlaceID, session)
            if not location:
                raise HTTPException(status_code=500, detail="Location creation failed and could not be found.")

        # ✅ Check or create starting point place
        place_result = await session.execute(
            select(Place).where(Place.place_id == startingPoint)
        )
        place = place_result.scalar_one_or_none()

        if not place:
            await create_place_from_google_maps_api(startingPoint, session=session)
            place_result = await session.execute(
                select(Place).where(Place.place_id == startingPoint)
            )
            place = place_result.scalar_one_or_none()

        if not place:
            raise HTTPException(status_code=500, detail="Starting point creation failed and could not be found.")

        # Create itinerary
        itinerary = await create_itinerary(
            user_id,
            itineraryName,
            location.location_id,
            startDate,
            endDate,
            place.p_id,
            session
        )

        # Create itinerary days
        itinerary_days = await create_itinerary_days(
            itinerary.itinerary_id,
            startDate,
            endDate,
            session
        )

        # Create itinerary items
        itinerary_items = []
        for day in itinerary_days:
            day_items = await create_itinerary_items(
                user_id,
                day.itinerary_day_id,
                day.day_number,
                place.p_id,
                hotel.hotel_id,
                place.place_id,
                hotel.place_id,
                session
            )
            itinerary_items.extend(day_items)

        await session.refresh(itinerary)
        await create_share_code(itinerary.itinerary_id, session)
        await session.commit()
        return itinerary


    except Exception as e:
        await session.rollback()
        raise HTTPException(status_code=500, detail=f"Unexpected error during itinerary creation: {e}")

async def add_itinerary_item(
    request: AddItineraryItem,
    session: AsyncSession,
    client_id: int,
    user_id: Optional[int]
):
    try:
        item = None
        item_id = None

        if request.type.lower() == "hotel":
            # First check if hotel exists
            hotel_result = await session.execute(
                select(Hotel).where(
                    Hotel.place_id == request.place_id,
                    Hotel.client_id == client_id,
                    Hotel.user_id == user_id
                )
            )
            item = hotel_result.scalar_one_or_none()

            if not item:
                hotel_data = HotelCreate(
                    food_type=FoodType.Veg,
                    category=HotelCategory.three,
                    place_id=request.place_id,
                    special_view_info=None,
                )
                hotel_response = await HotelService.create_hotel(
                    session=session,
                    data=hotel_data,
                    client_id=client_id,
                    user_id=user_id
                )
                
                hotel_result = await session.execute(
                    select(Hotel).where(Hotel.hotel_id == hotel_response.hotel_id)
                )
                item = hotel_result.scalar_one_or_none()
                if not item:
                    raise HTTPException(status_code=500, detail="Failed to retrieve created hotel")
            item_id = item.hotel_id if item else None

        elif request.type == "restaurant":
            stmt = select(Restaurant).where(Restaurant.user_id == request.user_id, Restaurant.place_id == request.place_id)
            result = await session.execute(stmt)
            item = result.scalar_one_or_none()

            if not item:
                item = await create_restaurant_from_google_maps_api(request.user_id, request.place_id, session=session)
            item_id = item.restaurant_id if item else None

        elif request.type == "place":
            stmt = select(Place).where(Place.place_id == request.place_id)
            result = await session.execute(stmt)
            item = result.scalar_one_or_none()

            if not item:
                item = await create_place_from_google_maps_api(request.place_id, session=session)
            item_id = item.p_id if item else None

        if item_id is None:
            raise HTTPException(status_code=500, detail=f"Failed to get or create {request.type} with place_id {request.place_id}")
        result = await add_item(item_id, item, request, session)
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to add itinerary item: {e}")

def get_all_route(itinerary_id, db):
    items = (
        db.query(
            ItineraryDays.itinerary_day_id,
            ItineraryDays.day_number,
            ItineraryDays.date,
            ItineraryItem.itinerary_item_id,
            ItineraryItem.order_index,
            ItineraryItem.type,
            ItineraryItem.hotel_id,
            ItineraryItem.restaurant_id,
            ItineraryItem.p_id,
        )
        .join(ItineraryItem, ItineraryItem.itinerary_day_id == ItineraryDays.itinerary_day_id)
        .filter(ItineraryDays.itinerary_id == itinerary_id)
        .order_by(ItineraryDays.day_number, ItineraryItem.order_index)
        .all()
    )
    #logger.info(items)
    hotel_ids, restaurant_ids, place_ids = set(), set(), set()

    for item in items:
        if item.type == "hotel" and item.hotel_id:
            hotel_ids.add(item.hotel_id)
        elif item.type == "restaurant" and item.restaurant_id:
            restaurant_ids.add(item.restaurant_id)
        elif (item.type == "place" or item.type =="starting_point") and item.p_id:
            place_ids.add(item.p_id)

    hotels = {h.hotel_id: h for h in db.query(Hotel).filter(Hotel.hotel_id.in_(hotel_ids)).all()}
    restaurants = {r.restaurant_id: r for r in db.query(Restaurant).filter(Restaurant.restaurant_id.in_(restaurant_ids)).all()}
    places = {p.p_id: p for p in db.query(Place).filter(Place.p_id.in_(place_ids)).all()}

    grouped = defaultdict(lambda: {"place": {}})
    item_counters = defaultdict(int)

    for row in items:
        day_id = str(row.itinerary_day_id)
        if "day_id" not in grouped[day_id]:
            grouped[day_id]["day_id"] = str(row.day_number)
            grouped[day_id]["date"] = row.date.strftime("%d-%m-%Y") if row.date else ""

        item_counters[day_id] += 1
        pid = f"p_id-{item_counters[day_id]}"

        data = {}
        if row.type == "hotel" and row.hotel_id in hotels:
            p = hotels[row.hotel_id]
        elif row.type == "restaurant" and row.restaurant_id in restaurants:
            p = restaurants[row.restaurant_id]
        elif row.p_id in places:
            p = places[row.p_id]
        data = {
                "order": str(row.order_index),
                "placeID": str(p.place_id),
                "lat": str(p.latitude),
                "lng": str(p.longitude),
                "placeType": row.type,
                "name": p.name,
                "address": p.address,
            }   
        grouped[day_id]["place"][pid] = data

    return list(grouped.values())


def get_route_for_day(itinerary_id, day_id, db):
    items = (
        db.query(
            ItineraryDays.itinerary_day_id,
            ItineraryDays.day_number,
            ItineraryDays.date,
            ItineraryItem.itinerary_item_id,
            ItineraryItem.order_index,
            ItineraryItem.type,
            ItineraryItem.hotel_id,
            ItineraryItem.restaurant_id,
            ItineraryItem.p_id,
        )
        .join(ItineraryItem, ItineraryItem.itinerary_day_id == ItineraryDays.itinerary_day_id)
        .filter(ItineraryDays.itinerary_id == itinerary_id)
        .filter(ItineraryDays.itinerary_day_id == day_id)
        .order_by(ItineraryDays.day_number, ItineraryItem.order_index)
        .all()
    )
    #logger.info(items)

    hotel_ids, restaurant_ids, place_ids = set(), set(), set()

    for item in items:
        if item.type == "hotel" and item.hotel_id:
            hotel_ids.add(item.hotel_id)
        elif item.type == "restaurant" and item.restaurant_id:
            restaurant_ids.add(item.restaurant_id)
        elif (item.type == "place" or item.type == "starting_point") and item.p_id:
            place_ids.add(item.p_id)

    hotels = {h.hotel_id: h for h in db.query(Hotel).filter(Hotel.hotel_id.in_(hotel_ids)).all()}
    restaurants = {r.restaurant_id: r for r in db.query(Restaurant).filter(Restaurant.restaurant_id.in_(restaurant_ids)).all()}
    places = {p.p_id: p for p in db.query(Place).filter(Place.p_id.in_(place_ids)).all()}

    grouped = defaultdict(lambda: {"place": {}})
    item_counters = defaultdict(int)

    for row in items:
        day_id_str = str(row.itinerary_day_id)
        if "day_id" not in grouped[day_id_str]:
            grouped[day_id_str]["day_id"] = str(row.day_number)
            grouped[day_id_str]["date"] = row.date.strftime("%d-%m-%Y") if row.date else ""

        item_counters[day_id_str] += 1
        pid = f"p_id-{item_counters[day_id_str]}"

        data = {}
        if row.type == "hotel" and row.hotel_id in hotels:
            p = hotels[row.hotel_id]
        elif row.type == "restaurant" and row.restaurant_id in restaurants:
            p = restaurants[row.restaurant_id]
        elif row.p_id in places:
            p = places[row.p_id]

        data = {
            "order": str(row.order_index),
            "placeID": str(p.place_id),
            "lat": str(p.latitude),
            "lng": str(p.longitude),
            "placeType": row.type,
            "name": p.name,
            "address": p.address,
        }

        grouped[day_id_str]["place"][pid] = data

    return list(grouped.values())

  
def get_day_summary(itinerary_day_id, db):
    items = (
        db.query(ItineraryItem).filter(ItineraryItem.itinerary_day_id == itinerary_day_id).all()
        )
    #logger.info(items)
    itinerary_day = db.query(ItineraryDays).filter(ItineraryDays.itinerary_day_id==itinerary_day_id).first()
    itinerary = db.query(Itinerary).filter(Itinerary.itinerary_id==itinerary_day.itinerary_id).first()
    stops= []
    day_cost = 0
    day_distance_km =0
    estimated_total_duration = 0
    total_stay_duration = 0
    departure_time = Null
    for row in items:
        if row.hotel_id:
            p = db.query(Hotel).filter(Hotel.hotel_id == row.hotel_id).first()
        elif row.restaurant_id:
            p = db.query(Restaurant).filter(Restaurant.restaurant_id == row.restaurant_id).first()
        elif row.p_id:
            p = db.query(Place).filter(Place.p_id == row.p_id).first()
        stop_data = {
            "stop_id" : row.itinerary_item_id,
            "order": row.order_index,
            "name": p.name,
            "address": p.address,
            "type": row.type,
            "eta": row.time,
            "stay_duration":row.stay_duration,
            "from_previous_duration": row.duration_from_previous_stop,
            "distance_from_previous_stop": row.distance_from_previous_stop,
            "cost": row.cost,
            "lat": p.latitude,
            "lng": p.longitude,
            "description": row.description,
        }
        if row.cost:
            day_cost += row.cost
        if row.distance_from_previous_stop:
            day_distance_km += row.distance_from_previous_stop
        if row.duration_from_previous_stop:
            estimated_total_duration += row.duration_from_previous_stop
        if row.stay_duration:
            total_stay_duration += row.stay_duration
        stops.append(stop_data)
    if stops != Null:
        departure_time = stops[0]["eta"]

    day_summary ={
        "itinerary_id": itinerary_day.itinerary_id,
        "date" : itinerary_day.date,
        "day_title": f"{itinerary.title} - Day {itinerary_day.day_number}",
        "departure_time": departure_time,
        "day_cost": day_cost,
        "day_distance_km": day_distance_km,
        "estimated_total_duration":estimated_total_duration,
        "total_stay_duration":total_stay_duration,
        "stops": stops 
    }
    
    return day_summary


def get_itinerary_menu_details(
    itinerary_id: int,
    db: Session
) -> Dict[str, Any]:
    response = db.query(Itinerary).filter(
        Itinerary.itinerary_id == itinerary_id
    ).first()
    if not response:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    
    return {
        "itinerary_id": response.itinerary_id,
        "itinerary_name": response.title,
        "start_date": response.start_date,
        "end_date": response.end_date
    }

def get_timeline(
    itinerary_id: int,
    db: Session
) -> Dict[str, Any]:
    itinerary_response = db.query(Itinerary).filter(
        Itinerary.itinerary_id == itinerary_id
    ).first()
    if not itinerary_response:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    
    location =  db.query(Location).filter(Location.location_id == itinerary_response.location_id).first()
    
    itinerary_days = db.query(ItineraryDays).filter(
        ItineraryDays.itinerary_id == itinerary_id
    ).order_by(ItineraryDays.day_number).all()
    
    response = {
        "itinerary_id": itinerary_response.itinerary_id
    }
    for day in itinerary_days:
        itinerary_items = db.query(ItineraryItem).filter(
            ItineraryItem.itinerary_day_id == day.itinerary_day_id
        ).all()
        types = list(set([item.type.value for item in itinerary_items]))
        response[f"day{day.day_number}"] = {
            "address":location.address,
            "date": str(day.date),
            "day_id": day.itinerary_day_id,
            "type": types
        }
    return response

def get_route(
    itinerary_id: int,
    day: Union[int, str],
    db: Session
) -> List[Any]: 
    if day == "all":
        return get_all_route(itinerary_id, db)
    else:
        return get_route_for_day(itinerary_id, int(day), db)


async def reorder_itinerary_items(request, session: AsyncSession):
    try:
        for stop in request.stops:
            stmt = select(ItineraryItem).where(ItineraryItem.itinerary_item_id == stop.stop_id)
            result = await session.execute(stmt)
            item = result.scalar_one_or_none()

            if not item:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"itinerary item with id = {stop.stop_id} not found"
                )

            item.order_index = stop.order

        await session.commit()

        stmt_ordered = (
            select(ItineraryItem)
            .where(ItineraryItem.itinerary_day_id == request.itinerary_day_id)
            .order_by(asc(ItineraryItem.order_index))
        )
        result_ordered = await session.execute(stmt_ordered)
        ordered_items = result_ordered.scalars().all()

        if ordered_items:
            return await recalculate_itinerary_timings(ordered_items, session)

    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to reorder itinerary items. Error: {e}"
        )


def get_all_itinerary(id,db):
    try: 
        results = (
            db.query(
                Itinerary.itinerary_id,
                Itinerary.title,
                Itinerary.start_date,
                Itinerary.end_date,
                Location.name.label("location_name"),
                Itinerary.created_at
            )
            .join(Location, Itinerary.location_id == Location.location_id)
            .filter(Itinerary.user_id == id)
            .all()
        )

        response = []
        for r in results:
            response.append({
                "itinerary_id":r.itinerary_id,
                "title": r.title,
                "start_date": r.start_date,
                "end_date": r.end_date,
                "location_id": r.location_name,
                "created_at": r.created_at.strftime("%Y-%m-%d")  # only date part
            })

        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"failed to get all itinerary, {e}" )
        
def update_item_description(payload, db):
    try:
        item = get_itinerary_item(payload.itinerary_item_id, db)
        item.description = payload.description
        return "description updated successfully"
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail= f"error occured while updating item description. error = {e}")
     
def update_item_cost(payload, db):
    try:
        item = get_itinerary_item(payload.itinerary_item_id, db)
        item.cost = payload.cost
        return "cost updated successfully"
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail= f"error occured while updating item description. error = {e}")


async def update_item_duration(payload, session: AsyncSession):
    try:
        item = await get_item(payload.itinerary_item_id, session)  # assume this is async
        item.stay_duration = payload.stay_duration
        await session.commit()

        stmt = (
            select(ItineraryItem)
            .where(ItineraryItem.itinerary_day_id == item.itinerary_day_id)
            .where(ItineraryItem.order_index >= item.order_index)
            .order_by(asc(ItineraryItem.order_index))
        )
        result = await session.execute(stmt)
        ordered_items = result.scalars().all()

        if ordered_items:
            await recalculate_itinerary_timings(ordered_items, session)  # assume this is async

        return item

    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error occurred while updating item duration. Error = {e}"
        )


async def delete_item(itinerary_item_id: int, session: AsyncSession):
    try:
        item = await get_item(itinerary_item_id, session)

        # Get previous item (highest order_index less than current item's)
        stmt_prev = (
            select(ItineraryItem)
            .where(ItineraryItem.itinerary_day_id == item.itinerary_day_id)
            .where(ItineraryItem.order_index < item.order_index)
            .order_by(desc(ItineraryItem.order_index))
            .limit(1)
        )
        result_prev = await session.execute(stmt_prev)
        previous_item = result_prev.scalar_one_or_none()

        # Get next items (order_index greater than current item's)
        stmt_next = (
            select(ItineraryItem)
            .where(ItineraryItem.itinerary_day_id == item.itinerary_day_id)
            .where(ItineraryItem.order_index > item.order_index)
            .order_by(asc(ItineraryItem.order_index))
        )
        result_next = await session.execute(stmt_next)
        all_next_items = result_next.scalars().all()

        ordered_items = []
        if previous_item:
            ordered_items.append(previous_item)
        ordered_items.extend(all_next_items)

        await session.delete(item)
        await session.commit()

        if ordered_items:
            await recalculate_itinerary_timings(ordered_items, session)

        return "Item deleted successfully"

    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error occurred while deleting item. Error = {e}"
        )


def day_cost_breakup(day_id, db):
    try:
        items = db.query(ItineraryItem.type, ItineraryItem.cost).filter(ItineraryItem.itinerary_day_id == day_id).all()

        cost_summary = defaultdict(lambda: {"total_cost": 0, "total_quantity": 0, "valid_quantity":0,"is_complete":True })

        is_first_item = True
        # Aggregating cost and quantity per type
        for item_type, cost in items:
            if is_first_item:
                is_first_item = False
                continue
            cost_summary[item_type]["total_quantity"] +=1
            if cost is None or 0:
                cost_summary[item_type]["is_complete"]= False
            else:
                cost_summary[item_type]["total_cost"] += cost
                cost_summary[item_type]["valid_quantity"] += 1
            

        # Preparing the final response
        result = []
        for item_type, data in cost_summary.items():
            # if item_type == "starting_point" or cost_summary[0]:
            #     continue
            valid_qty = data["valid_quantity"]
            avg_rate = round(data["total_cost"] / valid_qty, 2) if valid_qty else None
            sub_total = data["total_cost"] if valid_qty else 0

            result.append({
                "item_type": item_type,
                "total_quantity":data["total_quantity"],
                "valid_quantity": data["valid_quantity"],
                "avg_rate": avg_rate,
                "sub_total": sub_total,
                "is_complete": data["is_complete"]
            })

        return {"day_id": day_id, "cost_breakup": result}

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch day cost breakup details: {str(e)}")
    

def itinerary_cost_breakup(itinerary_id, db):
    try:
        day_ids = db.query(ItineraryDays.itinerary_day_id).filter(
            ItineraryDays.itinerary_id == itinerary_id
        ).all()

        if not day_ids:
            raise HTTPException(status_code=404, detail="No days found for this itinerary")

        # Flatten from [(id1,), (id2,), ...] to [id1, id2, ...]
        day_ids = [day_id for (day_id,) in day_ids]

        # Get cost breakup for each day
        all_breakups=[]
        for day_id in day_ids:
            cost_breakup = day_cost_breakup(day_id, db)
            all_breakups.append(cost_breakup)
        # cost_breakups = [day_cost_breakup(day_id, db) for day_id in day_ids]

        return {
            "itinerary_id": itinerary_id,
            "cost_breakup_by_day": all_breakups
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch itinerary cost breakup details: {str(e)}"
        )


def get_local_resource(user_id, resource_type,db):
    try:
        user= fetch_by_user_id(db,user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found for adding default timing")
        if resource_type == "hotel":
            resource = db.query(Hotel).filter(Hotel.user_id == user_id).all()
        if resource_type == "restaurant":
            resource = db.query(Restaurant).filter(Restaurant.user_id == user_id).all()
        # if resource_type == "place":
        #     resource = db.query(Place).filter(Place.user_id == user_id).all()
        return resource
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to fetch local resource: {str(e)}"
        )


    
def get_shared_itinerary(share_code, db):
    itinerary = db.query(ItineraryShareCode).filter(ItineraryShareCode.share_code == share_code).first()
    if not itinerary:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    return itinerary.itinerary_id  

def get_share_code(itinerary_id, db):
    share_entry = db.query(ItineraryShareCode).filter(ItineraryShareCode.itinerary_id == itinerary_id).first()
    if not share_entry or not share_entry.share_code:
        raise HTTPException(status_code=404, detail="Share code not found for this itinerary")
    return share_entry.share_code
