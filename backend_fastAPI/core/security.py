import jwt
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from core.config import JWT_SECRET, JWT_EXPIRE_HOURS, JWT_ALGORITHM, TZ

# Import schema (จะสร้างใน Step 2)
from schemas.models import TokenPayload

bearer = HTTPBearer(auto_error=False)

def create_jwt(user_id: int, email: str) -> str:
    exp = datetime.now(tz=TZ) + timedelta(hours=JWT_EXPIRE_HOURS)
    payload = {"id": user_id, "email": email, "exp": int(exp.timestamp())}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

async def require_auth(
    credentials: HTTPAuthorizationCredentials = Depends(bearer)
) -> TokenPayload:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="No token provided")
    
    token = credentials.credentials
    try:
        data = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return TokenPayload(**data)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Invalid or expired token")
    except Exception:
        raise HTTPException(status_code=403, detail="Invalid or expired token")