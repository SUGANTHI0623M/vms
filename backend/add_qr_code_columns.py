"""
Script to add QR code columns to vendors table if they don't exist.
Run this if the migration hasn't been applied yet.
"""
import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.core.database import SessionLocal, engine
from sqlalchemy import text

def add_qr_code_columns():
    """Add QR code columns to vendors table"""
    db = SessionLocal()
    try:
        # Check if columns exist
        with engine.begin() as conn:
            # Check if qr_code_data column exists
            result = conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name='vendors' AND column_name='qr_code_data'
            """))
            
            if result.fetchone() is None:
                print("Adding QR code columns to vendors table...")
                
                # Add columns
                conn.execute(text("""
                    ALTER TABLE vendors 
                    ADD COLUMN qr_code_data TEXT,
                    ADD COLUMN qr_code_image_url VARCHAR,
                    ADD COLUMN qr_code_generated_at TIMESTAMP WITH TIME ZONE
                """))
                print("QR code columns added successfully!")
            else:
                print("QR code columns already exist in vendors table")
                
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    print("Checking and adding QR code columns...")
    add_qr_code_columns()
