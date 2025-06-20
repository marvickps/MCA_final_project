from sqlalchemy import (
    Column, Integer, String, ForeignKey, Enum, Boolean, Date, Text, Float, DECIMAL, BigInteger, TIMESTAMP, func
)
from sqlalchemy.orm import relationship
import enum

from core.database import Base

class RoomType(str, enum.Enum):
    Single = "Single Seater"
    Double = "Double Seater"
    Triple = "Triple Seater"
    Family = "Family Room"


class HotelRoom(Base):
    __tablename__ = 'hotel_rooms'

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    hotel_id = Column(BigInteger, ForeignKey('hotels.hotel_id'), nullable=False)

    room_type = Column(Enum(RoomType), nullable=False)  # ✅ Fixed Enum room type
    ac_count = Column(Integer, nullable=False)
    non_ac_count = Column(Integer, nullable=False)
    ac_rate_per_night = Column(DECIMAL(10, 2), nullable=False)
    non_ac_rate_per_night = Column(DECIMAL(10, 2), nullable=False)
    is_available = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    hotel = relationship("Hotel", back_populates="rooms", lazy="selectin")
