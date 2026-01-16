from sqlalchemy.orm import Session, joinedload
from app.models.vendor import Vendor, VerificationStatus
from typing import Dict, Any

def get_vendor_by_user_id(db: Session, user_id: int):
    return db.query(Vendor).options(joinedload(Vendor.user)).filter(Vendor.user_id == user_id).first()

def get_vendor_by_id(db: Session, vendor_id: int):
    return db.query(Vendor).options(joinedload(Vendor.user)).filter(Vendor.id == vendor_id).first()

def update_vendor(db: Session, vendor_id: int, update_data: Dict[str, Any]):
    vendor = get_vendor_by_id(db, vendor_id)
    if vendor:
        for key, value in update_data.items():
            if key == "email" and vendor.user:
                vendor.user.email = value
            elif hasattr(vendor, key):
                setattr(vendor, key, value)
        db.commit()
        db.refresh(vendor)
    return vendor

def verify_profile(db: Session, vendor_id: int):
    vendor = get_vendor_by_id(db, vendor_id)
    if vendor:
        vendor.verification_status = VerificationStatus.VERIFIED
        # Generate proper UID if needed, simple logic for now
        if not vendor.vendor_uid:
            import uuid
            vendor.vendor_uid = str(uuid.uuid4())[:8].upper()
        db.commit()
        db.refresh(vendor)
        return True

def get_all_vendors(db: Session):
    return db.query(Vendor).options(joinedload(Vendor.user)).all()

def get_verified_companies(db: Session):
    companies = db.query(Vendor.company_name)\
        .filter(Vendor.verification_status == VerificationStatus.VERIFIED)\
        .distinct().all()
    # Flatten list of tuples and filter empty
    return [c[0] for c in companies if c[0]]
