from sqlalchemy.orm import Session
from models.booking import ReservationEvent, TravellerInfo, EventBookingRooms
from schemas.booking import CreateReservationEvent, ReservationEventResponse, CreateTravellerInfo, TravellerInfoResponse, CreateEventBookingRooms, EventBookingRoomsResponse, AllBookingDetailsResponse
from typing import List

def get_all_reservation_events(db: Session, skip: int = 0):
    reservation_events = db.query(ReservationEvent).offset(skip).all()
    return reservation_events

def get_reservation_event_by_id(db: Session, reservation_event_id: int):
    reservation_event = db.query(ReservationEvent).filter(ReservationEvent.reservation_event_id == reservation_event_id).first()
    return reservation_event

def get_reservation_event_by_user_id(db: Session, user_id: int):
    reservation_event = db.query(ReservationEvent).filter(ReservationEvent.user_id == user_id).all()
    return reservation_event

def get_reservation_event_by_event_id(db: Session, event_id: int):
    reservation_event = db.query(ReservationEvent).filter(ReservationEvent.event_id == event_id).all()
    return reservation_event

def get_reservation_event_by_event_plan_id(db: Session, event_plan_id: int):
    reservation_event = db.query(ReservationEvent).filter(ReservationEvent.event_plan_id == event_plan_id).all()
    return reservation_event

def create_reservation_event(db: Session, reservation_event: CreateReservationEvent):
    db_reservation_event = ReservationEvent(**reservation_event.dict())
    db.add(db_reservation_event)
    db.commit()
    db.refresh(db_reservation_event)
    return db_reservation_event

def update_reservation_event(db: Session, reservation_event_id: int, reservation_event: CreateReservationEvent):
    db_reservation_event = db.query(ReservationEvent).filter(ReservationEvent.reservation_event_id == reservation_event_id).first()
    if not db_reservation_event:
        return None
    for key, value in reservation_event.dict().items():
        setattr(db_reservation_event, key, value)
    db.commit()
    db.refresh(db_reservation_event)
    return db_reservation_event

def delete_reservation_event(db: Session, reservation_event_id: int):
    db_reservation_event = db.query(ReservationEvent).filter(ReservationEvent.reservation_event_id == reservation_event_id).first()
    if not db_reservation_event:
        return None
    db.delete(db_reservation_event)
    db.commit()
    return db_reservation_event

def get_all_traveller_info(db: Session, skip: int = 0):
    traveller_info = db.query(TravellerInfo).offset(skip).all()
    return traveller_info

def get_traveller_info_by_id(db: Session, traveller_id: int):
    traveller_info = db.query(TravellerInfo).filter(TravellerInfo.traveller_id == traveller_id).first()
    return traveller_info

def get_traveller_info_by_reservation_event_id(db: Session, reservation_event_id: int):
    traveller_info = db.query(TravellerInfo).filter(TravellerInfo.reservation_event_id == reservation_event_id).all()
    return traveller_info

def get_traveller_info_by_user_id(db: Session, user_id: int):
    traveller_info = db.query(TravellerInfo).filter(TravellerInfo.user_id == user_id).all()
    return traveller_info

def get_traveller_info_by_event_plan_id(db: Session, event_plan_id: int):
    traveller_info = db.query(TravellerInfo).filter(TravellerInfo.event_plan_id == event_plan_id).all()
    return traveller_info

def create_traveller_info(db: Session, traveller_info_list: list[CreateTravellerInfo]):
    db_travellers = [TravellerInfo(**t.dict()) for t in traveller_info_list]
    db.add_all(db_travellers)
    db.commit()
    for t in db_travellers:
        db.refresh(t)
    return db_travellers

