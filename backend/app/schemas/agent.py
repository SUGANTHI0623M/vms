from pydantic import BaseModel
from typing import Optional

class AgentBase(BaseModel):
    name: str
    department: Optional[str] = None
    email: Optional[str] = None

class AgentCreate(AgentBase):
    pass

class AgentResponse(AgentBase):
    id: int
    is_active: bool
    
    class Config:
        from_attributes = True
