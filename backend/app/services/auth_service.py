from sqlalchemy.orm import Session
from app.models.user import User
from app.models.vendor import Vendor
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
        role="vendor"
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create associated vendor profile
    db_vendor = Vendor(
        user_id=db_user.id,
        phone_number=getattr(user, 'phone_number', ""),
        company_name=getattr(user, 'company_name', ""),
        office_address=getattr(user, 'office_address', "")
    )
    db.add(db_vendor)
    db.commit()
    
    return db_user
