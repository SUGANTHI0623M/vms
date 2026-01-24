import sys
import os

# Add the parent directory to sys.path so we can import 'app'
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.models.user import User
from app.core.security import verify_password, get_password_hash

def check_login(email, password):
    db = SessionLocal()
    try:
        print(f"Checking user: {email}")
        user = db.query(User).filter(User.email == email).first()
        
        if not user:
            print("User not found in database")
            return

        print(f"User found: {user.email}")
        print(f"   ID: {user.id}")
        print(f"   Role: {user.role}")
        print(f"   Is Active: {user.is_active}")
        
        # Check password
        is_valid = verify_password(password, user.hashed_password)
        print(f"   Password verification: {'Valid' if is_valid else 'Invalid'}")
        
        if not is_valid:
            print(f"   Stored hash: {user.hashed_password}")
            # print(f"   New hash for '{password}': {get_password_hash(password)}")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    check_login("test5@gmail.com", "test5#123")
