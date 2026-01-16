import cloudinary
import cloudinary.uploader
from app.core.config import settings

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True
)

def upload_image_to_cloudinary(file, folder="vms_uploads"):
    # Debug logging
    print(f"DEBUG: Starting Cloudinary upload. Cloud Name: {settings.CLOUDINARY_CLOUD_NAME}, API Key: {settings.CLOUDINARY_API_KEY}")
    if settings.CLOUDINARY_API_SECRET:
        masked_secret = settings.CLOUDINARY_API_SECRET[:3] + "****" + settings.CLOUDINARY_API_SECRET[-3:]
        print(f"DEBUG: Using Secret: {masked_secret}")
    else:
        print("DEBUG: API Secret is MISSING!")

    try:
        upload_result = cloudinary.uploader.upload(file, folder=folder)
        url = upload_result.get("secure_url")
        print(f"DEBUG: Upload success! URL: {url}")
        return url
    except Exception as e:
        print(f"CRITICAL: Cloudinary upload FAILED. Error: {str(e)}")
        # If it's a specific Cloudinary error, it might have more details
        return None
