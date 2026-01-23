import sys
import os
from sqlalchemy.orm import Session

# Add the parent directory to sys.path to resolve imports
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from app.core.database import SessionLocal
from app.models.user import User, UserRole
from app.models.vendor import Vendor, VerificationStatus
from app.core import security

def create_more_test_users():
    db: Session = SessionLocal()
    
    # Users test6 to test10 (5 users)
    # Logic: "insert test6... to test10 users" interpreted as range [6, 10].
    
    users_to_create = []
    for i in range(6, 11):
        users_to_create.append({
            "email": f"test{i}@gmail.com",
            "password": f"test{i}#123",
            "name": f"Test User {i}",
            "phone_suffix": f"{i:02d}" # 06, 07...
        })

    print("--- Creating Test Users 6-10 ---")

    for user_data in users_to_create:
        email = user_data["email"]
        password = user_data["password"]
        name = user_data["name"]
        suffix = user_data["phone_suffix"]

        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"User {email} already exists. Skipping.")
            continue

        # Create User
        new_user = User(
            email=email,
            hashed_password=security.get_password_hash(password),
            full_name=name,
            role=UserRole.VENDOR,
            phone_number=f"99990000{suffix}" # Example: 9999000006
        )
        db.add(new_user)
        try:
            db.commit()
            db.refresh(new_user)
        except Exception as e:
            db.rollback()
            print(f"Error creating user {email}: {e}")
            continue
        
        # Create Vendor Profile
        # All non-verified as requested
        vendor = Vendor(
            user_id=new_user.id,
            phone_number=f"99990000{suffix}", 
            company_name=f"{name} Co",
            office_address="Testing Lane 123",
            verification_status=VerificationStatus.PENDING
        )
        
        db.add(vendor)
        try:
            db.commit()
            print(f"Created User: {email} (Verified: PENDING)")
        except Exception as e:
            db.rollback()
            print(f"Error creating vendor for {email}: {e}")
            
    db.close()
    print("--- Done ---")

if __name__ == "__main__":
    create_more_test_users()
