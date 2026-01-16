from sqlalchemy.orm import Session
from app.models.document import Document

def create_document(db: Session, vendor_id: int, document_type: str, file_url: str):
    db_document = Document(
        vendor_id=vendor_id,
        document_type=document_type,
        file_url=file_url
    )
    db.add(db_document)
    db.commit()
    db.refresh(db_document)
    return db_document

def get_profile_documents(db: Session, vendor_id: int):
    return db.query(Document).filter(Document.vendor_id == vendor_id).all()
