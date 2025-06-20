from fastapi import HTTPException
import httpx
import requests
from api.routes.google_maps_router import GOOGLE_MAPS_DETAILS_URL
from core.config import GOOGLE_MAPS_API_KEY

async def create_hotel_from_google_maps_api(accommodation: str) -> dict:
    try:
        url = f"https://maps.googleapis.com/maps/api/place/details/json?place_id={accommodation}&key={GOOGLE_MAPS_API_KEY}"
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, timeout=10.0)
            response.raise_for_status()
            
        result = response.json()

        if result.get("status") != "OK":
            raise HTTPException(
                status_code=400, 
                detail=f"Google Maps API error: {result.get('status', 'Unknown error')}"
            )
        
        data = result["result"]
        google_data = {
            "name": data.get("name", ""),
            "address": data.get("formatted_address", ""),
            "latitude": data["geometry"]["location"].get("lat", 0.0),
            "longitude": data["geometry"]["location"].get("lng", 0.0),
            "rating": data.get("rating", 0.0),
            "photo_url": ""
        }

        if photos := data.get("photos"):
            photo_ref = photos[0].get("photo_reference")
            if photo_ref:
                google_data["photo_url"] = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={GOOGLE_MAPS_API_KEY}"

        return google_data
        
    except httpx.HTTPError as e:
        raise HTTPException(status_code=503, detail=f"Failed to contact Google Maps API: {str(e)}")
    except KeyError as e:
        raise HTTPException(status_code=500, detail=f"Invalid response format: {str(e)}")
    
async def get_distance_matrix_details(origin: str, destination:str):
    url = f"https://maps.googleapis.com/maps/api/distancematrix/json?destinations=place_id:{destination}&mode=driving&origins=place_id:{origin}&key={GOOGLE_MAPS_API_KEY}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code != 200:
            raise Exception(f"distance calculation error : {response.status_code} - {response.text}")
        data = response.json()

        elements = data["rows"][0]["elements"][0]

        return  {
            "distance" : elements["distance"]["value"],
            "duration": elements["duration"]["value"]
        }

async def get_place_details(place_id: str) -> dict :
    url=f"{GOOGLE_MAPS_DETAILS_URL}{place_id}?fields=id,displayName,location,formattedAddress,rating,photos&key={GOOGLE_MAPS_API_KEY}"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        if response.status_code !=200:
            raise Exception(f"Google API error : {response.status_code} - {response.text}")
        return response.json()