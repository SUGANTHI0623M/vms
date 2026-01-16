from pydantic import BaseModel
from typing import Optional, List
from .document import DocumentResponse

class VendorBase(BaseModel):
    phone_number: Optional[str] = None
    company_name: Optional[str] = None
    office_address: Optional[str] = None
    dob: Optional[str] = None
    gender: Optional[str] = None

class VendorUpdate(VendorBase):
    pass

class VendorResponse(VendorBase):
    id: int
    user_id: int
    verification_status: str
    vendor_uid: Optional[str] = None
    
    class Config:
        from_attributes = True
