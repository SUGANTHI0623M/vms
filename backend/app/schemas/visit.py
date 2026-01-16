from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class VisitCreate(BaseModel):
    agent_id: int
    check_in_latitude: float
    check_in_longitude: float
    purpose: Optional[str] = None

class VisitCheckOut(BaseModel):
    check_out_latitude: float
    check_out_longitude: float

class VisitResponse(BaseModel):
    id: int
    vendor_id: int
    agent_id: int
    check_in_time: datetime
    check_out_time: Optional[datetime] = None
    check_in_latitude: float
    check_in_longitude: float
    check_in_selfie_url: str
    check_out_latitude: Optional[float] = None
    check_out_longitude: Optional[float] = None
    check_out_selfie_url: Optional[str] = None
    purpose: Optional[str] = None
    
    class Config:
        from_attributes = True
