from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class CreateTravellerInfo(BaseModel):
    reservation_event_id: Optional[int] = None
    full_name: str
    id_proof: Optional[str] = None
    medical_needs: Optional[str] = None
    meal_preference: Optional[str] = None
    emergency_contact: Optional[str] = None
    user_id: Optional[int] = None
    event_plan_id: Optional[int] = None

class TravellerInfoResponse(BaseModel):
    traveller_id: int
    reservation_event_id: Optional[int] = None
    full_name: str
    id_proof: Optional[str] = None
    medical_needs: Optional[str] = None
    meal_preference: Optional[str] = None
    emergency_contact: Optional[str] = None
    created_at: datetime
    user_id: Optional[int] = None
    event_plan_id: Optional[int] = None

    class Config:
        from_attributes = True

class CreateEventBookingRooms(BaseModel):
    reservation_event_id: Optional[int] = None
    room_bed_id: int
    number_of_travelers: int
    price_per_head_trip: float
    total_price: int
    selected_beds_quantity: Optional[int] = None
    user_id: Optional[int] = None
    event_plan_id: Optional[int] = None

class EventBookingRoomsResponse(BaseModel):
    booking_room_id: int
    reservation_event_id: Optional[int] = None
    room_bed_id: int
    number_of_travelers: int
    price_per_head_trip: float
    total_price: int
    created_at: datetime
    selected_beds_quantity: Optional[int] = None
    user_id: Optional[int] = None
    event_plan_id: Optional[int] = None

    class Config:
        from_attributes = True

class CreateReservationEvent(BaseModel):
    event_id: int
    event_plan_id: int
    user_id: int
    total_travelers: Optional[int] = None
    total_price: Optional[int] = None
    payment_status: Optional[str] = None
    advance_paid: Optional[int] = None
    booking_status: Optional[str] = None
    payment_reference: Optional[str] = None
    payment_id: Optional[str] = None

class ReservationEventResponse(BaseModel):
    reservation_event_id: int
    event_id: int
    event_plan_id: int
    total_travelers: Optional[int] = None
    total_price: Optional[int] = None
    payment_status: Optional[str] = None
    advance_paid: Optional[int] = None
    booking_status: Optional[str] = None
    special_requests: Optional[str] = None
    booking_date: datetime
    payment_reference: Optional[str] = None
    invoice_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    user_id: Optional[int] = None
    payment_id: Optional[str] = None

    class Config:
        from_attributes = True

class AllBookingDetailsResponse(BaseModel):
    reservation_event: ReservationEventResponse
    traveller_info: List[TravellerInfoResponse]
    event_booking_rooms: List[EventBookingRoomsResponse]

    class Config:
        from_attributes = True

class BookingRequest(BaseModel):
    reservation_event: CreateReservationEvent
    traveller_info: List[CreateTravellerInfo]
    booking_rooms: List[CreateEventBookingRooms]

class CreateOrderRequest(BaseModel):
    amount: float