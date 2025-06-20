from sqlalchemy.orm import Session
from services.user import add_default_timing
from repository import to_request as to_request_repo
from repository import user as user_repo
from fastapi import HTTPException, status
from schemas.user import UserSchema
from schemas.to_request import TORequestCreate
from models.to_request import TORequest

def update_request_status(db: Session, to_request_id: int, status: str):
    if status not in ["approved", "rejected"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status")

    request = to_request_repo.update_approval_status(db, to_request_id, status)
    if not request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="TO Request not found")

    user = None
    if status == "approved":
        user = user_repo.update_user_role(db, request.user_id, new_role_id=3)
        # add_default_timing(request.user_id,payload=None,db=db)

        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    else:
        user = user_repo.fetch_by_user_id(db, request.user_id)

    return request, user

def get_to_request_users(db: Session):
    requests = to_request_repo.get_all_to_requests(db)
    enriched_requests = []

    for req in requests:
        user = user_repo.fetch_by_user_id(db, req.user_id)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User with ID {req.user_id} not found")
        enriched_requests.append({
            "to_request_id": req.to_request_id,
            "approval_status": req.approval_status,
            "user": UserSchema.from_orm(user)
        })

    return enriched_requests

def fetch_user_by_request(db: Session, to_request):
    user = user_repo.fetch_by_user_id(db, to_request.user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return UserSchema.from_orm(user)


def create_to_request(db: Session, request_data: TORequestCreate):
    # Check if user exists
    user = user_repo.fetch_by_user_id(db, request_data.user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    # Check if user already has a TO request in open/pending state
    existing = db.query(TORequest).filter(
        TORequest.user_id == request_data.user_id,
        TORequest.approval_status.in_(["open", "pending"])
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="TO request already exists in open or pending state"
        )

    new_request = TORequest(user_id=request_data.user_id, approval_status="open")
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request
