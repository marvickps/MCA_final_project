from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from core.database import get_db
from models.connection_request import ConnectionRequest
from models.events import EventInfo
from schemas.connection_request import ConnectionRequestCreate, ConnectionRequestSchema, ReceivedConnectionRequest

router = APIRouter(prefix="/api/connection-requests", tags=["Connection Requests"])


@router.post("/", response_model=ConnectionRequestSchema)
def create_connection_request(data: ConnectionRequestCreate, db: Session = Depends(get_db)):
    new_request = ConnectionRequest(**data.dict())
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/received/{user_id}", response_model=List[ReceivedConnectionRequest])
def get_received_requests(user_id: int, db: Session = Depends(get_db)):
    # Get all requests related to events created by the user
    requests = (
        db.query(ConnectionRequest)
        .join(EventInfo, ConnectionRequest.event_id == EventInfo.event_id)
        .filter(EventInfo.created_by == user_id)
        .all()
    )

    # Build simplified response
    result = []
    for req in requests:
        # Fetch the associated event directly from the database
        event = db.query(EventInfo).filter(EventInfo.event_id == req.event_id).first()
        if event:
            result.append({
                "request_id": req.request_id,
                "name": req.name,  # Added this missing field
                "contact_no": req.contact_no,
                "email": req.email,
                "address": req.address,
                "event_id": req.event_id,
                "event_title": event.title,
                "event_description": event.description
            })

    return result