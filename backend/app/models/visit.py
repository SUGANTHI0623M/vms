from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base

class Visit(Base):
    __tablename__ = "visits"

    id = Column(Integer, primary_key=True, index=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id"), nullable=False)
    agent_id = Column(Integer, ForeignKey("agents.id"), nullable=True) 
    
    check_in_time = Column(DateTime(timezone=True), server_default=func.now())
    check_out_time = Column(DateTime(timezone=True), nullable=True)
    
    check_in_latitude = Column(Float)
    check_in_longitude = Column(Float)
    check_out_latitude = Column(Float, nullable=True)
    check_out_longitude = Column(Float, nullable=True)
    
    area = Column(String, nullable=True)
    pincode = Column(String, nullable=True)
    city = Column(String, nullable=True)
    state = Column(String, nullable=True)
    
    check_in_selfie_url = Column(String)
    check_out_selfie_url = Column(String, nullable=True)
    
    purpose = Column(String, nullable=True)
    
    vendor = relationship("Vendor", back_populates="visits")
    agent = relationship("Agent", back_populates="visits")
