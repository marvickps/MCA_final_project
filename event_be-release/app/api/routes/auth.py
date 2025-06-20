from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from core.auth import create_access_token, create_refresh_token, decode_access_token
from schemas.auth import RefreshTokenRequest, Token
from core.dependencies import login_for_access_token, get_session

router = APIRouter(prefix="/api/auth", tags=["Auth"])

@router.post("/token", response_model=Token)
async def login(
    form_data = Depends(OAuth2PasswordRequestForm),
    session: AsyncSession = Depends(get_session)
):
    return await login_for_access_token(form_data, session)


@router.post("/refresh", response_model=Token)
async def refresh_access_token(
    request: RefreshTokenRequest
):
    try:
        payload = decode_access_token(request.refresh_token)
        user_id = payload.get("sub")
        role_id = payload.get("role_id")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid refresh token")
        
        new_access_token = create_access_token({"sub": user_id, "role_id":role_id})
        new_refresh_token = create_refresh_token({"sub": user_id, "role_id":role_id})  # Optional rotation
        return Token(access_token=new_access_token, refresh_token=new_refresh_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
