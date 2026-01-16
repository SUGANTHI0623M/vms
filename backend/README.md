# Vendor Management System Backend

FastAPI backend for VMS.

## Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate # or venv\Scripts\activate on Windows
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the server:
   ```bash
   uvicorn app.main:app --reload
   ```

## Folder Structure

- `app/core`: Configuration, database, security
- `app/models`: SQLAlchemy Database models
- `app/schemas`: Pydantic schemas for data validation
- `app/routes`: API endpoints
- `app/services`: Business logic
- `app/utils`: Helper functions (JWT, file upload)
- `app/dependencies`: Request dependencies (Auth)
