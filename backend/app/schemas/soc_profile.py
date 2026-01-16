from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class SOCProfileBase(BaseModel):
    phone_number: str
    company_name: Optional[str] = None
    role_type: str # Visitor, Technician, Provider
    service_category: Optional[str] = None
    bluetooth_id: Optional[str] = None
    device_id: Optional[str] = None

class SOCProfileCreate(SOCProfileBase):
    full_name: str
    email: EmailStr
    password: str

class SOCProfileUpdate(BaseModel):
    company_name: Optional[str] = None
    role_type: Optional[str] = None
    photo_url: Optional[str] = None
    gov_id_url: Optional[str] = None
    service_category: Optional[str] = None
    bluetooth_id: Optional[str] = None

class SOCProfile(SOCProfileBase):
    id: int
    user_id: int
    soc_id: str
    photo_url: Optional[str] = None
    gov_id_url: Optional[str] = None
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True
