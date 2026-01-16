import shutil
from pathlib import Path
from fastapi import UploadFile
import uuid

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

def save_upload_file(upload_file: UploadFile, sub_dir: str = "misc") -> str:
    target_dir = UPLOAD_DIR / sub_dir
    target_dir.mkdir(parents=True, exist_ok=True)
    
    file_extension = upload_file.filename.split(".")[-1]
    file_name = f"{uuid.uuid4()}.{file_extension}"
    file_path = target_dir / file_name
    
    with file_path.open("wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
        
    return str(file_path)
