from pydantic import BaseModel
from datetime import datetime

class DocumentBase(BaseModel):
    document_type: str

class DocumentCreate(DocumentBase):
    pass

class DocumentResponse(DocumentBase):
    id: int
    vendor_id: int
    file_url: str
    uploaded_at: datetime
    
    class Config:
        from_attributes = True
        # Exclude relationships to avoid lazy loading issues
