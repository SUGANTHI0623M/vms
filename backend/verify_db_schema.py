"""
Verify database schema matches models.
This will check if all required columns exist.
"""
import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.core.database import engine
from sqlalchemy import inspect, text

def verify_schema():
    """Verify that all model columns exist in the database"""
    try:
        inspector = inspect(engine)
        
        # Check vendors table
        print("Checking vendors table...")
        vendor_columns = {col['name']: col for col in inspector.get_columns('vendors')}
        
        required_columns = [
            'qr_code_data',
            'qr_code_image_url', 
            'qr_code_generated_at'
        ]
        
        missing = []
        for col_name in required_columns:
            if col_name not in vendor_columns:
                missing.append(col_name)
            else:
                print(f"  [OK] {col_name} exists")
        
        if missing:
            print(f"\n[ERROR] Missing columns: {missing}")
            print("\nTo fix, run: python check_and_fix_qr_columns.py")
            return False
        else:
            print("\n[SUCCESS] All QR code columns exist!")
            print("\nIf you're still getting errors, restart the server to pick up schema changes.")
            return True
            
    except Exception as e:
        print(f"Error checking schema: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("Verifying database schema...\n")
    verify_schema()
