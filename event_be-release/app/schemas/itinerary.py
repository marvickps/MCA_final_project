import enum
from pydantic import BaseModel
from datetime import date, datetime, time
from typing import Optional, Literal, List
from typing import Optional, Literal, List
from decimal import Decimal

class ItineraryInput(BaseModel):
    user_id:int
    itineraryName:str
    itineraryPlaceID: str
    startDate: date
    endDate: date
    startingPoint: str
    accommodation: str


class ItemType(str, enum.Enum):
    HOTEL = "hotel"
    RESTAURANT = "restaurant"
    PLACE = "place"
    STARTING_POINT = "starting_point"


class ItineraryBase(BaseModel):
    title: Optional[str] = None
    user_id: Optional[int] = None
    location_id: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    starting_point: Optional[int] = None

class ItineraryCreate(ItineraryBase):
    created_at: Optional[datetime]  # Or use datetime if you're going to parse it properly

class Itinerary(ItineraryBase):
    # itinerary_id: int
    pass
    class Config:
        from_attributes = True


class ItineraryDay(BaseModel):
    itinerary_id: int
    daynumber: int
    date: date

class ItineraryItem(BaseModel):
    itinerary_day_id: int
    time: Optional[time]
    distance_from_previous_stop: Optional[Decimal]
    duration_from_previous_stop : Optional[Decimal]
    order_index: Optional[int] 
    type: ItemType
    hotel_id: Optional[int] 
    restaurant_id: Optional[int]
    p_id: Optional[int]
    cost: Optional[int]
    stay_duration: Optional[int]
    description: Optional[str]


class ItineraryItemResponse(BaseModel):
    itinerary_item_id: int
    itinerary_day_id: int
    time: time
    distance_from_previous_stop: int
    duration_from_previous_stop: int
    order_index: int
    type: str
    hotel_id: int | None
    restaurant_id: int | None
    p_id: int | None
    stay_duration: int
    cost: float | None

    class Config:
        from_attributes = True

class ItineraryItemCreate(ItineraryItem):
    pass

class ItineraryItemOut(ItineraryItem):
    id: int

    class Config:
        from_attributes = True

class AddItineraryItem(BaseModel): 
    itinerary_day_id: int
    user_id:int
    place_id: str
    type: str

class StopUpdate(BaseModel):
    stop_id: int 
    order: int

class ItineraryItemStopUpdate(BaseModel):
    itinerary_day_id: int
    stops: List[StopUpdate]


# schema for edit itinerary item
class UpdateItemDuration(BaseModel):
    itinerary_item_id: int
    stay_duration: int

class UpdateItemCost(BaseModel):
    itinerary_item_id: int
    cost: int

class UpdateItemDescription(BaseModel):
    itinerary_item_id: int
    description: str
    class Config:
        from_attributes = True  #


class PackageData(BaseModel):
    package_id: int
    package_name: str
    package_detail: str
    people_count :int
    highlights: str
    image_url : str
    vehicle_id: int
    Itinerary_id: int
    cost: Decimal
 
class CreatePackage(BaseModel):
    package_name: str
    package_detail: str
    people_count :int
    highlights: str
    image_url : str
    vehicle_id: int
    Itinerary_id: int
    cost: Decimal

class GetPackageDetail(BaseModel):
    package_id:  int
    package_name: str
    location : str
    description: str
    highlights: str
    days: int
    people_count: int
    total_distance: int
    total_stops: int
    vehicle_type : str
    hotel_rating: Decimal
    image_url : str
    itinerary_id: int
    cost: Decimal
    created_at: datetime
    updated_at: datetime



class GetPackageList(BaseModel):
    packages: List[GetPackageDetail]


class DefaultTime(BaseModel):
    user_id: int 
    departure_time: time
    hotel_duration: int
    restaurant_duration : int
    place_duration : int

class CostTransparency(BaseModel):
    pass

class CostItem(BaseModel):
    title: str
    unit_price: str  # e.g., "₹1000 /D (300km)"
    quantity: int
    total_price: int

class CostSummary(BaseModel):  # Renamed for clarity, optional
    total_base_cost: int  # was `sub_total`
    discount_percentage: int
    discount_amount: int
    gst_percentage: int
    gst_amount: int
    grand_total: int  # was `final_amount`

class PackageCostDetailsResponse(BaseModel):
    cost_items: List[CostItem]
    day_label: Optional[str] = None
    cost_summary: CostSummary
