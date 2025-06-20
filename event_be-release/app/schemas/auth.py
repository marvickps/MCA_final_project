# app/schema/auth.py
from pydantic import BaseModel, EmailStr

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    role_id: int
    username: str
    email: EmailStr
    phone: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: int

class RefreshTokenRequest(BaseModel):
    refresh_token: str
