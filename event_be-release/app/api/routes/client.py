from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlalchemy.orm import Session
from core.database import get_db
from repository import client as client_repo
from repository import user as user_repo
from services import client as client_service
from schemas.client import ClientResponse, ClientUserResponse, ClientResponseWithUser, ClientCreate
from schemas.user import UserSchema

router = APIRouter(prefix="/api/clients", tags=["Clients"])

# 1. Get all clients
@router.get("/", response_model=list[ClientResponse])
def get_all_clients(db: Session = Depends(get_db)):
    return client_repo.get_all_clients(db)

# 2. Get all client users
@router.get("/users", response_model=list[ClientUserResponse])
def get_all_client_users(db: Session = Depends(get_db)):
    return client_repo.get_all_clients_user(db)
 
# 3. Get client by user_id
@router.get("/by_user/{user_id}", response_model=ClientResponse)
def get_client_by_user_id(user_id: int, db: Session = Depends(get_db)):
    return client_repo.get_client_by_user_id(db, user_id)

# 4. Get client_user by user_id
@router.get("/users/by_user/{user_id}", response_model=List[ClientUserResponse])
def get_client_user_by_user_id(user_id: int, db: Session = Depends(get_db)):
    return client_repo.get_client_user_by_user_id(db, user_id)

# 5. Get client by client_id
@router.get("/{client_id}", response_model=ClientResponse)
def get_client_by_id(client_id: int, db: Session = Depends(get_db)):
    return client_repo.get_client_by_id(db, client_id)

# 6. Get client_user by client_id 
@router.get("/users/by_client/{client_id}", response_model=list[ClientUserResponse])
def get_client_users_by_client_id(client_id: int, db: Session = Depends(get_db)):
    users = db.query(client_repo.ClientUser).filter(
        client_repo.ClientUser.client_id == client_id
    ).all()
    if not users:
        raise HTTPException(status_code=404, detail="No users found for client")
    return users

@router.put("/users/{client_user_id}/{approval_status}")
def update_client_user_status(client_user_id: int, approval_status: str, db: Session = Depends(get_db)):
    try:
        return client_service.update_client_user_status(db, client_user_id, approval_status)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{client_id}/{approval_status}")
def update_client_status(client_id: int, approval_status: str, db: Session = Depends(get_db)):
    try:
        return client_service.update_client_and_admin_status(db, client_id, approval_status)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# 9. Get user details based on client_id
@router.get("/{client_id}/user", response_model=ClientResponseWithUser)
def get_users_by_client_id(client_id: int, db: Session = Depends(get_db)):
    client = client_repo.get_client_by_id(db, client_id)
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    client_users = client_repo.get_client_user_by_client_id_and_approval(db, client_id, "approved")
    if not client_users:
        raise HTTPException(status_code=404, detail="No users found for this client")

    user_ids = [cu.user_id for cu in client_users]
    users = [
        UserSchema.model_validate(user, from_attributes=True)
        for uid in user_ids
        if (user := user_repo.fetch_by_user_id(db, uid))
    ]

    return ClientResponseWithUser(
        client_id=client.client_id,
        client_name=client.client_name,
        url=client.url,
        user_id=client.user_id,
        client_logo=client.client_logo,
        client_banner=client.client_banner,
        approval_status=client.approval_status,
        created_at=client.created_at,
        updated_at=client.updated_at,
        user=users
    )

@router.get("/users/by_user_and_approval/{user_id}/{approval_status}", response_model=List[ClientUserResponse])
def get_client_users_by_user_id_and_status(user_id: int, approval_status: str, db: Session = Depends(get_db)):
    return client_repo.get_client_user_by_user_id_and_approval(db, user_id, approval_status)

@router.post("/create", response_model=ClientResponse)
def create_client_with_admin(client_data: ClientCreate, db: Session = Depends(get_db)):
    try:
        result = client_service.create_client_with_admin(db, client_data)
        return result["client"]
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/create/client_user/{username}", response_model=ClientUserResponse)
def create_client_user_by_username(username: str, client_id: int, db: Session = Depends(get_db)):
    try:
        return client_service.create_client_user_by_username(db, username, client_id)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@router.post("/create/client_user_by_email/{email}", response_model=ClientUserResponse)
def create_client_user_by_email(email: str, client_id: int, db: Session = Depends(get_db)):
    try:
        return client_service.create_client_user_by_email(db, email, client_id)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@router.get("/clientURL/{url}", response_model=ClientResponse)
def get_client_user_by_url(url: str, db: Session = Depends(get_db)):
    try:
        return client_repo.get_client_by_url(db, url)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/create/client_customer_joining/{client_url}/{user_id}", response_model=ClientUserResponse)
def create_client_user(client_url: str, user_id: int, db: Session = Depends(get_db)):
    try:
        return client_service.client_customer_joining(db, client_url, user_id)
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/client_customer_joining/{user_id}", response_model=List[ClientUserResponse])
def get_client_user(user_id: int, db: Session = Depends(get_db)):
    try:
        return client_service.get_client_user_customer(db, user_id)
    except HTTPException as he:
        raise he