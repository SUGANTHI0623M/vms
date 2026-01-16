from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base

class Agent(Base):
    __tablename__ = "agents"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    department = Column(String)
    email = Column(String)
    is_active = Column(Boolean, default=True)
    
    visits = relationship("Visit", back_populates="agent")
