from sqlalchemy import Column, Integer, String, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum

class VerificationStatus(str, enum.Enum):
    PENDING = "PENDING"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"

class Vendor(Base):
    __tablename__ = "vendors"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    phone_number = Column(String, unique=True, index=True)
    company_name = Column(String, index=True)
    office_address = Column(Text)
    verification_status = Column(Enum(VerificationStatus), default=VerificationStatus.PENDING, index=True)
    vendor_uid = Column(String, unique=True, index=True, nullable=True)
    
    # Personal details
    dob = Column(String, nullable=True)
    gender = Column(String, nullable=True)
    
    # Company details
    website = Column(String, nullable=True)
    gstin = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    logo_url = Column(String, nullable=True)
    
    user = relationship("User", backref="vendor_profile")
    documents = relationship("Document", back_populates="vendor")
    visits = relationship("Visit", back_populates="vendor")
