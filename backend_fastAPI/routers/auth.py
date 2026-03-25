from fastapi import APIRouter, Depends, HTTPException
import aiomysql

from core.database import get_db_conn
from core.security import create_jwt
from schemas.models import LoginBody

router = APIRouter(tags=["Authentication"])

@router.post("/login")
async def login(body: LoginBody, db_pool: aiomysql.Pool = Depends(get_db_conn)):
    """
    API สำหรับให้ผู้ใช้ Login เข้าสู่ระบบ และรับ JWT Token กลับไป
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            # หา user
            await cur.execute("SELECT * FROM users WHERE email=%s", (body.email,))
            user = await cur.fetchone()
            
            if not user:
                raise HTTPException(status_code=400, detail="User not found")
            
            # ตรวจรหัสแบบ SHA2
            await cur.execute(
                "SELECT * FROM users WHERE email=%s AND password_hash=SHA2(%s, 256)",
                (body.email, body.password),
            )
            check = await cur.fetchone()
            
            if not check:
                raise HTTPException(status_code=401, detail="Invalid password")
            
            token = create_jwt(user_id=user["user_id"], email=user["email"])
            return {"message": "Login success", "token": token}