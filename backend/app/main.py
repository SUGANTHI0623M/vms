from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core import config, database
from app.routes import auth, vendor, visit, document, agent

import logging

# Create database tables
# In production, use Alembic migrations
database.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title=config.settings.PROJECT_NAME,
    openapi_url=f"{config.settings.API_V1_STR}/openapi.json",
    docs_url=f"{config.settings.API_V1_STR}/docs",
    redoc_url=f"{config.settings.API_V1_STR}/redoc",
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow all for development/Flutter
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=f"{config.settings.API_V1_STR}/auth", tags=["auth"])
app.include_router(vendor.router, prefix=f"{config.settings.API_V1_STR}/vendors", tags=["vendors"])
app.include_router(visit.router, prefix=f"{config.settings.API_V1_STR}/visits", tags=["visits"])
app.include_router(document.router, prefix=f"{config.settings.API_V1_STR}/documents", tags=["documents"])
app.include_router(agent.router, prefix=f"{config.settings.API_V1_STR}/agents", tags=["agents"])

@app.get("/")
def read_root():
    return {"message": "Welcome to Vendor Management System API"}
