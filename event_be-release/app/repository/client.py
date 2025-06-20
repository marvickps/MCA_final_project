# repository/client.py

from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from models.client import Client, ClientUser
from schemas.client import ClientCreate

def get_all_clients(db: Session, skip: int = 0):
    clients = db.query(Client).offset(skip).all()
    if not clients:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No clients found")
    return clients

def get_all_clients_user(db: Session):
    clients = db.query(ClientUser).all()
    if not clients:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No clients found")
    return clients

def get_client_by_id(db: Session, client_id: int):
    client = db.query(Client).filter(Client.client_id == client_id).first()
    if not client:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client not found")
    return client

def get_client_user_by_id(db: Session, client_user_id: int):
    client_user = db.query(ClientUser).filter(ClientUser.client_user_id == client_user_id).first()
    if not client_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client user not found")
    return client_user

def get_client_by_user_id(db: Session, user_id: int):
    client = db.query(Client).filter(Client.user_id == user_id).first()
    if not client:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client not found")
    return client

def get_client_user_by_user_id(db: Session, user_id: int):
    client_user = db.query(ClientUser).filter(ClientUser.user_id == user_id).all()
    if not client_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client user not found")
    return client_user

def get_client_user_by_user_id_and_approval(db: Session, user_id: int, approval_status: str):
    client_user = db.query(ClientUser).filter(
        ClientUser.user_id == user_id,
        ClientUser.approval_status == approval_status,
        ClientUser.client_user_role.in_(["user", "admin"])
    ).all()
    if not client_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client user not found")
    return client_user

def get_client_user_by_client_id_and_approval(db: Session, client_id: int, approval_status: str):
    client_user = db.query(ClientUser).filter(ClientUser.client_id == client_id, ClientUser.approval_status == approval_status).all()
    if not client_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client user not found")
    return client_user

def get_client_user_by_client_id(db: Session, client_id: int):
    client_user = db.query(ClientUser).filter(ClientUser.client_id == client_id).all()
    if not client_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client user not found")
    return client_user

def create_client(db: Session, request_data: ClientCreate):
    try:
        new_request = Client(
            url=request_data.url,
            user_id=request_data.user_id,
            client_logo=request_data.client_logo,
            client_banner=request_data.client_banner,
            approval_status=request_data.approval_status,
            client_name=request_data.client_name
        )
        db.add(new_request)
        db.commit()
        db.refresh(new_request)
        return new_request
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))


def create_client_user(db: Session, client_id: int, user_id: int, role: str, approval_status: str):
    try:
        new_client_user = ClientUser(
            client_id=client_id,
            user_id=user_id,
            client_user_role=role,
            approval_status=approval_status
        )
        db.add(new_client_user)
        db.commit()
        db.refresh(new_client_user)
        return new_client_user
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

def update_client_status(db: Session, client: Client, status: str):
    client.approval_status = status
    db.commit()
    db.refresh(client)


def update_client_user_status(db: Session, client_user: ClientUser, status: str):
    client_user.approval_status = status
    db.commit()
    db.refresh(client_user)
    
def has_approved_client_user(db: Session, user_id: int) -> bool:
    return db.query(ClientUser).filter(
        ClientUser.user_id == user_id,
        ClientUser.approval_status == 'approved'
    ).first() is not None

def reject_other_client_users(db: Session, user_id: int, exclude_id: int = None):
    query = db.query(ClientUser).filter(
        ClientUser.user_id == user_id,
        ClientUser.approval_status.in_(['open', 'pending'])
    )
    if exclude_id:
        query = query.filter(ClientUser.client_user_id != exclude_id)
    query.update({"approval_status": "rejected"})
    db.commit()

def delete_client(db: Session, client_id: int):
    client = db.query(Client).filter(Client.client_id == client_id).first()
    if not client:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client not found")
    db.delete(client)
    db.commit()
    return {"message": "Client deleted successfully"}

def delete_client_user(db: Session, client_user_id: int):
    client_user = db.query(ClientUser).filter(ClientUser.client_user_id == client_user_id).first()
    if not client_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client user not found")
    db.delete(client_user)
    db.commit()
    return {"message": "Client user deleted successfully"}

def get_client_by_url(db: Session, url: str):
    client = db.query(Client).filter(Client.url == url).first()
    if not client:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Client not found")
    return client

def get_client_user_by_client_id_and_user_id(db: Session, client_id: int, user_id: int):
    client_user = db.query(ClientUser).filter(ClientUser.client_id == client_id, ClientUser.user_id == user_id).first()
    return client_user