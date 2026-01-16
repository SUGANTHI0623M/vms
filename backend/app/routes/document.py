from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core import database
from app.dependencies import auth
from app.services import document_service, vendor_service
from app.schemas.document import DocumentResponse
from app.utils.file_upload import save_upload_file

router = APIRouter()

@router.post("/upload", response_model=DocumentResponse)
def upload_document(
    document_type: str = Form(...),
    file: UploadFile = File(...),
    current_user = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        raise HTTPException(status_code=400, detail="Vendor profile required")
        
    from app.utils.cloudinary_util import upload_image_to_cloudinary
    file_url = upload_image_to_cloudinary(file.file, folder="documents")
    if not file_url:
        raise HTTPException(status_code=500, detail="Failed to upload document to cloud")
        
    return document_service.create_document(db, vendor.id, document_type, file_url)

@router.get("/", response_model=List[DocumentResponse])
def read_documents(current_user = Depends(auth.get_current_active_user), db: Session = Depends(database.get_db)):
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
         raise HTTPException(status_code=400, detail="Vendor profile required")
    return document_service.get_vendor_documents(db, vendor.id)
