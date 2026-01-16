import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
user = db.query(User).filter(User.email == 'sugu@gmail.com').first()
if user:
    print(f"User found: {user.email}")
    print(f"Hash: {user.hashed_password[:20]}...")
    from app.core.security import verify_password
    try:
        match = verify_password('sugu#123', user.hashed_password)
        print(f"Password match: {match}")
    except Exception as e:
        print(f"Error during verification: {e}")
else:
    print("User not found")
db.close()
