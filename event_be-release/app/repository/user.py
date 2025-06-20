from sqlalchemy.orm import Session
from models.user import User

def update_user_role(db: Session, user_id: int, new_role_id: int):
    user = db.query(User).filter(User.user_id == user_id).first()
    if user:
        user.role_id = new_role_id
        db.commit()
        db.refresh(user)
    return user

def fetch_by_user_id(db: Session, user_id: int):
    return db.query(User).filter(User.user_id == user_id).first()

def fetch_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def fetch_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()