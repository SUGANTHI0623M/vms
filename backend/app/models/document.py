from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base

class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id"), nullable=False)
    document_type = Column(String) 
    file_url = Column(String, nullable=False)
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())
    
    vendor = relationship("Vendor", back_populates="documents")
