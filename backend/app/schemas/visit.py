from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class VisitBase(BaseModel):
    agent_id: Optional[int] = None
    purpose: Optional[str] = None
    check_in_latitude: float
    check_in_longitude: float
    area: Optional[str] = None
    pincode: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    check_in_location: Optional[str] = None # Added full address

class VisitCreate(VisitBase):
    pass

class VisitCheckOut(BaseModel):
    check_out_latitude: float
    check_out_longitude: float
    check_out_location: Optional[str] = None # Added full address

class VisitResponse(VisitBase):
    id: int
    vendor_id: int
    check_in_time: datetime
    check_out_time: Optional[datetime] = None
    check_in_selfie_url: str
    check_out_selfie_url: Optional[str] = None
    check_in_location: Optional[str] = None
    check_out_location: Optional[str] = None
    
    class Config:
        from_attributes = True
