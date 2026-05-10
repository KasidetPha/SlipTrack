from fastapi import APIRouter, Depends, HTTPException, Path
from typing import List
import aiomysql
from datetime import datetime
import asyncio

from core.database import get_db_conn
from core.security import require_auth
from core.config import TZ
from schemas.models import (TokenPayload, FCMTokenBody, NotificationOut, UpdateProfileRequest, UserProfileDetailResponse,)
from services.fcm_service import send_push_notification
from google import genai
from google.genai import types

router = APIRouter(tags=["Users & Notifications"])

def mask_gemini_key(key: str | None):
    if not key:
        return None

    if len(key) <= 8:
        return "****"

    return f"{key[:4]}****{key[-4:]}"

@router.get("/users/profile")
async def get_user_profile(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """ดึงข้อมูลโปรไฟล์และสรุปยอดเงินคงเหลือของผู้ใช้"""
    sql = """
        SELECT 
            u.email, u.username, u.full_name, u.profile_image, u.gemini_api_key,

            (SELECT COALESCE(SUM(amount), 0) 
            FROM income_transactions 
            WHERE user_id = u.user_id) AS total_income,

            (SELECT COALESCE(SUM(ei.total_price), 0)
            FROM expense_transactions et
            JOIN expense_items ei 
            ON et.transaction_id = ei.transaction_id
            WHERE et.user_id = u.user_id) AS total_expense

        FROM users u
        WHERE u.user_id = %s
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id,))
            user_data = await cur.fetchone()
            
            if not user_data:
                raise HTTPException(status_code=404, detail="User not found")

            total_income = float(user_data['total_income'])
            total_expense = float(user_data['total_expense'])
            current_balance = total_income - total_expense
            
            display_name = user_data['full_name'] if user_data['full_name'] else user_data['username']
            

            return {
                "display_name": display_name,
                "email": user_data['email'],
                "balance": current_balance,
                "profile_image": user_data['profile_image'],
                "gemini_api_key": user_data["gemini_api_key"]
            }
            
@router.put("/users/profile", response_model=UserProfileDetailResponse)
async def update_user_profile(
    body: UpdateProfileRequest,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    fullname = body.fullname.strip()

    if not fullname:
        raise HTTPException(status_code=400, detail="Fullname is required")

    gemini_api_key = body.gemini_api_key

    if gemini_api_key is not None:
        gemini_api_key = gemini_api_key.strip()

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                """
                UPDATE users
                SET 
                    full_name = %s,
                    profile_image = %s,
                    gemini_api_key = %s
                WHERE user_id = %s
                """,
                (
                    fullname,
                    body.profile_image,
                    gemini_api_key,
                    auth.id,
                )
            )

            await conn.commit()

            await cur.execute(
                """
                SELECT 
                    user_id,
                    email,
                    username,
                    full_name,
                    profile_image,
                    gemini_api_key
                FROM users
                WHERE user_id = %s
                """,
                (auth.id,)
            )

            user = await cur.fetchone()

            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            return {
                "id": user["user_id"],
                "fullname": user["full_name"] or user["username"],
                "email": user["email"],
                "profile_image": user["profile_image"],
                "has_gemini_api_key": bool(user["gemini_api_key"]),
                "masked_gemini_api_key": mask_gemini_key(user["gemini_api_key"]),
            }
                
# ==========================================
# Profile Detail Token gemini
# ==========================================
    
@router.get("/users/profile/detail", response_model=UserProfileDetailResponse)
async def get_user_profile_detail(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    sql = """
        SELECT 
            user_id,
            email,
            username,
            full_name,
            profile_image,
            gemini_api_key
        FROM users
        WHERE user_id = %s
    """

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id,))
            user = await cur.fetchone()

            if not user:
                raise HTTPException(status_code=404, detail="User not found")

            fullname = user["full_name"] or user["username"]

            return {
                "id": user["user_id"],
                "fullname": fullname,
                "email": user["email"],
                "profile_image": user["profile_image"],
                "has_gemini_api_key": bool(user["gemini_api_key"]),
                "masked_gemini_api_key": mask_gemini_key(user["gemini_api_key"]),
            }

@router.post("/users/fcm-token")
async def update_fcm_token(
    body: FCMTokenBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """อัปเดต FCM Token เวลามีการเข้าแอปใหม่ เพื่อให้ส่งแจ้งเตือนได้ถูกเครื่อง"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor() as cur:
                await conn.begin()
                await cur.execute(
                    """
                    UPDATE users 
                    SET fcm_token = %s, updated_at = NOW() 
                    WHERE user_id = %s
                    """,
                    (body.token, auth.id)
                )
                await conn.commit()
                return {"message": "FCM Token updated successfully"}
        except Exception as e:
            await conn.rollback()
            print(f"Error saving FCM token: {e}")
            raise HTTPException(status_code=500, detail="Failed to save FCM token")

# ==========================================
# Notification Endpoints
# ==========================================

@router.get("/notifications", response_model=List[NotificationOut])
async def get_notifications(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """ดึงประวัติการแจ้งเตือนทั้งหมด 50 รายการล่าสุด"""
    sql = """
        SELECT notification_id, title, body, notification_type, is_read, created_at
        FROM notifications
        WHERE user_id = %s
        ORDER BY created_at DESC
        LIMIT 50
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id,))
            rows = await cur.fetchall()
            
            # แปลงค่า 1/0 เป็น True/False ให้ตรงกับ Pydantic Schema
            for row in rows:
                row['is_read'] = bool(row['is_read'])
                
            return rows

@router.put("/notifications/{id}/read")
async def mark_notification_read(
    id: int = Path(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """กดเปลี่ยนสถานะการแจ้งเตือนว่า 'อ่านแล้ว'"""
    async with db_pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "UPDATE notifications SET is_read = TRUE WHERE notification_id = %s AND user_id = %s",
                (id, auth.id)
            )
            await conn.commit()
            return {"message": "Marked as read"}

@router.get("/notifications/unread-count")
async def get_unread_count(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """นับจำนวนการแจ้งเตือนที่ยังไม่ได้อ่าน (เผื่อเอาไปโชว์ Badge ตัวแดงบนแอป)"""
    sql = """
        SELECT COUNT(*) AS unread_count
        FROM notifications
        WHERE user_id = %s AND is_read = FALSE
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, ))
            row = await cur.fetchone()
            
            count = int(row['unread_count']) if row else 0
            return {"unread_count": count}

