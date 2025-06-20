from sqlalchemy import Column, Integer, String, Text, Double
from core.database import Base  # assuming Base is from declarative_base()
from sqlalchemy.orm import Relationship

class Location(Base):
    __tablename__ = "locations" 

    location_id = Column(Integer, primary_key=True, autoincrement=True)
    place_id = Column(String(255), nullable=True)
    name = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    latitude = Column(Double, nullable=True)
    longitude = Column(Double, nullable=True)
    itinerary = Relationship("Itinerary", back_populates="locations")

