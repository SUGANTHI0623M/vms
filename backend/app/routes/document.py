from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core import database
from app.dependencies import auth
from app.services import document_service, vendor_service
from app.schemas.document import DocumentResponse
from app.models.user import User

router = APIRouter()

@router.post("/upload", response_model=DocumentResponse)
async def upload_document(
    document_type: str = Form(...),
    file: UploadFile = File(...),
    current_user: User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    print(f"DEBUG: Processing upload. Type: {document_type}, File: {file.filename}, User: {current_user.id}")
    vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
    if not vendor:
        print(f"DEBUG: Vendor not found for user {current_user.id}")
        raise HTTPException(status_code=400, detail="Vendor Profile required")
        
    from app.utils.cloudinary_util import upload_image_to_cloudinary
    from fastapi.concurrency import run_in_threadpool
    
    print("DEBUG: Calling Cloudinary utility...")
    # Run in threadpool to avoid blocking
    file_url = await run_in_threadpool(upload_image_to_cloudinary, file.file, "documents")
    
    if not file_url:
        print("DEBUG: Cloudinary returned None")
        raise HTTPException(status_code=500, detail="Failed to upload document to cloud")
        
    print(f"DEBUG: Saving document record to DB. Vendor ID: {vendor.id}")
    doc = document_service.create_document(db, vendor.id, document_type, file_url)
    
    # If it's a logo, update vendor profile directly
    if document_type == "LOGO":
        vendor.logo_url = file_url
        db.commit()
        db.refresh(vendor)
        
    return doc

@router.get("/", response_model=List[DocumentResponse])
def read_documents(
    current_user: User = Depends(auth.get_current_active_user), 
    db: Session = Depends(database.get_db)
):
    try:
        vendor = vendor_service.get_vendor_by_user_id(db, current_user.id)
        if not vendor:
            print(f"DEBUG: Vendor not found for user {current_user.id}")
            raise HTTPException(status_code=400, detail="Vendor Profile required")
        
        documents = document_service.get_profile_documents(db, vendor.id)
        print(f"DEBUG: Found {len(documents)} documents for vendor {vendor.id}")
        
        # Log each document
        for doc in documents:
            print(f"DEBUG: Document {doc.id}: type={doc.document_type}, url={doc.file_url}, uploaded_at={doc.uploaded_at}")
        
        # Return documents directly - FastAPI will serialize using DocumentResponse
        # Make sure we're not accessing any relationships
        return documents
    except HTTPException:
        raise
    except Exception as e:
        print(f"ERROR in read_documents: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
