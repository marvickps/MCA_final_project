from sqlalchemy import Column, Integer, String, BigInteger, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from models.events import EventInfo
from core.database import Base

class ConnectionRequest(Base):
    __tablename__ = "connection_request"

    request_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=True)
    contact_no = Column(String(20), nullable=True)
    email = Column(String(100), nullable=True)
    address = Column(Text, nullable=True)
    event_id = Column(BigInteger, ForeignKey(EventInfo.event_id),nullable=False)