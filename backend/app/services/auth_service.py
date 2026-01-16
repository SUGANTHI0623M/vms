from sqlalchemy.orm import Session
from app.models.user import User
from app.models.vendor import Vendor, VerificationStatus
from app.schemas.user import UserCreate
from app.core import security

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, user: UserCreate):
    hashed_password = security.get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        role="vendor" # Default to vendor as per requirement
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create associated Vendor profile
    db_vendor = Vendor(
        user_id=db_user.id,
        phone_number=user.phone_number,
        company_name=user.company_name,
        office_address=user.office_address,
        verification_status=VerificationStatus.PENDING
    )
    db.add(db_vendor)
    db.commit()
    db.refresh(db_vendor)
    
    return db_user
