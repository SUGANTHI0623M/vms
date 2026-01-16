from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core import database
from app.schemas.vendor import VendorUpdate, VendorResponse
from app.services import vendor_service
from app.dependencies import auth
from app.models.user import User

router = APIRouter()

@router.get("/me", response_model=VendorResponse)
def get_my_profile(
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    print(f"DEBUG: GET /me requested by User ID: {current_user.id}, Email: {current_user.email}")
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        print(f"DEBUG: Vendor profile NOT FOUND for User ID: {current_user.id}")
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    
    # Enrich response with user details
    vendor.email = current_user.email
    vendor.full_name = current_user.full_name
    return vendor

@router.put("/me", response_model=VendorResponse)
def update_my_profile(
    vendor_in: VendorUpdate,
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    print(f"DEBUG: PUT /me requested by User ID: {current_user.id}, Email: {current_user.email}")
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        print(f"DEBUG: Vendor profile NOT FOUND for User ID: {current_user.id}")
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    
    updated_vendor = vendor_service.update_vendor(db, vendor.id, vendor_in.model_dump(exclude_unset=True))
    updated_vendor.email = current_user.email
    updated_vendor.full_name = current_user.full_name
    return updated_vendor

@router.post("/me/verify", response_model=bool)
def verify_my_profile(
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    
    return vendor_service.verify_profile(db, vendor.id)
