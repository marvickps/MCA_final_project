from sqlalchemy import Column, Integer, String, BigInteger, Text, ForeignKey, Enum
from sqlalchemy.ext.declarative import declarative_base
from models.user import User
from core.database import Base

class TORequest(Base):
    __tablename__ = "to_request"

    to_request_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey(User.user_id),nullable=False)
    approval_status = Column(Enum('open', 'pending', 'approved', 'rejected'), nullable=True)