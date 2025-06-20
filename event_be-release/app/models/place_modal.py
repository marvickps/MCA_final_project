from sqlalchemy import Column, Integer, String, Text, Float, Double
from core.database import Base  # assuming you have a Base from declarative_base()
from sqlalchemy.orm import Relationship

class Place(Base):
    __tablename__ = "places"

    p_id = Column(Integer, primary_key=True, autoincrement=True)
    place_id = Column(String(255), nullable=False)
    name = Column(String(255), nullable=True) 
    address = Column(Text, nullable=True)
    latitude = Column(Double, nullable=True)
    longitude = Column(Double, nullable=True)
    rating = Column(Float, nullable=True)
    photo_url = Column(Text, nullable=True)
    itinerary = Relationship("Itinerary", back_populates="places",foreign_keys="[Itinerary.starting_point]")
    itinerary_items = Relationship("ItineraryItem", back_populates="places")
    cost = Column(Float)



