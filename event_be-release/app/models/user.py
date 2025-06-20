from sqlalchemy import (
    Column, BigInteger, DateTime, ForeignKey, String, Integer,
    TIMESTAMP, Time, func
)
from core.database import Base
from sqlalchemy.orm import relationship

class Role(Base):
    __tablename__ = "role"
    id   = Column(Integer, primary_key=True)
    role = Column(String(50), nullable=False, unique=True)   # e.g. 'admin', 'TO', 'user'

    users = relationship("User", back_populates="role")

class User(Base):
    __tablename__ = "users"
    user_id      = Column(BigInteger, primary_key=True, autoincrement=True)
    username     = Column(String(100), nullable=False, unique=True)
    email        = Column(String(100), nullable=False, unique=True)
    phone        = Column(String(20),  nullable=True,  unique=True)
    password_hash= Column(String(255), nullable=False)
    role_id      = Column(Integer, ForeignKey("role.id"), nullable=False)
    created_at   = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at   = Column(
        TIMESTAMP,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )
    is_active    = Column(Integer, default=1)

    # Relationships
    role         = relationship("Role", back_populates="users")
    client_users = relationship("ClientUser", back_populates="user")
    itinerary    = relationship("Itinerary", back_populates="users")
    restaurants  = relationship("Restaurant", back_populates="users")
    default_itinerary_timing = relationship("DefaultItineraryTiming", back_populates="users", uselist=False)


class DefaultItineraryTiming(Base):
    __tablename__ = "default_itinerary_timing"

    setting_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id", ondelete="CASCADE"), unique=True, nullable=False)

    day_start_time = Column(Time, nullable=False, default="09:00:00")
    place_duration = Column(Integer, nullable=False, default=3600)          # 1 hr in seconds
    hotel_daytime_duration = Column(Integer, nullable=False, default=7200)          # 2 hrs in seconds
    hotel_night_duration = Column(Integer, nullable=False, default=28800)           # 8 hrs
    activity_duration = Column(Integer, nullable=False, default=3600)               # 1 hr
    restaurant_duration = Column(Integer, nullable=False, default=3600)             # 1 hr

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    users = relationship("User", back_populates="default_itinerary_timing")
