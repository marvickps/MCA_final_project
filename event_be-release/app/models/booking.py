from sqlalchemy import Column, Integer, String, Text, DECIMAL, TIMESTAMP, ForeignKey, Date, Time, BigInteger, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import Relationship
from core.database import Base
from models.user import User
from models.events import EventInfo, EventPlan, RoomBedPricing

class TravellerInfo(Base):
    __tablename__ = "traveller_info"

    traveller_id = Column(Integer, primary_key=True, autoincrement=True)
    reservation_event_id = Column(Integer, nullable=False)
    full_name = Column(String(255), nullable=False)
    id_proof = Column(String(255), nullable=True)
    medical_needs = Column(Text, nullable=True)
    meal_preference = Column(String(100), nullable=True)
    emergency_contact = Column(String(20), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now(), nullable=True)
    user_id = Column(BigInteger, nullable=True)
    event_plan_id = Column(BigInteger, nullable=True)

class EventBookingRooms(Base):
    __tablename__ = "event_booking_rooms"

    booking_room_id = Column(Integer, primary_key=True, autoincrement=True)
    reservation_event_id = Column(Integer, nullable=False)
    room_bed_id = Column(Integer, nullable=False)
    number_of_travelers = Column(Integer, nullable=False)
    price_per_head_trip = Column(DECIMAL(10, 2), nullable=False)
    total_price = Column(Integer, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now(), nullable=True)
    event_plan_id = Column(BigInteger, nullable=True)
    selected_beds_quantity = Column(Integer, nullable=True)
    user_id = Column(BigInteger, nullable=True)

    # events=Relationship("EventInfo", back_populates="event_booking_rooms")
    # event_plan=Relationship("EventPlan", back_populates="event_booking_rooms")
    # room_bed_pricing=Relationship("RoomBedPricing", back_populates="event_booking_rooms")
    # user=Relationship("User", back_populates="event_booking_rooms")

class ReservationEvent(Base):
    __tablename__ = "reservation_event"

    reservation_event_id = Column(Integer, primary_key=True, autoincrement=True)
    event_id = Column(BigInteger, nullable=False)
    total_travelers = Column(Integer, nullable=True)
    total_price = Column(Integer, nullable=True)
    payment_status = Column(String(50), nullable=True)
    advance_paid = Column(Integer, nullable=True)
    booking_status = Column(String(50), nullable=True)
    special_requests = Column(Text, nullable=True)
    booking_date = Column(TIMESTAMP, server_default=func.now(), nullable=True)
    payment_reference = Column(String(100), nullable=True)
    invoice_url = Column(String(255), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now(), nullable=True)
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now(), nullable=True)
    user_id = Column(BigInteger, nullable=True)
    event_plan_id = Column(BigInteger, nullable=True)
    payment_id = Column(String, nullable=True)

    # event_booking_rooms = Relationship("EventInfo", back_populates="event_booking_rooms")
    # user = Relationship("User", back_populates="reservation_event")
