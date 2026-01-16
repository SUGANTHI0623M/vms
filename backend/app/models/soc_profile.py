from sqlalchemy import Column, Integer, String, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class SOCProfile(Base):
    __tablename__ = "soc_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    soc_id = Column(String, unique=True, index=True)
    phone_number = Column(String)
    company_name = Column(String, nullable=True)
    role_type = Column(String)
    service_category = Column(String, nullable=True)
    bluetooth_id = Column(String, nullable=True)
    device_id = Column(String, nullable=True)
    
    photo_url = Column(String, nullable=True)
    gov_id_url = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", backref="soc_profile")
