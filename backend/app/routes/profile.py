from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core import database
from app.schemas.soc_profile import SOCProfile, SOCProfileCreate, SOCProfileUpdate
from app.services import soc_service, auth_service
from app.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter()

@router.post("/register", response_model=SOCProfile)
def register_soc(profile_in: SOCProfileCreate, db: Session = Depends(database.get_db)):
    # Check if user already exists
    user = auth_service.get_user_by_email(db, email=profile_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="User with this email already exists.",
        )
    return soc_service.create_soc_profile(db=db, profile_in=profile_in)

@router.get("/me", response_model=SOCProfile)
def get_my_profile(
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(database.get_db)
):
    profile = soc_service.get_profile_by_user_id(db, user_id=current_user.id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile

@router.get("/lookup/{soc_id}", response_model=SOCProfile)
def lookup_profile(soc_id: str, db: Session = Depends(database.get_db)):
    profile = soc_service.get_profile_by_soc_id(db, soc_id=soc_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile

@router.get("/detect/{bluetooth_id}", response_model=SOCProfile)
def detect_profile(bluetooth_id: str, db: Session = Depends(database.get_db)):
    profile = soc_service.get_profile_by_bluetooth_id(db, bluetooth_id=bluetooth_id)
    if not profile:
        raise HTTPException(status_code=404, detail="No profile associated with this Bluetooth ID")
    return profile
