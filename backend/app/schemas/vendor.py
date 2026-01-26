from pydantic import BaseModel, field_serializer
from typing import Optional, List
from datetime import datetime
from .document import DocumentResponse

class VendorBase(BaseModel):
    phone_number: Optional[str] = None
    company_name: Optional[str] = None
    office_address: Optional[str] = None
    dob: Optional[str] = None
    gender: Optional[str] = None
    website: Optional[str] = None
    gstin: Optional[str] = None
    description: Optional[str] = None
    logo_url: Optional[str] = None

class VendorUpdate(VendorBase):
    pass

class VendorResponse(VendorBase):
    id: int
    user_id: int
    verification_status: str
    vendor_uid: Optional[str] = None
    email: Optional[str] = None
    full_name: Optional[str] = None
    qr_code_data: Optional[str] = None
    qr_code_image_url: Optional[str] = None
    qr_code_generated_at: Optional[datetime] = None
    
    @field_serializer('qr_code_generated_at')
    def serialize_datetime(self, value: Optional[datetime], _info) -> Optional[str]:
        if value is None:
            return None
        return value.isoformat()
    
    class Config:
        from_attributes = True

