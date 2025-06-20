from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlalchemy.orm import Session
from core.database import get_db
from repository import booking as booking_repo
from services import booking as booking_service
from schemas.booking import CreateEventBookingRooms, CreateReservationEvent, CreateTravellerInfo, BookingRequest, EventBookingRoomsResponse, ReservationEventResponse, TravellerInfoResponse, AllBookingDetailsResponse, CreateOrderRequest

router = APIRouter(prefix="/api/bookings", tags=["Bookings"])


@router.post("/", response_model=AllBookingDetailsResponse, status_code=status.HTTP_201_CREATED)
def generate_booking(payload: BookingRequest, payment_id: str, db: Session = Depends(get_db)):
    try:
        new_booking = booking_service.generate_booking(
            reservation_event=payload.reservation_event,
            traveller_info=payload.traveller_info,
            booking_rooms=payload.booking_rooms,
            payment_id=payment_id,
            db=db
        )
        return new_booking
    except HTTPException as e:
        raise e


@router.put("/{reservation_event_id}", response_model=ReservationEventResponse)
def update_booking(reservation_event_id: int, payload: CreateReservationEvent, db: Session = Depends(get_db)):
    try:
        updated_booking = booking_repo.update_reservation_event(db, reservation_event_id, payload)
        if not updated_booking:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
        return ReservationEventResponse.from_orm(updated_booking)
    except HTTPException as e:
        raise e

@router.get("/get_by_client_url/{client_url}", response_model=List[ReservationEventResponse])
def get_reservation_events_by_client_url(client_url: str, db: Session = Depends(get_db)):
    try:
        reservation_events = booking_service.get_reservation_events_by_client_url(client_url, db)
        if not reservation_events:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No bookings found for this client")
        return [ReservationEventResponse.from_orm(event) for event in reservation_events]
    except HTTPException as e:
        raise e
    
@router.get("/get_by_client_id/{client_id}", response_model=List[AllBookingDetailsResponse])
def get_reservation_events_by_client_url(client_id: int, db: Session = Depends(get_db)):
    try:
        reservation_events = booking_service.get_reservation_events_by_client_id(client_id, db)
        if not reservation_events:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No bookings found for this client")
        return reservation_events
    except HTTPException as e:
        raise e
    
@router.get("/get_by_user_id/{user_id}", response_model=List[AllBookingDetailsResponse])
def get_reservation_events_by_user_id(user_id: int, db: Session = Depends(get_db)):
    try:
        reservation_events = booking_service.get_reservation_events_by_user_id(user_id, db)
        if not reservation_events:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No bookings found for this user")
        return [AllBookingDetailsResponse.from_orm(event) for event in reservation_events]
    except HTTPException as e:
        raise e
    
@router.get("/available_slots/{event_plan_id}")
def get_available_slots(event_plan_id: int, db: Session = Depends(get_db)):
    try:
        available_slots = booking_service.get_available_slots(event_plan_id, db)
        if not available_slots:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No available slots found for this event plan")
        return available_slots
    except HTTPException as e:
        raise e

@router.post("/create-order")
def create_payment_order(request: CreateOrderRequest, db: Session = Depends(get_db)):
    order = booking_service.create_order(request)
    return order
@router.post("/verify-payment")
def verify_payment_endpoint(payment_data: dict, db: Session = Depends(get_db)):
    try:
        print(f"Verifying payment with data: {payment_data}")
        
        # Verify payment first
        booking_service.verify_payment(payment_data)
        
        # Get payment ID
        payment_id = payment_data["payment_id"]
        
        # Extract booking payload from the request (similar to your working code)
        booking_payload = payment_data.get("booking_payload")
        if not booking_payload:
            raise HTTPException(status_code=400, detail="Booking payload missing")
        
        # Convert dictionary data to Pydantic models
        reservation_event = CreateReservationEvent(**booking_payload["reservation_event"])
        
        # Convert traveller_info list of dicts to list of Pydantic models
        traveller_info = [CreateTravellerInfo(**traveller) for traveller in booking_payload["traveller_info"]]
        
        # Convert booking_rooms list of dicts to list of Pydantic models
        booking_rooms = [CreateEventBookingRooms(**room) for room in booking_payload["booking_rooms"]]
        
        # Create booking after successful payment verification
        new_booking = booking_service.generate_booking(
            reservation_event=reservation_event,
            traveller_info=traveller_info,
            booking_rooms=booking_rooms,
            payment_id=payment_id,
            db=db
        )
        
        return {
            "status": "success",
            "payment_id": payment_id,
            "booking_data": new_booking,
            "message": "Payment verified & booking successful!"
        }
        
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Payment verification or booking creation failed: {str(e)}"
        )