from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.core.database import Base
import random
import datetime

class OTP(Base):
    __tablename__ = "otps"

    id = Column(Integer, primary_key=True, index=True)
    identifier = Column(String, index=True) # email or phone number
    code = Column(String)
    purpose = Column(String) # 'register', 'forgot_password'
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True))

    @classmethod
    def generate_code(cls):
        return str(random.randint(1000, 9999))
