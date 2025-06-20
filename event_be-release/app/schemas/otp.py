from pydantic import BaseModel, EmailStr

class OTPRequest(BaseModel):
    email: EmailStr

class OTPVerify(BaseModel):
    email: EmailStr
    code: str

class OTPResponse(BaseModel):
    message: str
    success: bool