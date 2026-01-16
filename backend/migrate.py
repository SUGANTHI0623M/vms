from app.core.database import engine, Base
from app.models.user import User
from app.models.vendor import Vendor
from app.models.document import Document
from app.models.agent import Agent
from app.models.visit import Visit

print("Dropping all tables...")
# Try dropping in reverse order of dependencies
try:
    Base.metadata.drop_all(bind=engine)
except Exception as e:
    print(f"Standard drop failed, trying manual: {e}")

print("Creating all tables...")
Base.metadata.create_all(bind=engine)

print("Migration complete.")
