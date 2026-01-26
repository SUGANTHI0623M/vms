"""
Script to check and fix QR code columns in vendors table.
This will verify the columns exist and add them if missing.
"""
import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.core.database import engine, SessionLocal
from sqlalchemy import text, inspect

def check_and_fix_columns():
    """Check if QR code columns exist and add them if missing"""
    try:
        with engine.connect() as conn:
            # Get current columns
            inspector = inspect(engine)
            columns = [col['name'] for col in inspector.get_columns('vendors')]
            
            print(f"Current columns in vendors table: {columns}")
            
            missing_columns = []
            if 'qr_code_data' not in columns:
                missing_columns.append('qr_code_data TEXT')
            if 'qr_code_image_url' not in columns:
                missing_columns.append('qr_code_image_url VARCHAR')
            if 'qr_code_generated_at' not in columns:
                missing_columns.append('qr_code_generated_at TIMESTAMP WITH TIME ZONE')
            
            if missing_columns:
                print(f"\nMissing columns: {missing_columns}")
                print("Adding missing columns...")
                
                with conn.begin():
                    for col_def in missing_columns:
                        col_name = col_def.split()[0]
                        col_type = ' '.join(col_def.split()[1:])
                        try:
                            conn.execute(text(f"ALTER TABLE vendors ADD COLUMN {col_name} {col_type}"))
                            print(f"  Added column: {col_name}")
                        except Exception as e:
                            print(f"  Error adding {col_name}: {e}")
                    
                    conn.commit()
                print("\nColumns added successfully!")
            else:
                print("\nAll QR code columns already exist!")
                
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("Checking QR code columns in vendors table...")
    check_and_fix_columns()
