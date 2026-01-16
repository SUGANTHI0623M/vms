from sqlalchemy.orm import Session
from app.models.agent import Agent

def get_agents(db: Session, skip: int = 0, limit: int = 100):
    return db.query(Agent).offset(skip).limit(limit).all()

def create_agent(db: Session, name: str, department: str, email: str):
    db_agent = Agent(name=name, department=department, email=email)
    db.add(db_agent)
    db.commit()
    db.refresh(db_agent)
    return db_agent
