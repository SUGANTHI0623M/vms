"""
Script to generate QR codes for all verified vendors who don't have one yet.
Run this script to backfill QR codes for existing verified users.
"""
import sys
import os
sys.path.append(os.path.dirname(__file__))

from app.core.database import SessionLocal
from app.models.vendor import Vendor, VerificationStatus
from app.services.qr_code_service import generate_and_save_qr_code

def generate_qr_codes_for_verified_vendors():
    """Generate QR codes for all verified vendors who don't have one"""
    db = SessionLocal()
    try:
        # Get all verified vendors without QR codes
        verified_vendors = db.query(Vendor).filter(
            Vendor.verification_status == VerificationStatus.VERIFIED,
            (Vendor.qr_code_image_url == None) | (Vendor.qr_code_image_url == "")
        ).all()
        
        print(f"Found {len(verified_vendors)} verified vendors without QR codes")
        
        success_count = 0
        error_count = 0
        
        for vendor in verified_vendors:
            try:
                print(f"Generating QR code for vendor {vendor.id} ({vendor.company_name})...")
                qr_url = generate_and_save_qr_code(db, vendor)
                if qr_url:
                    print(f"  ✓ Success: {qr_url}")
                    success_count += 1
                else:
                    print(f"  ✗ Failed: QR code generation returned None")
                    error_count += 1
            except Exception as e:
                print(f"  ✗ Error for vendor {vendor.id}: {str(e)}")
                error_count += 1
        
        print(f"\n=== Summary ===")
        print(f"Successfully generated: {success_count}")
        print(f"Failed: {error_count}")
        print(f"Total processed: {len(verified_vendors)}")
        
    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    print("Generating QR codes for verified vendors...")
    generate_qr_codes_for_verified_vendors()
