# app/models/hotel.py
from sqlalchemy import BigInteger, Column, Integer, String, Float, Text, ForeignKey
from sqlalchemy.orm import Relationship
from core.database import Base 

class Restaurant(Base):
    __tablename__ = "restaurants"

    restaurant_id = Column(Integer, primary_key=True, autoincrement=True)
    place_id = Column(String(100), nullable=False)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False) 
    name = Column(String(255))
    address = Column(Text)
    latitude = Column(Float)
    longitude = Column(Float)
    rating = Column(Float)
    photo_url = Column(String(1000))
    users = Relationship("User", back_populates="restaurants") 
    itinerary_items = Relationship("ItineraryItem", back_populates="restaurants")
    cost = Column(Float)

