from fastapi import APIRouter, Depends, HTTPException, Query, Body
from typing import List
import aiomysql

from core.database import get_db_conn
from core.security import require_auth
from schemas.models import (
    TokenPayload, BudgetGetResponse, BudgetUpdateRequest, BudgetCategoryItemOut
)

router = APIRouter(prefix="/budgets", tags=["Budgets"])

async def _get_budget_data(
    db_pool: aiomysql.Pool,
    user_id: int,
    month: int,
    year: int,
) -> dict:
    """
    ฟังก์ชันผู้ช่วยสำหรับดึงข้อมูลการตั้งค่างบประมาณและการแจ้งเตือน
    เอาไว้เรียกใช้ตอน Get ข้อมูล หรือเรียกใช้ซ้ำหลังจากกด Update ไปแล้ว
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            # 1. ดึงการตั้งค่าการแจ้งเตือนจากตาราง budget
            await cur.execute(
                """
                SELECT warning_enabled, warning_percentage, overspending_enabled
                FROM budget
                WHERE user_id = %s
                """, (user_id,)
            )
            setting = await cur.fetchone()
            
            if setting:
                warning_enabled = bool(setting["warning_enabled"])
                warning_percentage = int(setting['warning_percentage'])
                overspending_enabled = bool(setting["overspending_enabled"])
            else:
                # ค่าเริ่มต้นถ้าผู้ใช้ยังไม่เคยตั้งค่า
                warning_enabled = False
                warning_percentage = 80
                overspending_enabled = True
                
            # 2. ดึงหมวดหมู่รายจ่ายทั้งหมด และ Join กับเป้าหมายงบประมาณ (ถ้ามี)
            await cur.execute(
                """
                SELECT
                    c.category_id, c.category_name, c.icon_name, c.color_hex,
                    COALESCE(eb.amount, 0) AS limit_amount
                FROM categories c
                LEFT JOIN expense_budgets eb
                    ON eb.category_id = c.category_id
                    AND eb.user_id = %s
                    AND eb.year = %s
                    AND eb.month = %s
                WHERE (c.user_id = %s OR c.is_default = 1)
                    AND c.category_type = 'EXPENSE'
                ORDER BY c.category_name ASC
                """,
                (user_id, year, month, user_id),
            )
            rows = await cur.fetchall()
            
    items: List[BudgetCategoryItemOut] = []
    for r in rows:
        items.append(
            BudgetCategoryItemOut(
                category_id=r["category_id"],
                category_name=r["category_name"],
                icon_name=r.get("icon_name"),
                color_hex=r.get("color_hex"),
                limit_amount=float(r["limit_amount"] or 0)
            )
        )
        
    return {
        "month": month,
        "year": year,
        "warning_enabled": warning_enabled,
        "warning_percentage": warning_percentage,
        "overspending_enabled": overspending_enabled,
        "items": items,
    }

@router.get("", response_model=BudgetGetResponse)
async def get_budgets(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=2000, le=2100),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """หน้าตั้งค่างบประมาณ: ดึงข้อมูลยอดที่ตั้งไว้ของเดือน/ปีนั้นๆ"""
    data = await _get_budget_data(db_pool, auth.id, month, year)
    return data

@router.put("", response_model=BudgetGetResponse)
async def update_budgets(
    payload: BudgetUpdateRequest = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    """กดบันทึกหน้าตั้งค่างบประมาณ: บันทึกทั้งแจ้งเตือนและยอดของแต่ละหมวด"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                # 1. อัปเดตการตั้งค่าในตาราง budget
                await cur.execute(
                    """
                    INSERT INTO budget
                        (user_id, warning_enabled, warning_percentage, overspending_enabled, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, NOW(), NOW())
                    ON DUPLICATE KEY UPDATE
                        warning_enabled = VALUES(warning_enabled),
                        warning_percentage = VALUES(warning_percentage),
                        overspending_enabled = VALUES(overspending_enabled),
                        updated_at = NOW()
                    """,
                    (
                        auth.id,
                        1 if payload.warning_enabled else 0,
                        payload.warning_percentage,
                        1 if payload.overspending_enabled else 0,
                    )
                )
                
                # 2. อัปเดตเป้าหมายในตาราง expense_budgets
                for item in payload.items:
                    await cur.execute(
                        """
                        INSERT INTO expense_budgets
                            (user_id, category_id, year, month, amount, created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
                        ON DUPLICATE KEY UPDATE
                            amount = VALUES(amount),
                            updated_at = NOW()
                        """,
                        (auth.id, item.category_id, payload.year, payload.month, float(item.limit_amount))
                    )
                await conn.commit()
                
        except Exception as e:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=f"Failed to update budgets: {e}")
            
    # ดึงข้อมูลที่เพิ่งอัปเดตกลับไปให้ Frontend ทันที
    data = await _get_budget_data(db_pool, auth.id, payload.month, payload.year)
    return data