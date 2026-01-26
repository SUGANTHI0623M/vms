from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core import database
from app.schemas.vendor import VendorUpdate, VendorResponse
from app.services import vendor_service
from app.services import qr_code_service
from app.dependencies import auth
from app.models.user import User
from app.models.vendor import Vendor, VerificationStatus
from app.models.company_location import CompanyLocation
from pydantic import BaseModel

router = APIRouter()

class CompanyLocationResponse(BaseModel):
    id: int
    company_name: str
    latitude: float
    longitude: float
    address: str = None
    
    class Config:
        from_attributes = True

@router.get("/", response_model=List[VendorResponse])
def get_all_vendors(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(auth.get_current_active_user)
):
    vendors = vendor_service.get_all_vendors(db)
    # Enrich each vendor with user details
    for vendor in vendors:
        if vendor.user:
            vendor.email = vendor.user.email
            vendor.full_name = vendor.user.full_name
    return vendors

@router.get("/companies", response_model=List[str])
def get_verified_companies(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(auth.get_current_active_user)
):
    return vendor_service.get_verified_companies(db)

@router.get("/company-locations", response_model=List[CompanyLocationResponse])
def get_company_locations(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(auth.get_current_active_user)
):
    """Get all company locations for location-based company detection"""
    locations = db.query(CompanyLocation).all()
    return locations

