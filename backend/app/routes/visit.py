from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core import database
from app.dependencies import auth
from app.services import visit_service, vendor_service
from app.schemas.visit import VisitResponse, VisitCreate, VisitCheckOut
from app.models.user import User
from app.models.vendor import VerificationStatus
from app.utils.cloudinary_util import upload_image_to_cloudinary

router = APIRouter()

@router.post("/check-in", response_model=VisitResponse)
def check_in(
    agent_id: Optional[int] = Form(None),
    check_in_latitude: float = Form(...),
    check_in_longitude: float = Form(...),
    area: Optional[str] = Form(None),
    pincode: Optional[str] = Form(None),
    city: Optional[str] = Form(None),
    state: Optional[str] = Form(None),
    purpose: Optional[str] = Form(None),
    selfie: UploadFile = File(...),
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=400, detail="Vendor profile not found")
    
    if vendor.verification_status != VerificationStatus.VERIFIED:
        raise HTTPException(status_code=403, detail="Only verified vendors can check in")

    # Save selfie to cloud
    try:
        print(f"DEBUG: Processing Check-in for user {current_user.id}")
        selfie_url = upload_image_to_cloudinary(selfie.file, folder="selfies")
        if not selfie_url:
            print("ERROR: Selfie upload returned None")
            raise HTTPException(status_code=500, detail="Failed to upload selfie to cloud")
        
        print(f"DEBUG: Selfie uploaded to {selfie_url}")

        visit_in = VisitCreate(
            agent_id=agent_id,
            check_in_latitude=check_in_latitude,
            check_in_longitude=check_in_longitude,
            area=area,
            pincode=pincode,
            city=city,
            state=state,
            purpose=purpose
        )
        
        return visit_service.create_visit(db, visit_in, vendor.id, selfie_url)
    except Exception as e:
        print(f"CRITICAL ERROR in check_in: {str(e)}")
        # Print stack trace
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.post("/{visit_id}/check-out", response_model=VisitResponse)
def check_out(
    visit_id: int,
    check_out_latitude: float = Form(...),
    check_out_longitude: float = Form(...),
    selfie: UploadFile = File(...),
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    visit = visit_service.get_visit_by_id(db, visit_id)
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")
        
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if visit.vendor_id != vendor.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this visit")

    selfie_url = upload_image_to_cloudinary(selfie.file, folder="selfies")
    if not selfie_url:
        raise HTTPException(status_code=500, detail="Failed to upload selfie to cloud")
    
    visit_out = VisitCheckOut(
        check_out_latitude=check_out_latitude,
        check_out_longitude=check_out_longitude
    )
    
    return visit_service.update_visit_checkout(db, visit_id, visit_out, selfie_url)

@router.get("/", response_model=List[VisitResponse])
def read_visits(
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=400, detail="Vendor profile not found")
    return [v for v in visit_service.get_all_visits(db) if v.vendor_id == vendor.id]
