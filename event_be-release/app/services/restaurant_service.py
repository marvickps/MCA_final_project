# app/services/hotel_service.py
from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

import httpx
# from services.google_maps_service import get_place_details
from models.restaurant_modal import Restaurant
from sqlalchemy.orm import Session
from core.config import GOOGLE_MAPS_API_KEY


async def create_restaurant_from_google_maps_api(user_id:int, place_id:str, session: AsyncSession) -> Restaurant:
    url = f"https://maps.googleapis.com/maps/api/place/details/json?place_id={place_id}&key={GOOGLE_MAPS_API_KEY}"
    # url = f"https://places.googleapis.com/v1/places/{accommodation}?fields=*&key={GOOGLE_MAPS_API_KEY}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        result = response.json()

    if result["status"] != "OK":
        raise HTTPException(status_code=400, detail="failed to fetch place details")
    
    data = result["result"]
    name = data.get("name", "")
    address = data.get("formatted_address", "")
    latitude = data["geometry"]["location"]["lat"]
    longitude= data["geometry"]["location"]["lng"]
    rating= data.get("rating",0.0)
    photo_url =""

    if "photos" in data:
        photo_ref = data["photos"][0]["photo_reference"]
        photo_url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={GOOGLE_MAPS_API_KEY}"

    #store hotel in database

    restaurant = Restaurant(
        place_id=place_id,
        user_id=user_id,
        name=name,
        address=address,
        latitude=latitude,
        longitude=longitude,
        rating=rating,
        photo_url=photo_url

    )
    session.add(restaurant)
    await session.flush()
    await session.refresh(restaurant)

    return restaurant
    
