import sys
import os

# Add the parent directory to sys.path to resolve imports
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

from app.core.database import engine, Base
from app.models import User, SOCProfile, Organization, Visit, Document

def reset_db():
    print("Dropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("Database reset complete.")

if __name__ == "__main__":
    reset_db()
