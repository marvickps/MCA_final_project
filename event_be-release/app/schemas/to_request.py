from pydantic import BaseModel
from typing import Optional
from schemas.user import UserSchema

class TORequestCreate(BaseModel):
    user_id: int

class TORequestSchema(BaseModel):
    to_request_id: int
    user_id: int
    approval_status: Optional[str]

    class Config:
        from_attributes = True

class TORequestWithUser(BaseModel):
    to_request_id: int
    approval_status: Optional[str]
    user: UserSchema