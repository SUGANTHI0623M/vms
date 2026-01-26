import json
import io
from datetime import datetime, timezone
from typing import Dict, Optional
from sqlalchemy.orm import Session
from app.models.vendor import Vendor
from app.utils.cloudinary_util import upload_image_to_cloudinary

# Try to import qrcode, but make it optional
try:
    import qrcode
    QRCODE_AVAILABLE = True
except ImportError:
    QRCODE_AVAILABLE = False
    print("WARNING: qrcode package not installed. QR code generation will be disabled.")
    print("Install it with: pip install qrcode Pillow")


def generate_qr_code_data(vendor: Vendor) -> Dict[str, str]:
    """
    Generate QR code data payload with company details.
    
    Returns:
        Dictionary containing company_id, company_name, GSTN_number, company_owner_name
    """
    return {
        "company_id": str(vendor.id),
        "company_name": vendor.company_name or "",
        "GSTN_number": vendor.gstin or "",
        "company_owner_name": vendor.user.full_name if vendor.user else ""
    }


def generate_qr_code_image(qr_data: Dict[str, str]) -> io.BytesIO:
    """
    Generate QR code image from data dictionary.
    
    Args:
        qr_data: Dictionary containing company details
        
    Returns:
        BytesIO object containing the QR code image
    """
    if not QRCODE_AVAILABLE:
        raise ImportError("qrcode package is not installed. Please install it with: pip install qrcode Pillow")
    
    # Convert dict to JSON string
    json_data = json.dumps(qr_data, ensure_ascii=False)
    
    # Create QR code instance
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(json_data)
    qr.make(fit=True)
    
    # Create image
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Convert to BytesIO
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    return img_bytes


def generate_and_save_qr_code(db: Session, vendor: Vendor) -> Optional[str]:
    """
    Generate QR code for a vendor and save it to Cloudinary.
    
    Args:
        db: Database session
        vendor: Vendor instance
        
    Returns:
        URL of the uploaded QR code image, or None if failed
    """
    try:
        # Generate QR code data
        qr_data = generate_qr_code_data(vendor)
        qr_data_json = json.dumps(qr_data, ensure_ascii=False)
        
        # Generate QR code image
        qr_image = generate_qr_code_image(qr_data)
        
        # Upload to Cloudinary
        qr_image.seek(0)  # Reset file pointer
        qr_url = upload_image_to_cloudinary(qr_image, folder="qr_codes")
        
        if qr_url:
            # Save to database
            vendor.qr_code_data = qr_data_json
            vendor.qr_code_image_url = qr_url
            vendor.qr_code_generated_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(vendor)
            return qr_url
        else:
            print(f"ERROR: Failed to upload QR code to Cloudinary for vendor {vendor.id}")
            return None
            
    except Exception as e:
        print(f"ERROR: Failed to generate QR code for vendor {vendor.id}: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def should_regenerate_qr_code(vendor: Vendor, updated_fields: Dict) -> bool:
    """
    Check if QR code should be regenerated based on updated fields.
    
    Args:
        vendor: Vendor instance
        updated_fields: Dictionary of fields being updated
        
    Returns:
        True if QR code should be regenerated, False otherwise
    """
    # Fields that affect QR code data
    qr_relevant_fields = ['company_name', 'gstin']
    
    # Check if any QR-relevant field is being updated
    for field in qr_relevant_fields:
        if field in updated_fields:
            return True
    
    # Also regenerate if owner name changes (via user update)
    if 'full_name' in updated_fields and vendor.user:
        return True
    
    # Regenerate if QR code doesn't exist
    if not vendor.qr_code_image_url:
        return True
    
    return False


def decode_qr_code_data(qr_data_json: str) -> Optional[Dict[str, str]]:
    """
    Decode QR code JSON data.
    
    Args:
        qr_data_json: JSON string from QR code
        
    Returns:
        Dictionary with company details, or None if invalid
    """
    try:
        return json.loads(qr_data_json)
    except (json.JSONDecodeError, TypeError):
        return None