@router.get("/me", response_model=VendorResponse)
def get_my_profile(
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    print(f"DEBUG: GET /me requested by User ID: {current_user.id}, Email: {current_user.email}, Full Name: {current_user.full_name}")
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        print(f"DEBUG: Vendor profile NOT FOUND for User ID: {current_user.id}")
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    
    print(f"DEBUG: Found vendor ID: {vendor.id}, Company: {vendor.company_name}, User ID: {vendor.user_id}")
    
    # Verify we're returning the correct vendor for this user
    if vendor.user_id != current_user.id:
        print(f"ERROR: Vendor user_id ({vendor.user_id}) doesn't match current_user.id ({current_user.id})!")
        raise HTTPException(status_code=500, detail="Data mismatch: Vendor profile doesn't match user")
    
    # Enrich response with user details (use current_user to ensure correct data)
    vendor.email = current_user.email
    vendor.full_name = current_user.full_name
    
    print(f"DEBUG: Returning vendor profile - Vendor ID: {vendor.id}, Company: {vendor.company_name}, Email: {vendor.email}, Name: {vendor.full_name}")
    
    # If verified but no QR code, generate it
    if vendor.verification_status == VerificationStatus.VERIFIED:
        if not vendor.qr_code_image_url:
            print(f"DEBUG: Vendor {vendor.id} is verified but has no QR code. Generating...")
            try:
                qr_url = qr_code_service.generate_and_save_qr_code(db, vendor)
                db.refresh(vendor)
                if qr_url:
                    print(f"DEBUG: QR code generated successfully: {qr_url}")
                else:
                    print(f"WARNING: QR code generation returned None")
            except Exception as e:
                print(f"Warning: Failed to auto-generate QR code: {e}")
                import traceback
                traceback.print_exc()
        else:
            print(f"DEBUG: Vendor {vendor.id} already has QR code: {vendor.qr_code_image_url}")
    
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
    
    result = vendor_service.verify_profile(db, vendor.id)
    
    # Ensure QR code is generated after verification
    if result:
        db.refresh(vendor)
        if vendor.verification_status == VerificationStatus.VERIFIED and not vendor.qr_code_image_url:
            try:
                qr_code_service.generate_and_save_qr_code(db, vendor)
            except Exception as e:
                print(f"Warning: Failed to generate QR code after verification: {e}")
                # Don't fail verification if QR code generation fails
    
    return result


@router.get("/me/qr-code")
def get_my_qr_code(
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    """Get QR code for the current vendor's company. Generates one if it doesn't exist."""
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    
    if vendor.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(
            status_code=400, 
            detail="Company must be verified to generate QR code"
        )
    
    # Generate QR code if it doesn't exist (for existing verified users)
    if not vendor.qr_code_image_url or not vendor.qr_code_image_url.strip():
        try:
            qr_url = qr_code_service.generate_and_save_qr_code(db, vendor)
            db.refresh(vendor)
            if not qr_url:
                print(f"WARNING: QR code generation returned None for vendor {vendor.id}")
                raise HTTPException(
                    status_code=500,
                    detail="Failed to generate QR code. Please ensure qrcode and Pillow packages are installed."
                )
        except ImportError as e:
            print(f"ERROR: QR code package not available: {e}")
            raise HTTPException(
                status_code=503,
                detail="QR code generation is currently unavailable. Please install required packages: pip install qrcode Pillow"
            )
        except Exception as e:
            print(f"ERROR: Failed to generate QR code: {e}")
            import traceback
            traceback.print_exc()
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate QR code: {str(e)}"
            )
    
    # Return QR code data
    if not vendor.qr_code_image_url:
        raise HTTPException(
            status_code=500,
            detail="QR code not available"
        )
    
    return {
        "qr_code_data": vendor.qr_code_data,
        "qr_code_image_url": vendor.qr_code_image_url,
        "qr_code_generated_at": vendor.qr_code_generated_at.isoformat() if vendor.qr_code_generated_at else None
    }


class QRCodeScanRequest(BaseModel):
    qr_data: str  # JSON string from scanned QR code


class QRCodeScanResponse(BaseModel):
    company_id: int
    company_name: str
    GSTN_number: str
    company_owner_name: str
    is_verified: bool
    valid: bool


@router.post("/generate-all-qr-codes")
def generate_all_qr_codes(
    db: Session = Depends(database.get_db),
    current_user: User = Depends(auth.get_current_active_user)
):
    """
    Admin endpoint to generate QR codes for all verified vendors who don't have one.
    Useful for backfilling QR codes for existing verified users.
    """
    # Get all verified vendors without QR codes
    verified_vendors = db.query(Vendor).filter(
        Vendor.verification_status == VerificationStatus.VERIFIED,
        (Vendor.qr_code_image_url == None) | (Vendor.qr_code_image_url == "")
    ).all()
    
    results = {
        "total_found": len(verified_vendors),
        "success": 0,
        "failed": 0,
        "errors": []
    }
    
    for vendor in verified_vendors:
        try:
            qr_url = qr_code_service.generate_and_save_qr_code(db, vendor)
            if qr_url:
                results["success"] += 1
            else:
                results["failed"] += 1
                results["errors"].append(f"Vendor {vendor.id}: QR generation returned None")
        except Exception as e:
            results["failed"] += 1
            results["errors"].append(f"Vendor {vendor.id}: {str(e)}")
    
    return results


@router.post("/scan-qr-code", response_model=QRCodeScanResponse)
def scan_qr_code(
    qr_request: QRCodeScanRequest,
    db: Session = Depends(database.get_db),
    current_user: User = Depends(auth.get_current_active_user)
):
    """
    Validate scanned QR code and return company details.
    Used for check-in flow.
    """
    # Decode QR code data
    qr_data = qr_code_service.decode_qr_code_data(qr_request.qr_data)
    
    if not qr_data:
        raise HTTPException(
            status_code=400,
            detail="Invalid QR code format"
        )
    
    # Extract company ID
    try:
        company_id = int(qr_data.get("company_id", 0))
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=400,
            detail="Invalid company ID in QR code"
        )
    
    # Get vendor/company from database
    vendor = vendor_service.get_vendor_by_id(db, company_id)
    
    if not vendor:
        return QRCodeScanResponse(
            company_id=company_id,
            company_name=qr_data.get("company_name", ""),
            GSTN_number=qr_data.get("GSTN_number", ""),
            company_owner_name=qr_data.get("company_owner_name", ""),
            is_verified=False,
            valid=False
        )
    
    # Validate QR code data matches database
    is_valid = (
        vendor.company_name == qr_data.get("company_name") and
        vendor.gstin == qr_data.get("GSTN_number") and
        (vendor.user.full_name if vendor.user else "") == qr_data.get("company_owner_name")
    )
    
    return QRCodeScanResponse(
        company_id=vendor.id,
        company_name=vendor.company_name or "",
        GSTN_number=vendor.gstin or "",
        company_owner_name=vendor.user.full_name if vendor.user else "",
        is_verified=vendor.verification_status == VerificationStatus.VERIFIED,
        valid=is_valid
    )
