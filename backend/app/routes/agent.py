from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.core import database
from app.services import agent_service
from app.schemas.agent import AgentResponse, AgentCreate
from app.dependencies import auth

router = APIRouter()

@router.get("/", response_model=List[AgentResponse])
def read_agents(
    skip: int = 0, 
    limit: int = 100, 
    user = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    return agent_service.get_agents(db, skip=skip, limit=limit)

@router.post("/", response_model=AgentResponse)
def create_agent(agent_in: AgentCreate, user = Depends(auth.get_current_active_user), db: Session = Depends(database.get_db)):
    # In real world, maybe only admin can create agents
    return agent_service.create_agent(db, agent_in.name, agent_in.department, agent_in.email)
