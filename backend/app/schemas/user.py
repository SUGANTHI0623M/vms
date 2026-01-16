from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    full_name: str
    phone_number: Optional[str] = None
    role: Optional[str] = "vendor"

class OTPRequest(BaseModel):
    identifier: str # email or phone
    purpose: str # 'register', 'forgot_password'

class OTPVerify(BaseModel):
    identifier: str
    code: str
    purpose: str

class PasswordReset(BaseModel):
    identifier: str
    code: str
    new_password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    role: str
    is_active: bool
    
    class Config:
        from_attributes = True
