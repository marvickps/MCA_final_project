from sqlalchemy.orm import Session
from models.to_request import TORequest
from schemas.to_request import TORequestCreate

def create_to_request(db: Session, request_data: TORequestCreate):
    new_request = TORequest(user_id=request_data.user_id, approval_status="open")
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

def update_approval_status(db: Session, to_request_id: int, status: str):
    to_request = db.query(TORequest).filter(TORequest.to_request_id == to_request_id).first()
    if to_request:
        to_request.approval_status = status
        db.commit()
        db.refresh(to_request)
    return to_request

def get_all_to_requests(db: Session):
    return db.query(TORequest).all()

