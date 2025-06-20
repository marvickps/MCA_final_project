from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError
from schemas.client import ClientCreate
from repository import client as client_repo
from repository import user as user_repo
from models.client import ClientUser


def create_client_with_admin(db: Session, client_data: ClientCreate):
    existing_url = client_repo.get_client_by_url(db, client_data.client_url)
    if existing_url:
        raise HTTPException(
            status_code=400,
            detail="Client with the given URL already exists"
        )
    try:
        # Start transaction
        new_client = client_repo.create_client(db, client_data)
        client_user = client_repo.create_client_user(
            db=db,
            client_id=new_client.client_id,
            user_id=client_data.user_id,
            role="admin",
            approval_status="open"
        )
        return {"client": new_client, "client_user": client_user}
    except SQLAlchemyError as e:
        db.rollback()
        raise e
    
def create_client_user_by_username(db: Session, username: str, client_id: int):
    user = user_repo.fetch_by_username(db, username)
    if not user:
        raise HTTPException(status_code=404, detail="User with the given username not found")
    
    client_user = client_repo.create_client_user(
        db=db,
        client_id=client_id,
        user_id=user.user_id,
        role="user",
        approval_status="pending"
    )
    return client_user


def create_client_user_by_email(db: Session, email: str, client_id: int):
    user = user_repo.fetch_by_email(db, email)
    if not user:
        raise HTTPException(status_code=404, detail="User with the given email not found")
    
    client_user = client_repo.create_client_user(
        db=db,
        client_id=client_id,
        user_id=user.user_id,
        role="user",
        approval_status="pending"
    )
    return client_user

def update_client_and_admin_status(db: Session, client_id: int, new_status: str):
    client = client_repo.get_client_by_id(db, client_id)
    client_repo.update_client_status(db, client, new_status)

    if new_status == "approved":
        admin_user_id = client.user_id

        if client_repo.has_approved_client_user(db, admin_user_id):
            raise HTTPException(
                status_code=400,
                detail="User already has an approved client_user"
            )

        client_user = db.query(ClientUser).filter_by(
            client_id=client_id,
            user_id=admin_user_id,
            client_user_role="admin"
        ).first()

        if client_user:
            client_repo.update_client_user_status(db, client_user, "approved")
            client_repo.reject_other_client_users(db, admin_user_id, exclude_id=client_user.client_user_id)

    return {"message": "Client and associated admin user updated successfully"}


def update_client_user_status(db: Session, client_user_id: int, new_status: str):
    client_user = client_repo.get_client_user_by_id(db, client_user_id)

    if new_status == "approved":
        # Check if user already has an approved client_user
        if client_repo.has_approved_client_user(db, client_user.user_id):
            raise HTTPException(
                status_code=400,
                detail="User already has an approved client_user"
            )

        # Update current and reject others
        client_repo.update_client_user_status(db, client_user, "approved")
        client_repo.reject_other_client_users(db, client_user.user_id, exclude_id=client_user.client_user_id)
    else:
        client_repo.update_client_user_status(db, client_user, new_status)

    return {"message": "Client user status updated successfully"}


def client_customer_joining(db: Session, client_url, user_id):
    current_client = client_repo.get_client_by_url(db, client_url)
    client_user_exists = client_repo.get_client_user_by_client_id_and_user_id(db, current_client.client_id, user_id)
    if client_user_exists:
        raise HTTPException(status_code=400, detail="User already exists in the client")
    try:
        role = "customer"
        status = "approved"
        return client_repo.create_client_user(db, current_client.client_id, user_id, role, status)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
def get_client_user_customer(db: Session, user_id: int):
    client_users = client_repo.get_client_user_by_user_id(db, user_id)
    if not client_users:
        raise HTTPException(status_code=404, detail="Client user not found")

    customers = []
    for client_user in client_users:
        client_url = client_repo.get_client_by_id(db, client_user.client_id).url
        client_name = client_repo.get_client_by_id(db, client_user.client_id).client_name
        client_user.client_url = client_url
        client_user.client_name = client_name
        customers.append(client_user)

    if not customers:
        raise HTTPException(status_code=403, detail="No customer roles found")
    return customers
