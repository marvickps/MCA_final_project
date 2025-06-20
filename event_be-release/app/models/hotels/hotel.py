from sqlalchemy import (
    Column, Integer, String, ForeignKey, Enum, Boolean, Date, Text, Float, DECIMAL, BigInteger, TIMESTAMP, func
)
from sqlalchemy.orm import relationship
import enum

from core.database import Base

class HotelCategory(str, enum.Enum):
    three = "3"
    four = "4"
    five = "5"

class FoodType(str, enum.Enum):
    Veg = "Veg"
    NonVeg = "Non-Veg"
    Both = "Both"


class Hotel(Base):
    __tablename__ = "hotels"

    hotel_id = Column(BigInteger, primary_key=True, autoincrement=True)
    client_id = Column(BigInteger, ForeignKey("client_table.client_id"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    place_id = Column(String(255), nullable=False)
    name = Column(String(255), nullable=False)
    address = Column(Text)
    food_type = Column(Enum(FoodType), nullable=False)
    category = Column(Enum(HotelCategory), nullable=False)
    special_view_info = Column(String(255), nullable=True)
    
    latitude = Column(Float)
    longitude = Column(Float)
    photo_url = Column(String(1000))
    google_rating = Column(Float, nullable=True)
    
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)

    # Relationships
    user = relationship("User", backref="hotels")
    client = relationship("Client", backref="hotels")
    rooms = relationship("HotelRoom", back_populates="hotel", lazy='selectin')
    itinerary_items = relationship("ItineraryItem", back_populates="hotels")

