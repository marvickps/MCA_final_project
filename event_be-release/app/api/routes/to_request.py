from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from core.database import get_db
from services import to_request as to_request_service
from schemas.to_request import TORequestWithUser, TORequestCreate, TORequestSchema

router = APIRouter(prefix="/api/to-requests", tags=["TO Requests"])

@router.put("/{to_request_id}/{status}", response_model=TORequestWithUser)
def update_to_request_status(to_request_id: int, status: str, db: Session = Depends(get_db)):
    req, user = to_request_service.update_request_status(db, to_request_id, status)
    return {
        "to_request_id": req.to_request_id,
        "approval_status": req.approval_status,
        "user": user
    }


@router.get("/", response_model=List[TORequestWithUser])
def get_all_to_requests(db: Session = Depends(get_db)):
    return to_request_service.get_to_request_users(db)


@router.post("/create/{user_id}", response_model=TORequestSchema, status_code=status.HTTP_201_CREATED)
def create_request(user_id: int, db: Session = Depends(get_db)):
    request_data = TORequestCreate(user_id=user_id)
    return to_request_service.create_to_request(db, request_data)