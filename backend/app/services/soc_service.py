from sqlalchemy.orm import Session
from app.models.soc_profile import SOCProfile
from app.models.user import User, UserRole
from app.schemas.soc_profile import SOCProfileCreate, SOCProfileUpdate
from app.core.security import get_password_hash
from app.utils.soc import generate_soc_id
import logging

def create_soc_profile(db: Session, profile_in: SOCProfileCreate):
    # 1. Create User
    db_user = User(
        email=profile_in.email,
        hashed_password=get_password_hash(profile_in.password),
        full_name=profile_in.full_name,
        role=UserRole.VISITOR
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # 2. Generate unique SOC ID
    soc_id = generate_soc_id()
    
    # 3. Create SOC Profile
    db_profile = SOCProfile(
        user_id=db_user.id,
        soc_id=soc_id,
        phone_number=profile_in.phone_number,
        company_name=profile_in.company_name,
        role_type=profile_in.role_type,
        service_category=profile_in.service_category,
        bluetooth_id=profile_in.bluetooth_id,
        device_id=profile_in.device_id
    )
    db.add(db_profile)
    db.commit()
    db.refresh(db_profile)
    return db_profile

def get_profile_by_soc_id(db: Session, soc_id: str):
    return db.query(SOCProfile).filter(SOCProfile.soc_id == soc_id).first()

def get_profile_by_user_id(db: Session, user_id: int):
    return db.query(SOCProfile).filter(SOCProfile.user_id == user_id).first()

def get_profile_by_bluetooth_id(db: Session, bluetooth_id: str):
    return db.query(SOCProfile).filter(SOCProfile.bluetooth_id == bluetooth_id).first()

def update_profile(db: Session, db_profile: SOCProfile, profile_in: SOCProfileUpdate):
    update_data = profile_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_profile, field, value)
    db.commit()
    db.refresh(db_profile)
    return db_profile
