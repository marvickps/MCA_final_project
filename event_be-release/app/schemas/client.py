from pydantic import BaseModel, Field
from typing import Optional, List
from schemas.user import UserSchema
from datetime import datetime

class ClientCreate(BaseModel):
    client_name: str
    url: Optional[str] = None
    user_id: int
    approval_status: Optional[str]
    client_logo: Optional[str] = None
    client_banner: Optional[str] = None

class ClientResponse(BaseModel):
    client_id: int
    client_name: str
    url: Optional[str] = None
    user_id: int
    client_logo: Optional[str] = None
    client_banner: Optional[str] = None
    approval_status: Optional[str]
    created_at: Optional[datetime] 
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

class ClientResponseWithUser(ClientResponse):
    user: List[UserSchema]

class ClientUserCreate(BaseModel):
    client_id: int
    user_id: int
    client_user_role: str
    approval_status: Optional[str]


class ClientUserResponse(BaseModel):
    client_user_id: int
    client_id: int
    user_id: int
    client_user_role: str
    client_url: Optional[str] = None
    client_name: Optional[str] = None

    class Config:
        from_attributes = True

