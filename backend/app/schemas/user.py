from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    full_name: str
    role: Optional[str] = "visitor"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    full_name: Optional[str] = None
    role: str
    is_active: bool
    
    class Config:
        from_attributes = True
