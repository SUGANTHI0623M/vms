from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core import database
from app.dependencies.auth import get_current_user
from app.services import document_service, vendor_service
from app.schemas.document import DocumentResponse
from app.models.user import User

router = APIRouter()

@router.post("/upload", response_model=DocumentResponse)
def upload_document(
    document_type: str = Form(...),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=400, detail="Vendor Profile required")
        
    from app.utils.cloudinary_util import upload_image_to_cloudinary
    file_url = upload_image_to_cloudinary(file.file, folder="documents")
    if not file_url:
        raise HTTPException(status_code=500, detail="Failed to upload document to cloud")
        
    return document_service.create_document(db, vendor.id, document_type, file_url)

@router.get("/", response_model=List[DocumentResponse])
def read_documents(
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=400, detail="Vendor Profile required")
    return document_service.get_profile_documents(db, vendor.id)
