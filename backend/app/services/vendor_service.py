from sqlalchemy.orm import Session
from app.models.vendor import Vendor, VerificationStatus
from typing import Dict, Any

def get_vendor_by_user_id(db: Session, user_id: int):
    return db.query(Vendor).filter(Vendor.user_id == user_id).first()

def get_vendor_by_id(db: Session, vendor_id: int):
    return db.query(Vendor).filter(Vendor.id == vendor_id).first()

def update_vendor(db: Session, vendor_id: int, update_data: Dict[str, Any]):
    vendor = get_vendor_by_id(db, vendor_id)
    if vendor:
        for key, value in update_data.items():
            if hasattr(vendor, key):
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
    return False
