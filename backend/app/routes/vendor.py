from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core import database
from app.dependencies import auth
from app.services import vendor_service
from app.schemas.vendor import VendorResponse
from app.models.user import User

router = APIRouter()

@router.get("/me", response_model=VendorResponse)
def read_users_me(current_user: User = Depends(auth.get_current_active_user), db: Session = Depends(database.get_db)):
    vendor = vendor_service.get_vendor_by_user_id(db, user_id=current_user.id)
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    return vendor
