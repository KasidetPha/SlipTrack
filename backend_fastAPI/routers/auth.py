from fastapi import APIRouter, Depends, HTTPException
import aiomysql
import secrets
from datetime import datetime, timedelta

from core.database import get_db_conn
from core.security import create_jwt, hash_password, verify_password
from schemas.models import LoginBody, RegisterBody, ForgotPasswordBody, ResetPasswordBody


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
            
            if not verify_password(body.password, user["password_hash"]):
                raise HTTPException(status_code=401, detail="Invalid password")
            
            token = create_jwt(user_id=user["user_id"], email=user["email"])
            return {"message": "Login success", "token": token}
        
@router.post("/register")
async def register(
    body: RegisterBody,
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:

            await cur.execute(
                "SELECT user_id FROM users WHERE email=%s",
                (body.email,)
            )
            existing_user = await cur.fetchone()

            if existing_user:
                raise HTTPException(status_code=400, detail="Email already exists")

            gemini_api_key = None
            if body.gemini_api_key and body.gemini_api_key.strip() != "":
                gemini_api_key = body.gemini_api_key.strip()

            hashed_password = hash_password(body.password)

            await cur.execute(
                """
                INSERT INTO users (
                    full_name,
                    username,
                    email,
                    password_hash,
                    gemini_api_key
                )
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    body.fullname.strip(),
                    body.email.split("@")[0],
                    body.email.strip(),
                    hashed_password,
                    gemini_api_key,
                )
            )

            new_user_id = cur.lastrowid

            await cur.execute(
                """
                INSERT INTO budget (
                    user_id,
                    warning_enabled,
                    warning_percentage,
                    overspending_enabled
                )
                VALUES (%s, %s, %s, %s)
                """,
                (new_user_id, 1, 80, 1)
            )

            await conn.commit()
            
            return {
                "message": "Register success"
            }
            
@router.post("/forgot-password")
async def forgot_password(
    body: ForgotPasswordBody,
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:

            await cur.execute(
                "SELECT user_id FROM users WHERE email=%s",
                (body.email,)
            )
            user = await cur.fetchone()

            if not user:
                return {"message": "If this email exists, a reset token has been generated"}

            token = secrets.token_urlsafe(32)

            expires_at = datetime.utcnow() + timedelta(minutes=15)

            await cur.execute(
                """
                INSERT INTO password_resets (user_id, reset_token, expires_at)
                VALUES (%s, %s, %s)
                """,
                (user["user_id"], token, expires_at)
            )

            await conn.commit()

            return {
                "message": "Reset token generated",
                "reset_token": token
            }
            
            
@router.post("/reset-password")
async def reset_password(
    body: ResetPasswordBody,
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:

            await cur.execute(
                """
                SELECT * FROM password_resets
                WHERE reset_token=%s
                """,
                (body.token,)
            )
            record = await cur.fetchone()

            if not record:
                raise HTTPException(status_code=400, detail="Invalid token")

            if record["used"]:
                raise HTTPException(status_code=400, detail="Token already used")

            if record["expires_at"] < datetime.utcnow():
                raise HTTPException(status_code=400, detail="Token expired")

            new_hashed = hash_password(body.new_password)

            await cur.execute(
                """
                UPDATE users
                SET password_hash=%s
                WHERE user_id=%s
                """,
                (new_hashed, record["user_id"])
            )

            await cur.execute(
                """
                UPDATE password_resets
                SET used=1
                WHERE reset_id=%s
                """,
                (record["reset_id"],)
            )

            await conn.commit()

            return {"message": "Password reset successful"}