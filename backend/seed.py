import sys
import os
from sqlalchemy.orm import Session

# Add the parent directory to sys.path to resolve imports
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from app.core.database import SessionLocal, engine, Base
from app.models.user import User, UserRole
from app.models.soc_profile import SOCProfile
from app.models.vendor import Vendor
# from app.models.organization import Organization
from app.core import security
from app.utils.soc import generate_soc_id

def seed_data():
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    
    # 1. Create Organization - SKIPPED
    # org = db.query(Organization).filter(Organization.name == "Main Office").first()
    # if not org:
    #     org = Organization(
    #         name="Main Office",
    #         address="123 Corporate Blvd",
    #         contact_email="admin@mainoffice.com",
    #         subscription_plan="free"
    #     )
    #     db.add(org)
    #     db.commit()
    #     db.refresh(org)
    #     print("Created Organization: Main Office")

    # 2. Create Security User
    security_user = db.query(User).filter(User.email == "security@vms.com").first()
    if not security_user:
        security_user = User(
            email="security@vms.com",
            hashed_password=security.get_password_hash("security123"),
            full_name="Guard One",
            role=UserRole.SECURITY
        )
        db.add(security_user)
        db.commit()
        print("Created Security User: security@vms.com")

    # 3. Create Client User (The one who approves)
    client_user = db.query(User).filter(User.email == "manager@vms.com").first()
    if not client_user:
        client_user = User(
            email="manager@vms.com",
            hashed_password=security.get_password_hash("manager123"),
            full_name="Office Manager",
            role=UserRole.CLIENT
        )
        db.add(client_user)
        db.commit()
        print("Created Client User: manager@vms.com")

    # 4. Create a Service Provider Technician
    tech_user = db.query(User).filter(User.email == "tech@vms.com").first()
    if not tech_user:
        tech_user = User(
            email="tech@vms.com",
            hashed_password=security.get_password_hash("tech123"),
            full_name="John Technician",
            role=UserRole.VISITOR
        )
        db.add(tech_user)
        db.commit()
        db.refresh(tech_user)
        
        soc_profile = SOCProfile(
            user_id=tech_user.id,
            soc_id=generate_soc_id(),
            phone_number="9876543210",
            company_name="AC Repair Co",
            role_type="Technician",
            service_category="Maintenance",
            bluetooth_id="BT-001",
            device_id="DEV-001",
            is_verified=True
        )
        db.add(soc_profile)
        db.commit()
        print(f"Created Technician Profile with SOC ID: {soc_profile.soc_id}")

    # 5. Create Sugu User (Vendor)
    sugu_user = db.query(User).filter(User.email == "sugu@gmail.com").first()
    if not sugu_user:
        sugu_user = User(
            email="sugu@gmail.com",
            hashed_password=security.get_password_hash("password123"), # Default password
            full_name="Sugu Vendor",
            role=UserRole.VENDOR
        )
        db.add(sugu_user)
        db.commit()
        db.refresh(sugu_user)
        print("Created Sugu User: sugu@gmail.com")

    # Ensure Sugu has a vendor profile
    if sugu_user:
        sugu_vendor = db.query(Vendor).filter(Vendor.user_id == sugu_user.id).first()
        if not sugu_vendor:
            sugu_vendor = Vendor(
                user_id=sugu_user.id,
                phone_number="",
                company_name="",
                office_address=""
            )
            db.add(sugu_vendor)
            db.commit()
            print("Created Sugu Vendor Profile")

    db.close()

if __name__ == "__main__":
    seed_data()
