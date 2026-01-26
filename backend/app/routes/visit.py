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
async def check_in(
    agent_id: Optional[int] = Form(None),
    check_in_latitude: float = Form(...),
    check_in_longitude: float = Form(...),
    area: Optional[str] = Form(None),
    pincode: Optional[str] = Form(None),
    city: Optional[str] = Form(None),
    state: Optional[str] = Form(None),
    check_in_location: Optional[str] = Form(None), # Added
    purpose: Optional[str] = Form(None),
    company_name: Optional[str] = Form(None),
    selfie: UploadFile = File(...),
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=400, detail="Vendor profile not found")
    
    # Save selfie to cloud
    try:
        from fastapi.concurrency import run_in_threadpool
        selfie_url = await run_in_threadpool(upload_image_to_cloudinary, selfie.file, "selfies")
        
        if not selfie_url:
            raise HTTPException(status_code=500, detail="Failed to upload selfie to cloud")
        
        # Format purpose only if company name is provided, otherwise leave it to service to detect
        final_purpose = purpose
        if company_name:
            if final_purpose:
                final_purpose = f"Visiting: {company_name}. {final_purpose}"
            else:
                final_purpose = f"Visiting: {company_name}"

        visit_in = VisitCreate(
            agent_id=agent_id,
            check_in_latitude=check_in_latitude,
            check_in_longitude=check_in_longitude,
            area=area,
            pincode=pincode,
            city=city,
            state=state,
            check_in_location=check_in_location,
            purpose=final_purpose
        )
        
        # Pass company_name explicitly to service for logic
        return visit_service.create_visit(db, visit_in, vendor.id, selfie_url, user_provided_company=company_name)
    except Exception as e:
        print(f"CRITICAL ERROR in check_in: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.post("/{visit_id}/check-out", response_model=VisitResponse)
async def check_out(
    visit_id: int,
    check_out_latitude: float = Form(...),
    check_out_longitude: float = Form(...),
    check_out_location: Optional[str] = Form(None), # Added
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

    from fastapi.concurrency import run_in_threadpool
    selfie_url = await run_in_threadpool(upload_image_to_cloudinary, selfie.file, "selfies")
    
    if not selfie_url:
        raise HTTPException(status_code=500, detail="Failed to upload selfie to cloud")
    
    visit_out = VisitCheckOut(
        check_out_latitude=check_out_latitude,
        check_out_longitude=check_out_longitude,
        check_out_location=check_out_location
    )
    
    return visit_service.update_visit_checkout(db, visit_id, visit_out, selfie_url)

@router.get("/", response_model=List[VisitResponse])
def read_visits(
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    if current_user.role == "admin" or current_user.is_superuser:
        return visit_service.get_all_visits(db)

    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        return []
        
    return visit_service.get_visits_for_vendor_view(db, vendor.id, vendor.company_name)