@router.post("/debug/test-notification")
async def test_notification(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """ใช้สำหรับกดยิงทดสอบแจ้งเตือนเข้าเครื่องตัวเอง"""
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("SELECT fcm_token FROM users WHERE user_id = %s", (auth.id,))
            user = await cur.fetchone()
            
            if not user or not user.get("fcm_token"):
                raise HTTPException(
                    status_code=404, 
                    detail="ไม่พบ FCM Token ในระบบ กรุณาเปิดแอป Flutter เพื่อรายงานตัวก่อน"
                )
            
            # สั่งทำงานแบบ Background ด้วย asyncio.to_thread เพื่อไม่ให้ API ค้างรอ
            success = await asyncio.to_thread(
                send_push_notification,
                token=user["fcm_token"],
                title="🚀 SlipTrack Test",
                body=f"ยินดีด้วย! ระบบแจ้งเตือนของคุณเชื่อมต่อสำเร็จแล้วเมื่อเวลา {datetime.now(TZ).strftime('%H:%M:%S')}"
            )
            
            if success:
                return {"status": "success", "message": "Notification sent!", "token_used": user["fcm_token"][:15] + "..."}
            else:
                raise HTTPException(status_code=500, detail="ส่งแจ้งเตือนไม่สำเร็จ ตรวจสอบ Server Log")
            
            
# ==========================================
# Check Gemini Token
# ==========================================

@router.post("/users/verify-gemini-token")
async def verify_gemini_token(
    body: dict,
    auth: TokenPayload = Depends(require_auth),
):
    gemini_api_key = body.get("gemini_api_key")

    if not gemini_api_key or gemini_api_key.strip() == "":
        raise HTTPException(status_code=400, detail="Gemini API Key is required")

    print("VERIFY GEMINI BODY:", body)
    print("VERIFY GEMINI KEY:", gemini_api_key[:8] if gemini_api_key else None)
    try:
        client = genai.Client(api_key=gemini_api_key.strip())

        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents="Reply only: OK",
            config=types.GenerateContentConfig(temperature=0.0),
        )

        if response.text and "OK" in response.text.upper():
            return {"valid": True, "message": "Gemini API Key is valid"}

        return {"valid": True, "message": "Gemini API Key works"}

    except Exception as e:
        err = str(e)
        print("VERIFY GEMINI ERROR:", err)

        if "429" in err or "RESOURCE_EXHAUSTED" in err:
            raise HTTPException(
                status_code=429,
                detail="Gemini API Key ถูกต้อง แต่ quota หมดหรือยังไม่มี quota"
            )

        raise HTTPException(
            status_code=400,
            detail="Gemini API Key ใช้งานไม่ได้"
        )