from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class OrganizationBase(BaseModel):
    name: str
    address: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = None

class OrganizationCreate(OrganizationBase):
    pass

class Organization(OrganizationBase):
    id: int
    subscription_plan: str
    subscription_expires_at: Optional[datetime] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
