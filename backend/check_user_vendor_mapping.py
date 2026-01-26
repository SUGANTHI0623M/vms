"""
Script to check user-vendor mapping and identify any mismatches.
"""
import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.core.database import SessionLocal
from app.models.user import User
from app.models.vendor import Vendor

def check_user_vendor_mapping():
    """Check all user-vendor relationships for mismatches"""
    db = SessionLocal()
    try:
        users = db.query(User).all()
        vendors = db.query(Vendor).all()
        
        print("=== User-Vendor Mapping Check ===\n")
        
        # Check each user
        for user in users:
            vendor = db.query(Vendor).filter(Vendor.user_id == user.id).first()
            if vendor:
                print(f"User {user.id} ({user.email}):")
                print(f"  Name: {user.full_name}")
                print(f"  Vendor ID: {vendor.id}")
                print(f"  Company: {vendor.company_name}")
                print(f"  Vendor User ID: {vendor.user_id}")
                if vendor.user_id != user.id:
                    print(f"  [ERROR] MISMATCH! Vendor.user_id ({vendor.user_id}) != User.id ({user.id})")
                print()
            else:
                print(f"User {user.id} ({user.email}): NO VENDOR PROFILE")
                print()
        
        # Check for orphaned vendors
        print("\n=== Checking for orphaned vendors ===")
        for vendor in vendors:
            user = db.query(User).filter(User.id == vendor.user_id).first()
            if not user:
                print(f"Vendor {vendor.id} (Company: {vendor.company_name}) has user_id {vendor.user_id} but user doesn't exist!")
            elif user.email not in [f"test{i}@gmail.com" for i in range(1, 11)] + ["hema@gmail.com"]:
                print(f"Vendor {vendor.id} belongs to user {vendor.user_id} ({user.email})")
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    check_user_vendor_mapping()
