from pydantic import BaseModel
from typing import Optional
from schemas.events import EventSchema  # Reuse your existing EventSchema

class ConnectionRequestCreate(BaseModel):
    name: Optional[str]
    contact_no: Optional[str]
    email: Optional[str]
    address: Optional[str]
    event_id: int

class ConnectionRequestSchema(BaseModel):
    request_id: int
    name: Optional[str]
    contact_no: Optional[str]
    email: Optional[str]
    address: Optional[str]
    event_id: int

    class Config:
        from_attributes = True

class ReceivedConnectionRequest(BaseModel):
    request_id: int
    name: str
    contact_no: str
    email: str
    address: str
    event_id: int
    event_title: str
    event_description: str

