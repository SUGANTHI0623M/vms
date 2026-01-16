from sqlalchemy.orm import Session
from app.models.vendor import Vendor
from app.schemas.vendor import VendorUpdate

def get_vendor_by_user_id(db: Session, user_id: int):
    return db.query(Vendor).filter(Vendor.user_id == user_id).first()

def get_vendor_by_id(db: Session, vendor_id: int):
    return db.query(Vendor).filter(Vendor.id == vendor_id).first()
