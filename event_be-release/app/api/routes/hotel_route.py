# app/api/routes/hotel.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from core.database import get_db
from services import hotel_service

# from app.models import hotel # Import the User model
# from app.schemas import user as user_schema  # Import user schemas

router = APIRouter()
