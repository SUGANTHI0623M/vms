from sqlalchemy.orm import Session
from app.core import database
from app.models.user import User
from app.models.vendor import Vendor

def check_users_and_vendors():
    db = database.SessionLocal()
    try:
        users = db.query(User).all()
        print(f"Total Users: {len(users)}")
        
        for user in users:
            vendor = db.query(Vendor).filter(Vendor.user_id == user.id).first()
            if vendor:
                print(f"[OK] User {user.email} (ID: {user.id}) -> Vendor ID: {vendor.id}")
            else:
                print(f"[MISSING] User {user.email} (ID: {user.id}) has NO Vendor profile!")
                
                # Auto-fix: Create the missing vendor profile
                print(f"Creating missing Vendor profile for User {user.id}...")
                new_vendor = Vendor(
                    user_id=user.id,
                    phone_number=f"000000000{user.id}"[-10:], # Dummy unique phone
                    company_name="Pending Setup",
                    office_address="Pending Setup"
                )
                db.add(new_vendor)
                db.commit()
                print(f"[FIXED] Created Vendor ID: {new_vendor.id}")

    finally:
        db.close()

if __name__ == "__main__":
    check_users_and_vendors()
