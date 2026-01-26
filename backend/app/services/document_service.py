from sqlalchemy.orm import Session, noload
from app.models.document import Document

def create_document(db: Session, vendor_id: int, document_type: str, file_url: str):
    # Check for existing document of this type
    existing_doc = db.query(Document).filter(
        Document.vendor_id == vendor_id,
        Document.document_type == document_type
    ).first()
    
    if existing_doc:
        print(f"DEBUG: Deleting existing document ID {existing_doc.id} of type {document_type}")
        db.delete(existing_doc)
        db.commit()

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
    # Query documents without loading relationships to avoid lazy loading issues
    # Use noload to prevent accessing the vendor relationship
    try:
        documents = db.query(Document).options(noload(Document.vendor)).filter(
            Document.vendor_id == vendor_id
        ).all()
        return documents
    except Exception as e:
        print(f"ERROR in get_profile_documents: {str(e)}")
        import traceback
        traceback.print_exc()
        # Fallback: query without noload if there's an issue
        return db.query(Document).filter(Document.vendor_id == vendor_id).all()
