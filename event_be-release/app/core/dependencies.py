from typing import Any, AsyncGenerator

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from core.auth import create_refresh_token, verify_password, create_access_token, decode_access_token
from core.async_database import AsyncSessionLocal
from models.user import User
from models.client import ClientUser
from schemas.auth import Token
from core.auth import oauth2_scheme

# --- FastAPI dependencies ---

async def get_session() -> AsyncGenerator[Any, Any]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

# --- Authenticate & issue JWT ---
async def authenticate_user(email: str, password: str, session: AsyncSession):
    q = select(User).where(User.email == email)
    result = await session.execute(q)
    user = result.scalar_one_or_none()
    if not user or not verify_password(password, user.password_hash):
        return None
    return user


async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: AsyncSession = Depends(get_session)
) -> Token:
    user = await authenticate_user(form_data.username, form_data.password, session)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect email or password")

    payload = {"sub": str(user.user_id), "role_id": user.role_id}
    access_token = create_access_token(payload)
    refresh_token = create_refresh_token(payload)
    return Token(access_token=access_token, refresh_token=refresh_token)

# --- Resolve current user from JWT ---
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: AsyncSession = Depends(get_session)
) -> User:
    try:
        payload = decode_access_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid token payload")

    q = select(User).options(selectinload(User.role)).where(User.user_id == int(user_id))
    result = await session.execute(q)
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return user


# --- Check User.role == 'TO' ---
async def require_TO(user: User = Depends(get_current_user)) -> User:
    if not user.role or user.role.role != 'TO':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Tour Operators can perform this action"
        )
    return user


# --- Determine current client context ---
#    We assume each TO is assigned exactly one approved ClientUser record
async def get_current_client(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session)
):
    q = (
        select(ClientUser)
        .where(
            ClientUser.user_id == user.user_id,
            ClientUser.approval_status == "approved"
        )
    )
    result = await session.execute(q)
    cu = result.scalars().first()
    if not cu:
        raise HTTPException(
            status_code=403,
            detail="You have no approved client association"
        )
    return cu.client_id
