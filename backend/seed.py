import sys
import os
from sqlalchemy.orm import Session

# Add the parent directory to sys.path to resolve imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from app.core.database import SessionLocal
from app.services.auth_service import create_user
from app.schemas.user import UserCreate
from app.models.user import User
from app.models.vendor import Vendor, VerificationStatus
from app.models.visit import Visit
from app.models.agent import Agent
from app.models.document import Document
from app.core import security

def seed_users():
    db: Session = SessionLocal()
    
    users = [
        {
            "email": "sugu@gmail.com",
            "password": "sugu#123",
            "full_name": "Sugu Vendor",
            "phone_number": "1234567890",
            "company_name": "Sugu Tech",
            "office_address": "123 Tech Park, Chennai",
            "status": VerificationStatus.VERIFIED
        },
        {
            "email": "sugu@gmai.com",
            "password": "sugu#123",
            "full_name": "Sugu Vendor",
            "phone_number": "1234567890",
            "company_name": "Sugu Tech",
            "office_address": "123 Tech Park, Chennai",
            "status": VerificationStatus.VERIFIED
        },
        {
            "email": "hema@gmail.com",
            "password": "hema#123",
            "full_name": "Hema Vendor",
            "phone_number": "0987654321",
            "company_name": "Hema Solutions",
            "office_address": "456 IT Hub, Bangalore",
            "status": VerificationStatus.PENDING
        }
    ]

    for user_data in users:
        email = user_data["email"].lower().strip()
        # Check if user exists
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"User {user_data['email']} already exists. Updating password and status...")
            existing_user.hashed_password = security.get_password_hash(user_data["password"])
            existing_user.vendor_profile.verification_status = user_data["status"]
            db.commit()
            continue

        user_in = UserCreate(
            email=email,
            password=user_data["password"],
            full_name=user_data["full_name"],
            phone_number=user_data["phone_number"],
            company_name=user_data["company_name"],
            office_address=user_data["office_address"]
        )
        
        created_user = create_user(db, user_in)
        # Manually set status for demo
        created_user.vendor_profile.verification_status = user_data["status"]
        db.commit()
        print(f"Created user {email} with status {user_data['status']}")

    db.close()

if __name__ == "__main__":
    seed_users()
