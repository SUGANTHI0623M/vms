from pydantic import BaseModel
from typing import Optional, List
from .document import DocumentResponse  # assuming we will create this

class VendorBase(BaseModel):
    phone_number: str
    company_name: str
    office_address: str

class VendorUpdate(BaseModel):
    phone_number: Optional[str] = None
    company_name: Optional[str] = None
    office_address: Optional[str] = None

class VendorResponse(VendorBase):
    id: int
    user_id: int
    verification_status: str
    documents: List[DocumentResponse] = []
    
    class Config:
        from_attributes = True
