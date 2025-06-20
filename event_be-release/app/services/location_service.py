# app/services/hotel_service.py
from fastapi import Depends, HTTPException
import httpx
import requests
from sqlalchemy.ext.asyncio import AsyncSession

# from services.google_maps_service import get_place_details
from models.location_modal import Location
from sqlalchemy.orm import Session
from core.config import GOOGLE_MAPS_API_KEY


async def create_location_from__google_maps_api(itineraryPlaceID:str, session:AsyncSession) -> Location:
    url = f"https://maps.googleapis.com/maps/api/place/details/json?place_id={itineraryPlaceID}&key={GOOGLE_MAPS_API_KEY}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        result = response.json()

    if result["status"] != "OK":
        raise HTTPException(status_code=400, detail="failed to fetch place details")
    
    place = result["result"]
    name = place.get("name","")
    address = place.get("formatted_address","")
    latitude= place["geometry"]["location"]["lat"]
    longitude= place["geometry"]["location"]["lng"]

    location = Location(
        place_id=itineraryPlaceID,
        name = name,
        address= address,
        latitude = latitude,
        longitude = longitude
    )
    session.add(location)
    await session.flush()
    await session.refresh(location)

    return location