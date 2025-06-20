from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime, date, time

# Base schemas for creating related records
class ItineraryInfoBase(BaseModel):
    day_count: int
    stop_name: str
    eta: Optional[time] = None
    description: Optional[str] = None

class EventPlanBase(BaseModel):
    client_id: Optional[str] = None
    booking_start_date: Optional[date] = None
    booking_end_date: Optional[date] = None
    tour_start_date: Optional[date] = None
    tour_end_date: Optional[date] = None
    status: Optional[str] = None
    created_by: Optional[int] = None
    instruction_for_trip: Optional[str] = None

class StopSettingBase(BaseModel):
    day_start_time: Optional[time] = None
    hotel_duration: Optional[int] = None
    activity_duration: Optional[int] = None
    restaurant_duration: Optional[int] = None

class CategorySchema(BaseModel):
    category_id: int
    name: str
    description: Optional[str]

    class Config:
        from_attributes = True

class EventInCategorySchema(BaseModel):
    id: int  # ID from event_in_category
    event_id: int
    category_id: int

    class Config:
        from_attributes = True


# Base schema
class RoomBedPricingBase(BaseModel):
    no_of_days: Optional[int]
    room_type: Optional[str]
    bed_count: Optional[int]
    price_per_head_per_day: Optional[int]
    price_per_head_trip: Optional[int]
    total_rooms: Optional[int]
    remarks: Optional[str]

# Create schema
class RoomBedPricingCreate(RoomBedPricingBase):
    event_id: int

# Response schema
class RoomBedPricingSchema(RoomBedPricingBase):
    room_bed_id: int
    event_id: int
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

# Complete event creation schema
class EventCreate(BaseModel):
    # Main event details
    user_id: int
    title: str
    tour_category: Optional[str] = None
    tour_per_head_price: Optional[float] = None
    tour_capacity: Optional[int] = None
    description: Optional[str] = None
    booking_per: Optional[str] = None
    destination: Optional[str] = None
    number_of_nodes: Optional[int] = None
    itinerary_info: Optional[str] = None
    images: Optional[str] = None
    videos: Optional[str] = None
    status: Optional[str] = None
    client_id: Optional[int] = None
    instruction_for_trip: Optional[str] = None
    tour_duration: Optional[int] = None
    
    # Related records
    itineraries: Optional[List[ItineraryInfoBase]] = []
    event_plans: Optional[List[EventPlanBase]] = []
    stop_settings: Optional[List[StopSettingBase]] = []
    category_ids: Optional[List[int]] = []
    room_bed_pricing: Optional[List[RoomBedPricingBase]] = []

# Response schemas (for returning data)
class ItineraryInfoSchema(ItineraryInfoBase):
    itinerary_id: int
    event_id: int
    
    class Config:
        from_attributes = True

class EventPlanSchema(EventPlanBase):
    ep_id: int
    event_id: int
    booking_start_date: Optional[date] = None
    booking_end_date: Optional[date] = None
    tour_start_date: Optional[date] = None
    tour_end_date: Optional[date] = None
    status: Optional[str] = None
    client_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    instruction_for_trip: Optional[str] = None
    class Config:
        from_attributes = True

class StopSettingSchema(StopSettingBase):
    stop_setting_id: int
    event_id: int
    
    class Config:
        from_attributes = True

class EventSchema(BaseModel):
    event_id: int
    user_id: int
    title: str
    tour_category: Optional[str] = None
    tour_per_head_price: Optional[float] = None
    tour_capacity: Optional[int] = None
    description: Optional[str] = None
    booking_per: Optional[str] = None
    destination: Optional[str] = None
    number_of_nodes: Optional[int] = None
    itinerary_info: Optional[str] = None
    images: Optional[str] = None
    videos: Optional[str] = None
    status: Optional[str] = None
    client_id: Optional[int] = None
    client_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    instruction_for_trip: Optional[str] = None
    display_sequence: Optional[float] = None
    tour_duration: Optional[int] = None
    
    # Related records
    itineraries: List[ItineraryInfoSchema] = []
    event_plans: List[EventPlanSchema] = []
    stop_settings: List[StopSettingSchema] = []
    categories: List[CategorySchema] = []
    room_bed_pricings: List[RoomBedPricingSchema] = []
    
    class Config:
        from_attributes = True

class BasicEventSchema(BaseModel):
    event_id: int
    title: str
    client_id: Optional[int] = None
    client_url: Optional[str] = None
    tour_capacity: Optional[int] = None
    tour_duraton: Optional[int] = None
    class Config:
        from_attributes = True

class EventUpdate(BaseModel):
    event_id: int
    user_id: int
    title: str
    tour_category: Optional[str] = None
    tour_per_head_price: Optional[float] = None
    tour_capacity: Optional[int] = None
    description: Optional[str] = None
    booking_per: Optional[str] = None
    destination: Optional[str] = None
    number_of_nodes: Optional[int] = None
    itinerary_info: Optional[str] = None
    images: Optional[str] = None
    videos: Optional[str] = None
    status: Optional[str] = None
    client_id: Optional[int] = None
    instruction_for_trip: Optional[str] = None
    tour_duration: Optional[int] = None

class EventAddDisplaySequence(BaseModel):
    event_id: int
    display_sequence: float
class EventSequenceUpdate(BaseModel):
    event_id: int
    display_sequence: Optional[float] = None

class ItineraryUpdate(ItineraryInfoBase):
    itinerary_id: int
    event_id: int

class EventPlanUpdate(EventPlanBase):
    ep_id: int
    event_id: int

class StopSettingUpdate(StopSettingBase):
    stop_setting_id: int
    event_id: int

class EventInCategoryUpdate(BaseModel):
    id: int  # ID from event_in_category
    event_id: int
    category_id: int

class CategoryWithEventsSchema(BaseModel):
    category_id: int
    name: str
    description: Optional[str] = None
    events: List[EventSchema] = []

    class Config:
        from_attributes = True