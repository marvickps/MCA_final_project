from sqlalchemy import Column, Integer, String, Text, DECIMAL, TIMESTAMP, ForeignKey, Date, Time, BigInteger, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from core.database import Base
from models.user import User


class Client(Base):
    __tablename__ = "client_table"
    client_id       = Column(BigInteger, primary_key=True, autoincrement=True)
    client_name     = Column(String(255), nullable=False)
    url             = Column(String(255), nullable=True, unique=True)
    user_id         = Column(BigInteger, ForeignKey("users.user_id"), nullable=False)
    client_logo     = Column(String(255), nullable=True)
    client_banner   = Column(String(255), nullable=True)
    approval_status = Column(
        Enum('open','pending','approved','rejected','left'),
        nullable=True
    )
    created_at      = Column(TIMESTAMP, server_default=func.now(), nullable=False)
    updated_at      = Column(
        TIMESTAMP, server_default=func.now(),
        onupdate=func.now(), nullable=False
    )

    owner           = relationship("User", backref="owned_client")
    client_users    = relationship("ClientUser", back_populates="client")


class ClientUser(Base):
    __tablename__ = "client_user_table"
    client_user_id  = Column(BigInteger, primary_key=True, autoincrement=True)
    client_id       = Column(BigInteger, ForeignKey("client_table.client_id"), nullable=False)
    user_id         = Column(BigInteger, ForeignKey("users.user_id"),      nullable=False)
    client_user_role= Column(Enum('admin','user','customer'), nullable=False)
    approval_status = Column(Enum('open','pending','approved','rejected'), nullable=True)

    client = relationship("Client", back_populates="client_users")
    user   = relationship("User",   back_populates="client_users")
