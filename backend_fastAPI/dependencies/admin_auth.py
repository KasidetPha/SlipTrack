from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import aiomysql
import jwt

from core.config import JWT_SECRET, JWT_ALGORITHM
from core.database import get_db_conn

bearer = HTTPBearer(auto_error=False)


async def require_admin(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No token provided"
        )

    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM]
        )

        user_id = payload.get("id")

        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or expired token"
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or expired token"
        )

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                """
                SELECT user_id, email, role, status
                FROM users
                WHERE user_id = %s
                """,
                (user_id,)
            )
            user = await cur.fetchone()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin only")

    if user["status"] != "active":
        raise HTTPException(status_code=403, detail="Admin account inactive")

    return user