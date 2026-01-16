import sys
import os
from sqlalchemy.orm import Session

# Add the parent directory to sys.path to resolve imports
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from app.core.database import SessionLocal, engine, Base
from app.models.user import User, UserRole
from app.models.vendor import Vendor, VerificationStatus
from app.core import security

def create_test_users():
    db: Session = SessionLocal()
    
    users_to_create = [
        {"email": "hema@gmail.com", "password": "hema#123", "name": "Hema User"},
        {"email": "test1@gmail.com", "password": "test1#123", "name": "Test User 1"},
        {"email": "test2@gmail.com", "password": "test2#123", "name": "Test User 2"},
        {"email": "test3@gmail.com", "password": "test3#123", "name": "Test User 3"},
        {"email": "test4@gmail.com", "password": "test4#123", "name": "Test User 4"},
        {"email": "test5@gmail.com", "password": "test5#123", "name": "Test User 5"},
    ]

    print("--- Creating Test Users ---")

    for user_data in users_to_create:
        email = user_data["email"]
        password = user_data["password"]
        name = user_data["name"]

        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"User {email} already exists. Skipping.")
            # Ensure vendor profile exists
            vendor = db.query(Vendor).filter(Vendor.user_id == existing_user.id).first()
            if not vendor:
                vendor = Vendor(
                    user_id=existing_user.id,
                    phone_number=f"900000000{users_to_create.index(user_data)}", # Dummy phone
                    company_name=f"{name} Co",
                    office_address="123 Test St"
                )
                db.add(vendor)
                db.commit()
                print(f"  -> Created missing vendor profile for {email}")
            continue

        # Create User
        new_user = User(
            email=email,
            hashed_password=security.get_password_hash(password),
            full_name=name,
            role=UserRole.VENDOR
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        # Create Vendor Profile
        # Verify 'hema' by default for testing check-in
        is_verified = VerificationStatus.VERIFIED if email == "hema@gmail.com" else VerificationStatus.PENDING
        
        vendor = Vendor(
            user_id=new_user.id,
            phone_number=f"900000000{users_to_create.index(user_data)}", 
            company_name=f"{name} Co",
            office_address="123 Test St",
            verification_status=is_verified
        )
        # Generate dummy UID
        import uuid
        if is_verified == VerificationStatus.VERIFIED:
            vendor.vendor_uid = str(uuid.uuid4())[:8].upper()

        db.add(vendor)
        db.commit()
        print(f"Created User: {email} (Verified: {is_verified})")

    db.close()
    print("--- Done ---")

if __name__ == "__main__":
    create_test_users()
