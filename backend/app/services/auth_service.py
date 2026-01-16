from sqlalchemy.orm import Session
from app.models.user import User
from app.models.vendor import Vendor
from app.models.otp import OTP
from app.schemas.user import UserCreate
from app.core import security
from datetime import datetime, timedelta

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def get_user_by_phone(db: Session, phone: str):
    return db.query(User).filter(User.phone_number == phone).first()

def create_otp(db: Session, identifier: str, purpose: str):
    # Expire old OTPs for this identifier/purpose
    db.query(OTP).filter(OTP.identifier == identifier, OTP.purpose == purpose).delete()
    
    code = OTP.generate_code()
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    db_otp = OTP(identifier=identifier, code=code, purpose=purpose, expires_at=expires_at)
    db.add(db_otp)
    db.commit()
    return code

def verify_otp(db: Session, identifier: str, code: str, purpose: str):
    otp = db.query(OTP).filter(
        OTP.identifier == identifier,
        OTP.code == code,
        OTP.purpose == purpose,
        OTP.expires_at > datetime.utcnow()
    ).first()
    if otp:
        db.delete(otp)
        db.commit()
        return True
    return False

def reset_password(db: Session, identifier: str, new_password: str):
    user = get_user_by_email(db, identifier) or get_user_by_phone(db, identifier)
    if user:
        user.hashed_password = security.get_password_hash(new_password)
        db.commit()
        return True
    return False

def create_user(db: Session, user: UserCreate):
    hashed_password = security.get_password_hash(user.password)
    db_user = User(
        email=user.email,
        hashed_password=hashed_password,
        full_name=user.full_name,
        phone_number=user.phone_number,
        role="vendor"
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Create associated vendor profile
    db_vendor = Vendor(
        user_id=db_user.id,
        phone_number=user.phone_number or "",
        company_name=getattr(user, 'company_name', ""),
        office_address=getattr(user, 'office_address', "")
    )
    db.add(db_vendor)
    db.commit()
    
    return db_user
