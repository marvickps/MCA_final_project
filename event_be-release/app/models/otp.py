from sqlalchemy import Column, BigInteger, String, Integer, TIMESTAMP, func, ForeignKey
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class OTP(Base):
    __tablename__ = "otps"

    otp_id = Column(BigInteger, primary_key=True, autoincrement=True)
    email = Column(String(100), nullable=False)
    code = Column(String(6), nullable=False) 
    purpose = Column(String(50), nullable=False)
    expires_at = Column(TIMESTAMP, nullable=False)
    is_used = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())