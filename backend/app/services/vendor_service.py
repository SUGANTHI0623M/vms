from sqlalchemy.orm import Session, joinedload
from app.models.vendor import Vendor, VerificationStatus
from typing import Dict, Any
from app.services.qr_code_service import generate_and_save_qr_code, should_regenerate_qr_code

def get_vendor_by_user_id(db: Session, user_id: int):
    vendor = db.query(Vendor).options(joinedload(Vendor.user)).filter(Vendor.user_id == user_id).first()
    if vendor:
        print(f"DEBUG vendor_service: Found vendor ID {vendor.id} for user_id {user_id}, company: {vendor.company_name}")
        # Verify the user relationship is correct
        if vendor.user and vendor.user.id != user_id:
            print(f"ERROR: Vendor.user.id ({vendor.user.id}) doesn't match requested user_id ({user_id})!")
    else:
        print(f"DEBUG vendor_service: No vendor found for user_id {user_id}")
    return vendor

def get_vendor_by_id(db: Session, vendor_id: int):
    return db.query(Vendor).options(joinedload(Vendor.user)).filter(Vendor.id == vendor_id).first()

def update_vendor(db: Session, vendor_id: int, update_data: Dict[str, Any]):
    vendor = get_vendor_by_id(db, vendor_id)
    if vendor:
        # Check if QR code needs regeneration before updating
        needs_qr_regeneration = should_regenerate_qr_code(vendor, update_data)
        
        # Handle user fields (email, full_name)
        user_update_data = {}
        if "email" in update_data and vendor.user:
            user_update_data["email"] = update_data.pop("email")
        if "full_name" in update_data and vendor.user:
            user_update_data["full_name"] = update_data.pop("full_name")
        
        # Update vendor fields
        for key, value in update_data.items():
            if hasattr(vendor, key):
                setattr(vendor, key, value)
        
        # Update user fields
        if user_update_data and vendor.user:
            for key, value in user_update_data.items():
                setattr(vendor.user, key, value)
        
        db.commit()
        db.refresh(vendor)
        
        # Regenerate QR code if needed and vendor is verified
        if needs_qr_regeneration and vendor.verification_status == VerificationStatus.VERIFIED:
            generate_and_save_qr_code(db, vendor)
        
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
        
        # Always generate QR code after verification (even if one exists, regenerate to ensure it's current)
        if vendor.verification_status == VerificationStatus.VERIFIED:
            try:
                qr_url = generate_and_save_qr_code(db, vendor)
                if qr_url:
                    print(f"QR code generated successfully for vendor {vendor.id}: {qr_url}")
                else:
                    print(f"WARNING: QR code generation returned None for vendor {vendor.id}")
            except Exception as e:
                print(f"ERROR: Failed to generate QR code for vendor {vendor.id}: {str(e)}")
                import traceback
                traceback.print_exc()
                # Don't fail verification if QR code generation fails
        
        return True

def get_all_vendors(db: Session):
    return db.query(Vendor).options(joinedload(Vendor.user)).all()

def get_verified_companies(db: Session):
    companies = db.query(Vendor.company_name)\
        .filter(Vendor.verification_status == VerificationStatus.VERIFIED)\
        .distinct().all()
    # Flatten list of tuples and filter empty
    return [c[0] for c in companies if c[0]]
