import os, time
import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

SECRET = os.getenv("JWT_SECRET", "dev-only-change-me")
bearer = HTTPBearer()

def create_token(user_id: str) -> str:
    return jwt.encode({"sub": user_id, "exp": int(time.time()) + 86400}, SECRET, algorithm="HS256")


def current_user_id(cred: HTTPAuthorizationCredentials = Depends(bearer)) -> str:
    try:
        return jwt.decode(cred.credentials, SECRET, algorithms=["HS256"])["sub"]
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="انتهت الجلسة")