from sqlalchemy import (
    Column, BigInteger, String, Date, Boolean, Float, Integer, Text, TIMESTAMP, func, ForeignKey, Enum, DECIMAL, CheckConstraint
)
from sqlalchemy.orm import relationship, backref
import enum
from core.database import Base

# Simplified lookups
class RateUnit(str, enum.Enum):
    PerKm = "Per KM"
    PerDay = "Per Day"

class VehicleCategory(str, enum.Enum):
    Sedan = "Sedan"
    SUV = "SUV"
    Minibus = "Minibus"
    Bus = "Bus"

class Driver(Base):
    __tablename__ = "drivers"
    
    driver_id = Column(BigInteger, primary_key=True, autoincrement=True)
    client_id = Column(BigInteger, ForeignKey("client_table.client_id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey('users.user_id'), nullable=False)
    name = Column(String(255), nullable=False)
    dl_number = Column(String(100), nullable=False, unique=True)
    dl_valid_until = Column(Date, nullable=False)
    working_hours = Column(String(50), nullable=True)  # e.g., "08:00-20:00"
    description = Column(String(255), nullable=True)
    review_score = Column(Float, nullable=True)
    review_count = Column(Integer, default=0)
    is_active = Column(Boolean, default=True, index=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    vehicles = relationship("DriverVehicle", back_populates="driver", lazy="dynamic")
    reviews = relationship("DriverReview", back_populates="driver", lazy="dynamic")
    itinerary_items = relationship("ItineraryItem", back_populates="driver", lazy="dynamic")
    client = relationship("Client", backref=backref("drivers", lazy="dynamic"))
    user = relationship("User", back_populates="driver", lazy="joined")  # Changed to joined loading

class DriverVehicle(Base):
    __tablename__ = "driver_vehicles"
    
    id = Column(BigInteger, primary_key=True, autoincrement=True)
    driver_id = Column(BigInteger, ForeignKey("drivers.driver_id"), nullable=False)
    vehicle_name = Column(String(255), nullable=False)  # e.g., "Innova"
    category = Column(Enum(VehicleCategory), nullable=False, index=True)
    is_ac = Column(Boolean, default=True)
    rate_unit = Column(Enum(RateUnit), nullable=False)
    rate = Column(DECIMAL(10, 2), nullable=False)
    is_available = Column(Boolean, default=True, index=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    driver = relationship("Driver", back_populates="vehicles", lazy="dynamic")

class DriverReview(Base):
    __tablename__ = "driver_reviews"
    
    review_id = Column(BigInteger, primary_key=True, autoincrement=True)
    driver_id = Column(BigInteger, ForeignKey("drivers.driver_id"), nullable=False, index=True)
    user_id = Column(BigInteger, ForeignKey("users.user_id"), nullable=False, index=True)
    # TODO: Uncomment when bookings table is implemented
    # booking_id = Column(BigInteger, ForeignKey("bookings.booking_id"), nullable=True, index=True)
    
    rating = Column(Integer, nullable=False)
    title = Column(String(200), nullable=True)  # Optional review title
    comment = Column(Text, nullable=True)  # Detailed review comment
    
    driving_rating = Column(Integer, nullable=True)
    is_visible = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    driver = relationship("Driver", back_populates="reviews", lazy="joined")
