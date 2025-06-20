from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from schemas.booking import CreateEventBookingRooms, EventBookingRoomsResponse, CreateReservationEvent, ReservationEventResponse, CreateTravellerInfo, TravellerInfoResponse, AllBookingDetailsResponse, CreateOrderRequest
from models.booking import ReservationEvent, TravellerInfo, EventBookingRooms
from schemas.events import EventSchema
from models.events import EventInfo, EventPlan
from models.client import Client
from repository import booking as booking_repo
from repository import events as event_repo
from typing import List
import razorpay

def generate_booking(
    reservation_event: CreateReservationEvent,
    traveller_info: list[CreateTravellerInfo],
    booking_rooms: list[CreateEventBookingRooms],
    payment_id: str,
    db: Session
):
    try:
        # Create reservation event and get the new ID
        reservation_event.payment_id = payment_id
        new_reservation_event = booking_repo.create_reservation_event(db, reservation_event)
        reservation_event_id = new_reservation_event.reservation_event_id

        # Assign reservation_event_id to each traveller
        for traveller in traveller_info:
            traveller.reservation_event_id = reservation_event_id

        # Save traveller info list (assuming your repo supports batch insert)
        new_traveller_info = booking_repo.create_traveller_info(db, traveller_info)

        # Assign reservation_event_id to each booking room
        for room in booking_rooms:
            room.reservation_event_id = reservation_event_id

        # Save booking rooms list
        new_booking_rooms = booking_repo.create_event_booking_rooms(db, booking_rooms)

        return {
            "reservation_event": ReservationEventResponse.from_orm(new_reservation_event),
            "traveller_info": [TravellerInfoResponse.from_orm(t) for t in new_traveller_info],
            "event_booking_rooms": [EventBookingRoomsResponse.from_orm(r) for r in new_booking_rooms],
        }
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error occurred: {str(e)}"
        ) from e

def get_reservation_events_by_client_url(client_url: str, db: Session):
    try:
        client = db.query(Client).filter(Client.url == client_url).first()

        if not client:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client not found")
        else:
            client_events = (
                db.query(ReservationEvent)
                .join(EventInfo, ReservationEvent.event_id == EventInfo.event_id)
                .filter(EventInfo.client_id == client.client_id)
                .all()
            )
            return client_events
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error occurred: {str(e)}"
        ) from e
    
def get_reservation_events_by_client_id(client_id: int, db: Session):
    try:
        client = db.query(Client).filter(Client.client_id == client_id).first()
        if not client:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client not found")

        client_events = (
            db.query(ReservationEvent)
            .join(EventInfo, ReservationEvent.event_id == EventInfo.event_id)
            .filter(EventInfo.client_id == client.client_id)
            .all()
        )

        if not client_events:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No bookings found for this client")

        booking_details_list = []

        for event in client_events:
            traveller_info = booking_repo.get_traveller_info_by_reservation_event_id(db, event.reservation_event_id)
            room_bed_info = booking_repo.get_event_booking_rooms_by_reservation_event_id(db, event.reservation_event_id)

            response = AllBookingDetailsResponse(
                reservation_event=ReservationEventResponse.model_validate(event),
                traveller_info=[TravellerInfoResponse.model_validate(t) for t in traveller_info],
                event_booking_rooms=[EventBookingRoomsResponse.model_validate(r) for r in room_bed_info]
            )
            booking_details_list.append(response)

        return booking_details_list

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error occurred: {str(e)}"
        ) from e
    
def get_reservation_events_by_user_id(user_id: int, db: Session):
    try:
        reservation_events = booking_repo.get_reservation_event_by_user_id(db, user_id)
        if not reservation_events:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No bookings found for this user")
        
        result = []
        for event in reservation_events:
            traveller_info = booking_repo.get_traveller_info_by_reservation_event_id(db, event.reservation_event_id)
            booking_rooms = booking_repo.get_event_booking_rooms_by_reservation_event_id(db, event.reservation_event_id)
            
            result.append({
                "reservation_event": ReservationEventResponse.from_orm(event),
                "traveller_info": [TravellerInfoResponse.from_orm(t) for t in traveller_info],
                "event_booking_rooms": [EventBookingRoomsResponse.from_orm(r) for r in booking_rooms],
            })

        return result

    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database error occurred: {str(e)}"
        ) from e


