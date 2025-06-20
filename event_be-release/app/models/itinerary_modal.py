# app/models/itinerary.py

from sqlalchemy import BigInteger, Column, DateTime, Double, Integer, String, Text, TIMESTAMP,ForeignKey,Date,Time,Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import Relationship
from core.database import Base
from models.user import User  
from models.place_modal import Place
from models.location_modal import Location
from pydantic import BaseModel, Field
from typing import Optional
from datetime import date
import enum


class Itinerary(Base):
    __tablename__ = "itinerary"

    itinerary_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id", ondelete="NO ACTION"), nullable=True)
    title = Column(String(255), nullable=True)
    location_id = Column(Integer, ForeignKey("locations.location_id", ondelete="NO ACTION"), nullable=True)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    starting_point = Column(Integer, ForeignKey("places.p_id", ondelete="NO ACTION"), nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    # Relationship with other tables
    users = Relationship("User", back_populates="itinerary")
    locations = Relationship("Location", back_populates="itinerary")
    places = Relationship("Place", back_populates="itinerary")
    itineraryDays = Relationship("ItineraryDays", back_populates="itinerary")

class ItineraryDays(Base):
    __tablename__ = "itinerary_days"

    itinerary_day_id = Column(Integer, primary_key=True, index=True)
    itinerary_id = Column(Integer, ForeignKey("itinerary.itinerary_id",ondelete="NO ACTION"), nullable=True)
    day_number = Column(Integer,nullable=True)
    date= Column(Date, nullable=True)
    itinerary = Relationship("Itinerary", back_populates="itineraryDays")
    itinerary_items = Relationship("ItineraryItem", back_populates="itinerary_days", cascade="all, delete-orphan")



class ItemType(str, enum.Enum):
    HOTEL = "hotel"
    RESTAURANT = "restaurant"
    PLACE = "place"
    STARTING_POINT = "starting_point"

class ItineraryItem(Base):
    __tablename__ = "itinerary_items" 

    itinerary_item_id = Column(Integer, primary_key=True, index=True)
    itinerary_day_id = Column(Integer, ForeignKey("itinerary_days.itinerary_day_id", ondelete="NO ACTION"))
    time = Column(Time, nullable=True)
    distance_from_previous_stop = Column(Double, nullable=True)
    duration_from_previous_stop = Column(Double, nullable=True)
    order_index = Column(Integer, nullable=True)
    type = Column(Enum(ItemType), nullable=False)
    hotel_id = Column(BigInteger, ForeignKey("hotels.hotel_id"), nullable=True)
    restaurant_id = Column(Integer, ForeignKey("restaurants.restaurant_id"), nullable=True)
    p_id = Column(Integer, ForeignKey("places.place_id"), nullable=True)
    cost = Column(Double, nullable=True)
    stay_duration = Column(Integer, nullable=True)
    description = Column(Text, nullable=True)

    itinerary_days = Relationship("ItineraryDays", back_populates="itinerary_items")
    hotels = Relationship("Hotel", back_populates="itinerary_items")
    restaurants = Relationship("Restaurant", back_populates="itinerary_items")
    places = Relationship("Place", back_populates="itinerary_items")


class ItineraryShareCode(Base):
    __tablename__ = "itinerary_share_code" 

    share_id = Column(Integer, primary_key=True, index=True)
    itinerary_id = Column(Integer, ForeignKey("itinerary.itinerary_id",ondelete="NO ACTION"), nullable=True)
    share_code = Column(String(255), nullable=True)

