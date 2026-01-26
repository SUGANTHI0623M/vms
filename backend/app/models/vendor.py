from sqlalchemy import Column, Integer, String, ForeignKey, Enum, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
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
    
    # QR Code fields (added via migration)
    # Note: If migration hasn't run, these will cause errors
    # Run: python check_and_fix_qr_columns.py or alembic upgrade head
    qr_code_data = Column(Text, nullable=True)  # JSON string with company details
    qr_code_image_url = Column(String, nullable=True)  # URL to QR code image
    qr_code_generated_at = Column(DateTime(timezone=True), nullable=True)
    
    user = relationship("User", backref="vendor_profile")
    documents = relationship("Document", back_populates="vendor")
    visits = relationship("Visit", back_populates="vendor")
