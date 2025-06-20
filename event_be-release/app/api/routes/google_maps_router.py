from fastapi import APIRouter
import requests 
from core.config import GOOGLE_MAPS_API_KEY

GOOGLE_MAPS_DETAILS_URL = "https://places.googleapis.com/v1/places/"
router = APIRouter(
    prefix='/googlemap',
    tags=['maps api'] 
)

@router.post('/getdetail')
def get_place_details(place_id: str) -> dict :
    url=f"{GOOGLE_MAPS_DETAILS_URL}{place_id}?fields=id,displayName,location,formattedAddress,rating,photos&key={GOOGLE_MAPS_API_KEY}"
    response = requests.get(url)

    if response.status_code !=200:
        raise Exception(f"Google API error : {response.status_code} - {response.text}")
    return response.json()

@router.post('/get_distance_data')
def get_distance_matrix_details(origin: str, destination:str):
    url = f"https://maps.googleapis.com/maps/api/distancematrix/json?destinations=place_id:{destination}&mode=driving&origins=place_id:{origin}&key={GOOGLE_MAPS_API_KEY}"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"distance calculation error : {response.status_code} - {response.text}")
    data = response.json()

    elements = data["rows"][0]["elements"][0]

    return  {
        "distance" : elements["distance"]["value"],
        "duration": elements["duration"]["value"]
    }