def get_reservation_details(reservation_event_id: int, db: Session):
    try:
        reservation_event = booking_repo.get_reservation_event_by_id(db, reservation_event_id)
        if not reservation_event:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation event not found")
        
        traveller_info = booking_repo.get_traveller_info_by_reservation_event_id(db, reservation_event_id)
        booking_rooms = booking_repo.get_event_booking_rooms_by_reservation_event_id(db, reservation_event_id)
        
        return AllBookingDetailsResponse(
            reservation_event=ReservationEventResponse.from_orm(reservation_event),
            traveller_info=[TravellerInfoResponse.from_orm(info) for info in traveller_info],
            booking_rooms=[EventBookingRoomsResponse.from_orm(room) for room in booking_rooms]
        )
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Database error occurred") from e
    
def get_reservation_details_by_event_plan_id(event_plan_id: int, db: Session):
    try:
        reservation_event = booking_repo.get_reservation_event_by_event_plan_id(db, event_plan_id)
        if not reservation_event:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation event not found")
        
        traveller_info = booking_repo.get_traveller_info_by_reservation_event_id(db, reservation_event.reservation_event_id)
        booking_rooms = booking_repo.get_event_booking_rooms_by_reservation_event_id(db, reservation_event.reservation_event_id)
        
        return AllBookingDetailsResponse(
            reservation_event=ReservationEventResponse.from_orm(reservation_event),
            traveller_info=[TravellerInfoResponse.from_orm(info) for info in traveller_info],
            booking_rooms=[EventBookingRoomsResponse.from_orm(room) for room in booking_rooms]
        )
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Database error occurred") from e
    
def get_reservation_details_by_user_id(user_id: int, db: Session):
    try:
        reservation_event = booking_repo.get_reservation_event_by_user_id(db, user_id)
        if not reservation_event:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reservation event not found")
        
        traveller_info = booking_repo.get_traveller_info_by_reservation_event_id(db, reservation_event.reservation_event_id)
        booking_rooms = booking_repo.get_event_booking_rooms_by_reservation_event_id(db, reservation_event.reservation_event_id)
        
        return AllBookingDetailsResponse(
            reservation_event=ReservationEventResponse.from_orm(reservation_event),
            traveller_info=[TravellerInfoResponse.from_orm(info) for info in traveller_info],
            booking_rooms=[EventBookingRoomsResponse.from_orm(room) for room in booking_rooms]
        )
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Database error occurred") from e
    
def get_available_beds(event_plan_id: int, db: Session):
    try:
        event_plan = event_repo.get_event_plan_by_id(db, event_plan_id)
        if not event_plan:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event plan not found")
        
        room_bed_pricing = event_repo.get_room_bed_pricing_by_event_id(db, event_plan.event_id)
        if not room_bed_pricing:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room bed pricing not found")
        
        available_beds = []
        for pricing in room_bed_pricing:
            available_beds.append({
                "room_bed_id": pricing.room_bed_id,
                "available_beds": pricing.available_beds
            })
        
        return available_beds
    except SQLAlchemyError as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Database error occurred") from e
    
# class CreateOrder(BaseModel):
#     amount: int

# import razorpay


razorpay_client = razorpay.Client(auth=("rzp_test_0nH69rvztCJPB7", "yLIe1FImY102rMjAzjEYKEMV"))

def create_order(request: CreateOrderRequest, currency: str = "INR"):
    order = razorpay_client.order.create({
        "amount": request.amount * 100,  # Razorpay works with paise
        "currency": currency,
        "payment_capture": 1
    })
    return {"order_id": order["id"]}

def verify_payment(data: dict):
    params_dict = {
        "razorpay_order_id": data["order_id"],
        "razorpay_payment_id": data["payment_id"],
        "razorpay_signature": data["signature"]
    }
    try:
        razorpay_client.utility.verify_payment_signature(params_dict)
    except razorpay.errors.SignatureVerificationError as e:
        raise HTTPException(status_code=400, detail=f"Payment verification failed, error: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error during payment verification, error: {e}")