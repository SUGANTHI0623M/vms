import sys
import os
from sqlalchemy import text
from sqlalchemy.orm import Session

# Add the parent directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from app.core.database import SessionLocal, engine
from app.models.vendor import Vendor, VerificationStatus
from app.models.user import User

def debug_vendor_update():
    print("Connecting to database...")
    db: Session = SessionLocal()
    
    try:
        # 1. Check Vendor Table Schema
        print("\n--- Checking Vendors Table Schema ---")
        with engine.connect() as connection:
            result = connection.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vendors';"))
            columns = [row[0] for row in result]
            print(f"Columns found: {columns}")
            
            required_cols = ['dob', 'gender', 'phone_number', 'company_name', 'office_address']
            missing = [c for c in required_cols if c not in columns]
            if missing:
                print(f"CRITICAL: Missing columns in DB: {missing}")
            else:
                print("Schema check passed: All required columns exist.")

        # 2. Try to fetch the Sugu User and Vendor
        print("\n--- Checking Sugu User ---")
        user = db.query(User).filter(User.email == "sugu@gmail.com").first()
        if not user:
            print("User sugu@gmail.com NOT FOUND!")
            return
        
        print(f"User found: ID={user.id}")
        
        vendor = db.query(Vendor).filter(Vendor.user_id == user.id).first()
        if not vendor:
            print("Vendor profile for Sugu NOT FOUND!")
            return
            
        print(f"Vendor found: ID={vendor.id}, Status={vendor.verification_status}")
        
        # 3. Attempt Dummy Update
        print("\n--- Attempting Update ---")
        vendor.dob = "01/01/1990"
        vendor.gender = "Male"
        vendor.phone_number = "1234567890" # Use a dummy number
        vendor.company_name = "Test Cop"
        vendor.office_address = "123 Test St"
        
        db.commit()
        print("Update SUCCESSFUL!")
        
    except Exception as e:
        print(f"\nERROR DURING DEBUG: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    debug_vendor_update()
