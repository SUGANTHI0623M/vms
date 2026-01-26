from sqlalchemy.orm import Session
from app.models.visit import Visit
from app.models.company_location import CompanyLocation
from app.schemas.visit import VisitCreate, VisitCheckOut
from datetime import datetime, timezone
import math

def calculate_distance(lat1, lon1, lat2, lon2):
    # Haversine formula
    R = 6371000  # radius of Earth in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c

def detect_company(db: Session, lat: float, lon: float, threshold_meters: float = 300.0):
    locations = db.query(CompanyLocation).all()
    nearest_company = None
    min_dist = float('inf')
    
    for loc in locations:
        dist = calculate_distance(lat, lon, loc.latitude, loc.longitude)
        if dist <= threshold_meters and dist < min_dist:
            min_dist = dist
            nearest_company = loc
            
    return nearest_company

def create_visit(db: Session, visit_in: VisitCreate, vendor_id: int, selfie_url: str, user_provided_company: str = None):
    # 1. Detect Company
    detected = detect_company(db, visit_in.check_in_latitude, visit_in.check_in_longitude)
    
    final_company_name = None
    
    if detected:
        final_company_name = detected.company_name
    elif user_provided_company:
        # 2. If not detected but user provided name, Check if we should store this new location
        # Check if same address exists (to avoid duplicates as requested)
        # Note: Address string matching is tricky. We'll check if any location is very close (e.g. < 50m) 
        # OR if exact address string matches.
        # Requirement: "If the same address already exists... Do not store a duplicate entry."
        
        exists = False
        if visit_in.check_in_location:
             exists = db.query(CompanyLocation).filter(CompanyLocation.address == visit_in.check_in_location).first() is not None
        
        if not exists:
            # Also check very close proximity to avoid duplicates with slightly different coords?
            # For now, strict address check as per requirement or just creating it.
            new_loc = CompanyLocation(
                company_name=user_provided_company,
                latitude=visit_in.check_in_latitude,
                longitude=visit_in.check_in_longitude,
                address=visit_in.check_in_location
            )
            db.add(new_loc)
            db.commit() # Commit to generate ID and save
            final_company_name = user_provided_company
        else:
            final_company_name = user_provided_company
            
    # Construct Purpose
    # If we have a final company name, ensure it's in the purpose
    # Format: "Visiting: {Name}. {OriginalPurpose}"
    
    current_purpose = visit_in.purpose
    # Remove existing "Visiting: " prefix if present in purpose to avoid double
    clean_purpose = current_purpose
    
    # If the route already formatted it as "Visiting: UserInput. Purpose", we might need to adjust
    # if we detected a DIFFERENT company.
    # But usually, if detected, we should prefer detected? Or User input?
    # Let's assume User Input overrides if provided (as they might be visiting a new building of same company),
    # but if User Input is empty, we use Detected.
    
    if user_provided_company:
        final_company_name = user_provided_company
    elif detected:
        final_company_name = detected.company_name
    
    # Now reconstruct purpose
    # We expect visit_in.purpose to might handle "Visiting: ..." part from route or raw.
    # Actually route passes `final_purpose` which formats it.
    # Let's trust route's formatting if user provided company.
    # If user did NOT provide company, route passed raw purpose.
    # So if `user_provided_company` is None, `visit_in.purpose` is just "Meeting" etc.
    # In that case, prepend Detected.
    
    if not user_provided_company and final_company_name:
        if clean_purpose:
             visit_in.purpose = f"Visiting: {final_company_name}. {clean_purpose}"
        else:
             visit_in.purpose = f"Visiting: {final_company_name}"
    
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
        check_in_location=visit_in.check_in_location,
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
        db_visit.check_out_location = visit_out.check_out_location
        db_visit.check_out_selfie_url = selfie_url
        db_visit.check_out_time = datetime.now(timezone.utc)
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
        term = f"Visiting: {company_name}%"
        query = or_(Visit.vendor_id == vendor_id, Visit.purpose.ilike(term))
        
    return db.query(Visit).filter(query).all()