def update_traveller_info(db: Session, traveller_id: int, traveller_info: CreateTravellerInfo):
    db_traveller_info = db.query(TravellerInfo).filter(TravellerInfo.traveller_id == traveller_id).first()
    if not db_traveller_info:
        return None
    for key, value in traveller_info.dict().items():
        setattr(db_traveller_info, key, value)
    db.commit()
    db.refresh(db_traveller_info)
    return db_traveller_info

def delete_traveller_info(db: Session, traveller_id: int):
    db_traveller_info = db.query(TravellerInfo).filter(TravellerInfo.traveller_id == traveller_id).first()
    if not db_traveller_info:
        return None
    db.delete(db_traveller_info)
    db.commit()
    return db_traveller_info

def get_all_event_booking_rooms(db: Session, skip: int = 0):
    event_booking_rooms = db.query(EventBookingRooms).offset(skip).all()
    return event_booking_rooms

def get_event_booking_rooms_by_id(db: Session, booking_room_id: int):
    event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.booking_room_id == booking_room_id).first()
    return event_booking_rooms

def get_event_booking_rooms_by_reservation_event_id(db: Session, reservation_event_id: int):
    event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.reservation_event_id == reservation_event_id).all()
    return event_booking_rooms

def get_event_booking_rooms_by_user_id(db: Session, user_id: int):
    event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.user_id == user_id).all()
    return event_booking_rooms

def get_event_booking_rooms_by_event_plan_id(db: Session, event_plan_id: int):
    event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.event_plan_id == event_plan_id).all()
    return event_booking_rooms

def create_event_booking_rooms(db: Session, event_booking_rooms_list: list[CreateEventBookingRooms]):
    db_rooms = [EventBookingRooms(**room.dict()) for room in event_booking_rooms_list]
    db.add_all(db_rooms)
    db.commit()
    for room in db_rooms:
        db.refresh(room)
    return db_rooms

def update_event_booking_rooms(db: Session, booking_room_id: int, event_booking_rooms: CreateEventBookingRooms):
    db_event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.booking_room_id == booking_room_id).first()
    if not db_event_booking_rooms:
        return None
    for key, value in event_booking_rooms.dict().items():
        setattr(db_event_booking_rooms, key, value)
    db.commit()
    db.refresh(db_event_booking_rooms)
    return db_event_booking_rooms

def delete_event_booking_rooms(db: Session, booking_room_id: int):
    db_event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.booking_room_id == booking_room_id).first()
    if not db_event_booking_rooms:
        return None
    db.delete(db_event_booking_rooms)
    db.commit()
    return db_event_booking_rooms

def get_all_booking_details(db: Session, reservation_event_id: int):
    reservation_event = db.query(ReservationEvent).filter(ReservationEvent.reservation_event_id == reservation_event_id).first()
    if not reservation_event:
        return None
    traveller_info = db.query(TravellerInfo).filter(TravellerInfo.reservation_event_id == reservation_event_id).all()
    event_booking_rooms = db.query(EventBookingRooms).filter(EventBookingRooms.reservation_event_id == reservation_event_id).all()
    
    booking_details = AllBookingDetailsResponse(
        reservation_event_id=reservation_event.reservation_event_id,
        event_id=reservation_event.event_id,
        event_plan_id=reservation_event.event_plan_id,
        total_travelers=reservation_event.total_travelers,
        total_price=reservation_event.total_price,
        payment_status=reservation_event.payment_status,
        advance_paid=reservation_event.advance_paid,
        booking_status=reservation_event.booking_status,
        special_requests=reservation_event.special_requests,
        booking_date=reservation_event.booking_date,
        payment_reference=reservation_event.payment_reference,
        invoice_url=reservation_event.invoice_url,
        created_at=reservation_event.created_at,
        updated_at=reservation_event.updated_at,
        user_id=reservation_event.user_id,
        traveller_info=[TravellerInfoResponse(**traveller.__dict__) for traveller in traveller_info],
        event_booking_rooms=[EventBookingRoomsResponse(**room.__dict__) for room in event_booking_rooms]
    )
    
    return booking_details