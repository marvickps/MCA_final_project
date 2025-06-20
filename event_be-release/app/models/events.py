from sqlalchemy import Column, Integer, String, Text, DECIMAL, TIMESTAMP, ForeignKey, Date, Time, BigInteger
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from core.database import Base


class EventInfo(Base):
    __tablename__ = "event_info"

    event_id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    title = Column(String(255), nullable=False)
    tour_category = Column(String(100), nullable=True)
    tour_per_head_price = Column(DECIMAL(10, 2), nullable=True)
    tour_capacity = Column(Integer, nullable=True)
    description = Column(Text, nullable=True)
    booking_per = Column(String(50), nullable=True)
    destination = Column(String(255), nullable=True)
    number_of_nodes = Column(Integer, nullable=True)
    itinerary_info = Column(Text, nullable=True)
    images = Column(Text, nullable=True)
    videos = Column(Text, nullable=True)
    status = Column(String(50), nullable=True)
    client_id = Column(BigInteger, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    instruction_for_trip = Column(Text, nullable=True)
    display_sequence = Column(DECIMAL(10, 2), nullable=True)
    tour_duration = Column(Integer, nullable=True)
    
    # Relationships
    itineraries = relationship("ItineraryInfo", back_populates="event", cascade="all, delete-orphan")
    event_plans = relationship("EventPlan", back_populates="event", cascade="all, delete-orphan")
    stop_settings = relationship("StopSetting", back_populates="event", cascade="all, delete-orphan")
    event_categories = relationship("EventInCategory", back_populates="event", cascade="all, delete-orphan")


class MasterEventCategory(Base):
    __tablename__ = "master_event_categories"
    
    category_id = Column(BigInteger, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True)
    description = Column(Text, nullable=True)

    # Relationships
    events = relationship("EventInCategory", back_populates="category")

class EventInCategory(Base):
    __tablename__ = "event_in_category"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    event_id = Column(BigInteger, ForeignKey("event_info.event_id"), nullable=False)
    category_id = Column(BigInteger, ForeignKey("master_event_categories.category_id"), nullable=False)

    # Relationships
    event = relationship("EventInfo", back_populates="event_categories")
    category = relationship("MasterEventCategory", back_populates="events")


class ItineraryInfo(Base):
    __tablename__ = "itinerary_info"

    itinerary_id = Column(BigInteger, primary_key=True, autoincrement=True)
    event_id = Column(BigInteger, ForeignKey("event_info.event_id"), nullable=False)
    day_count = Column(Integer, nullable=False)
    stop_name = Column(String(255), nullable=False)
    eta = Column(Time, nullable=True)
    description = Column(Text, nullable=True)
    
    # Relationship
    event = relationship("EventInfo", back_populates="itineraries")

class EventPlan(Base):
    __tablename__ = "event_plan"
    
    ep_id = Column(BigInteger, primary_key=True, autoincrement=True)
    event_id = Column(BigInteger, ForeignKey("event_info.event_id"), nullable=False)
    client_id = Column(Text, nullable=True)
    booking_start_date = Column(Date, nullable=True)
    booking_end_date = Column(Date, nullable=True)
    tour_start_date = Column(Date, nullable=True)
    tour_end_date = Column(Date, nullable=True)
    status = Column(String(50), nullable=True)
    created_by = Column(BigInteger, nullable=True, index=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    instruction_for_trip = Column(Text, nullable=True)
    
    # Relationship
    event = relationship("EventInfo", back_populates="event_plans")

class StopSetting(Base):
    __tablename__ = "stop_setting"
    
    stop_setting_id = Column(BigInteger, primary_key=True, autoincrement=True)
    event_id = Column(BigInteger, ForeignKey("event_info.event_id"), nullable=False)
    day_start_time = Column(Time, nullable=True)
    hotel_duration = Column(Integer, nullable=True)
    activity_duration = Column(Integer, nullable=True)
    restaurant_duration = Column(Integer, nullable=True)
    
    # Relationship
    event = relationship("EventInfo", back_populates="stop_settings")

class RoomBedPricing(Base):
    __tablename__ = "room_bed_pricing"

    room_bed_id = Column(BigInteger, primary_key=True, autoincrement=True)
    event_id = Column(BigInteger, ForeignKey("event_info.event_id"), nullable=False)
    no_of_days = Column(Integer, nullable=True)
    room_type = Column(String(100), nullable=True)
    bed_count = Column(Integer, nullable=True)
    price_per_head_per_day = Column(Integer, nullable=True)
    price_per_head_trip = Column(Integer, nullable=True)
    total_rooms = Column(Integer, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp(), onupdate=func.current_timestamp())
    remarks = Column(Text, nullable=True)

    # Relationship (optional, if you want to backref from EventInfo)
    event = relationship("EventInfo", backref="room_bed_pricings")
