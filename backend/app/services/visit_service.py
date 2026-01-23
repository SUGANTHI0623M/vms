from sqlalchemy.orm import Session
from app.models.visit import Visit
from app.schemas.visit import VisitCreate, VisitCheckOut
from datetime import datetime

def create_visit(db: Session, visit_in: VisitCreate, vendor_id: int, selfie_url: str):
    db_visit = Visit(
        vendor_id=vendor_id,
        agent_id=visit_in.agent_id,
        check_in_latitude=visit_in.check_in_latitude,
        check_in_longitude=visit_in.check_in_longitude,
        check_in_selfie_url=selfie_url,
        area=visit_in.area,
        pincode=visit_in.pincode,
        city=visit_in.city,
        state=visit_in.state,
        purpose=visit_in.purpose
    )
    db.add(db_visit)
    db.commit()
    db.refresh(db_visit)
    return db_visit

def update_visit_checkout(db: Session, visit_id: int, visit_out: VisitCheckOut, selfie_url: str):
    db_visit = db.query(Visit).filter(Visit.id == visit_id).first()
    if db_visit:
        db_visit.check_out_latitude = visit_out.check_out_latitude
        db_visit.check_out_longitude = visit_out.check_out_longitude
        db_visit.check_out_selfie_url = selfie_url
        db_visit.check_out_time = datetime.utcnow()
        db.commit()
        db.refresh(db_visit)
    return db_visit

def get_all_visits(db: Session):
    return db.query(Visit).all()

def get_visit_by_id(db: Session, visit_id: int):
    return db.query(Visit).filter(Visit.id == visit_id).first()

def get_visits_by_vendor_id(db: Session, vendor_id: int):
    return db.query(Visit).filter(Visit.vendor_id == vendor_id).all()

def get_visits_for_vendor_view(db: Session, vendor_id: int, company_name: str = None):
    from sqlalchemy import or_
    
    query = Visit.vendor_id == vendor_id
    if company_name:
        # Match "Visiting: CompanyName" case-insensitive
        # We search for "Visiting: {company_name}"
        # Ideally, we should be careful about partial matches, e.g. "Hema" matching "Hema Co".
        # But for now, user context implies simple string matching.
        # We'll use ilike for case insensitivity.
        term = f"Visiting: {company_name}%"
        query = or_(Visit.vendor_id == vendor_id, Visit.purpose.ilike(term))
        
    return db.query(Visit).filter(query).all()
