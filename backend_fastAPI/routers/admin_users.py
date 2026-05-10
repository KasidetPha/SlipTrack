from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
import aiomysql
import bcrypt

from core.database import get_db_conn
from dependencies.admin_auth import require_admin

router = APIRouter(
    prefix="/admin/admins",
    tags=["Admin Users"]
)


class CreateAdminRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    status: str = "active"


class UpdateAdminStatusRequest(BaseModel):
    status: str


@router.get("")
async def get_admins(
    admin=Depends(require_admin),
    db=Depends(get_db_conn)
):
    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("""
                SELECT
                    user_id AS id,
                    email,
                    username,
                    full_name,
                    role,
                    status,
                    profile_image,
                    created_at,
                    updated_at
                FROM users
                WHERE role = 'admin'
                ORDER BY created_at DESC
            """)
            admins = await cur.fetchall()

    return {
        "admins": admins
    }


@router.post("")
async def create_admin(
    payload: CreateAdminRequest,
    admin=Depends(require_admin),
    db=Depends(get_db_conn)
):
    if payload.status not in ["active", "inactive"]:
        raise HTTPException(status_code=400, detail="Invalid status")

    if len(payload.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("""
                SELECT user_id
                FROM users
                WHERE email = %s
                LIMIT 1
            """, (payload.email,))
            existing = await cur.fetchone()

            if existing:
                raise HTTPException(status_code=400, detail="Email already exists")

            await cur.execute("""
                INSERT INTO users (
                    email,
                    username,
                    password_hash,
                    full_name,
                    role,
                    status,
                    created_at,
                    updated_at
                )
                VALUES (%s, %s, SHA2(%s, 256), %s, 'admin', %s, NOW(), NOW())
            """, (
                payload.email,
                payload.email.split("@")[0],
                payload.password,
                payload.full_name,
                payload.status
            ))

            await conn.commit()

    return {
        "message": "Admin created successfully"
    }


@router.patch("/{admin_id}/status")
async def update_admin_status(
    admin_id: int,
    payload: UpdateAdminStatusRequest,
    current_admin=Depends(require_admin),
    db=Depends(get_db_conn)
):
    if payload.status not in ["active", "inactive"]:
        raise HTTPException(status_code=400, detail="Invalid status")

    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("""
                SELECT user_id, role
                FROM users
                WHERE user_id = %s AND role = 'admin'
            """, (admin_id,))
            target_admin = await cur.fetchone()

            if not target_admin:
                raise HTTPException(status_code=404, detail="Admin not found")

            await cur.execute("""
                UPDATE users
                SET status = %s, updated_at = NOW()
                WHERE user_id = %s AND role = 'admin'
            """, (payload.status, admin_id))

            await conn.commit()

    return {
        "message": "Admin status updated successfully"
    }


@router.delete("/{admin_id}")
async def delete_admin(
    admin_id: int,
    current_admin=Depends(require_admin),
    db=Depends(get_db_conn)
):
    if int(current_admin["user_id"]) == int(admin_id):
        raise HTTPException(
            status_code=400,
            detail="You cannot delete your own admin account"
        )

    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("""
                SELECT user_id, role
                FROM users
                WHERE user_id = %s AND role = 'admin'
            """, (admin_id,))
            target_admin = await cur.fetchone()

            if not target_admin:
                raise HTTPException(status_code=404, detail="Admin not found")

            await cur.execute("""
                DELETE FROM users
                WHERE user_id = %s AND role = 'admin'
            """, (admin_id,))

            await conn.commit()

    return {
        "message": "Admin deleted successfully"
    }