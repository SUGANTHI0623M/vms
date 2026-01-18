import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from app.core.database import SessionLocal
from app.models.user import User

db = SessionLocal()
user = db.query(User).filter(User.email == 'hema@gmail.com').first()
if user:
    print(f"User found: {user.email}")
    print(f"Hash: {user.hashed_password[:20]}...")
    from app.core.security import verify_password
    try:
        match = verify_password('sugu#123', user.hashed_password)
        print(f"Password match: {match}")
        
        print(f"Is active: {getattr(user, 'is_active', 'Attribute Missing')}")
        
        from app.core import security
        token = security.create_access_token(data={"sub": user.email})
        print(f"Token created: {token[:10]}...")
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error: {e}")
else:
    print("User not found")
db.close()
