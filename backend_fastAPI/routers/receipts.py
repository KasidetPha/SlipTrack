from fastapi import APIRouter, Depends, HTTPException, Body, Path, File, UploadFile, BackgroundTasks
from fastapi.responses import StreamingResponse
from typing import List
import aiomysql
from datetime import datetime
import time
import base64
import json
import io
from PIL import Image
from google.genai import types
import asyncio

from core.database import get_db_conn
from core.security import require_auth
from google import genai
from schemas.models import (
    TokenPayload, MonthYear, ReceiptItemOut, MonthYearType,
    UpdateItemBody, CreateIncomeBody, CreateExpenseBody,
    MonthlyComparisionResponse, ScanResponse, ReceiptBatchCreateRequest,
    UpdateIncomeBody, ReceiptItem, BoundingBox, OCRCorrectionRequest
)

from services.ai_service import predict_item_category, auto_assign_category, create_user_gemini_client, build_receipt_prompt, call_gemini_receipt_ocr, is_noise_receipt_item
from services.ocr_service import process_receipt_ocr
from services.budget_notification import check_and_notify_budget
from utils.constants import CATEGORY_MAP

from utils.image_utils import preprocess_receipt_image, optimize_image_for_gemini

router = APIRouter(tags=["Transactions & Receipts"])

@router.post("/receipt_item/categories")
async def top_two_categories(
    body: MonthYear = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    """หน้าแรก (Home): ดึง 2 หมวดหมู่ที่จ่ายเยอะสุด"""
    sql = """
        SELECT 
            c.category_id, 
            c.category_name, 
            c.icon_name, 
            c.color_hex,
            SUM(ei.total_price) AS total_spent
        FROM expense_items ei
        JOIN expense_transactions et ON et.transaction_id = ei.transaction_id
        LEFT JOIN categories c ON c.category_id = ei.category_id
        WHERE 
            et.user_id = %s 
            AND MONTH(et.receipt_date) = %s 
            AND YEAR(et.receipt_date) = %s
        GROUP BY 
            c.category_id, 
            c.category_name, 
            c.icon_name, 
            c.color_hex
        ORDER BY total_spent DESC
        LIMIT 2;
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, body.month, body.year))
            return await cur.fetchall()
            
@router.post("/receipt_item", response_model=List[ReceiptItemOut])
async def recent_transactions(
    body: MonthYear = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    """หน้าแรก (Home): ดึงประวัติรายการล่าสุด (รวมรับและจ่าย)"""

    print("=== /receipt_item ===")
    print("auth.id:", auth.id)
    print("month:", body.month, "year:", body.year)

    sql = """
        (
            SELECT
                ei.item_id AS item_id,
                u.full_name AS full_name,
                ei.total_price AS total_price,
                ei.item_name AS item_name,
                et.receipt_date AS tx_date,
                ei.quantity AS quantity,
                c.category_id AS category_id,
                c.icon_name AS icon_name,
                c.color_hex AS color_hex,
                'expense' AS entry_type,
                et.created_at AS created_at,
                ei.note AS note
            FROM expense_transactions et
            JOIN users u ON u.user_id = et.user_id
            JOIN expense_items ei ON ei.transaction_id = et.transaction_id
            LEFT JOIN categories c ON c.category_id = ei.category_id
            WHERE et.user_id = %s
              AND MONTH(et.receipt_date) = %s
              AND YEAR(et.receipt_date) = %s
        )

        UNION ALL

        (
            SELECT
                it.income_id AS item_id,
                u.full_name AS full_name,
                it.amount AS total_price,
                COALESCE(it.income_source, 'รายรับ') AS item_name,
                it.income_date AS tx_date,
                1 AS quantity,
                c.category_id AS category_id,
                c.icon_name AS icon_name,
                c.color_hex AS color_hex,
                'income' AS entry_type,
                it.created_at AS created_at,
                it.note AS note
            FROM income_transactions it
            LEFT JOIN users u ON u.user_id = it.user_id
            LEFT JOIN categories c ON c.category_id = it.category_id
            WHERE it.user_id = %s
              AND MONTH(it.income_date) = %s
              AND YEAR(it.income_date) = %s
        )

        ORDER BY tx_date DESC, created_at DESC
    """

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:

            # 🔍 DEBUG DB
            await cur.execute("SELECT DATABASE() AS db_name")
            db_info = await cur.fetchone()
            print("DB:", db_info)

            # 🔍 DEBUG QUERY PARAM
            print("QUERY PARAM:", auth.id, body.month, body.year)

            await cur.execute(
                sql,
                (auth.id, body.month, body.year, auth.id, body.month, body.year)
            )

            rows = await cur.fetchall()

            print("RESULT COUNT:", len(rows))
            print("receipt_item rows:", rows)

            return rows

@router.post("/monthlyTotal")
async def monthly_total(
    body: MonthYearType,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    """ดึงยอดรวมรายเดือน แบบสุทธิ(Net), รายรับ(Income) หรือ รายจ่าย(Expense)"""
    month, year, t = body.month, body.year, (body.type or "net").lower()
    
    sql = """
        SELECT
            (
                SELECT COALESCE(SUM(it.amount), 0)
                FROM income_transactions it
                WHERE it.user_id = %s
                AND MONTH(it.income_date) = %s
                AND YEAR(it.income_date) = %s
            ) AS income_total_amount,

            (
                SELECT COALESCE(SUM(ei.total_price), 0)
                FROM expense_transactions et
                JOIN expense_items ei ON ei.transaction_id = et.transaction_id
                WHERE et.user_id = %s
                AND MONTH(et.receipt_date) = %s
                AND YEAR(et.receipt_date) = %s
            ) AS expense_total_amount
        """
        
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, month, year, auth.id, month, year))
            row = await cur.fetchone()
            
    income_total = float(row.get("income_total_amount", 0)) if row else 0.0
    expense_total = float(row.get("expense_total_amount", 0)) if row else 0.0
    net_total = income_total - expense_total

    if t == "income":
        amount = income_total
    elif t == "expense":
        amount = expense_total
    else:
        t = "net"
        amount = net_total

    return {
        "month": month,
        "year": year,
        "amount": float(amount),
        "type": t,
        "breakdown": {
            "income_total_amount": income_total,
            "expense_total_amount": expense_total,
            "net_total": net_total,
        },
    }

@router.post("/incomes")
async def create_income(
    body: CreateIncomeBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """บันทึกรายรับใหม่ (ระบุหมวดหมู่เอง ไม่ใช้ AI)"""
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()
                
                target_category_name = body.category_name.strip()
                
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s AND category_type = 'INCOME' AND (user_id = %s OR is_default = 1) LIMIT 1
                    """, (target_category_name, auth.id)
                )
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code=400, detail=f"Category '{target_category_name}' not found")
                
                category_id = cat_row["category_id"]
                
                await cur.execute(
                    """
                    INSERT INTO income_transactions
                    (user_id, category_id, amount, income_date, income_source, note, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, NOW())
                    """, (auth.id, category_id, body.amount, body.date, body.source, body.note)
                )
                
                await conn.commit()
                return {"message": "Income created successfully"}
                
            except HTTPException:
                await conn.rollback()
                raise
            except Exception as e:
                await conn.rollback()
                print(f"Error creating income: {e}") 
                raise HTTPException(status_code=500, detail="Failed to create income")
            
@router.post('/expenses')
async def create_expense(
    body: CreateExpenseBody,
    background_tasks: BackgroundTasks,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """บันทึกรายจ่ายใหม่แบบ Manual (กรอกเอง) พร้อมเช็กแจ้งเตือนงบ"""
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()

                target_category_name = body.category_name

                if target_category_name.lower() == "auto":
                    await cur.execute(
                        "SELECT gemini_api_key FROM users WHERE user_id=%s",
                        (auth.id,)
                    )
                    user_row = await cur.fetchone()

                    if not user_row or not user_row["gemini_api_key"]:
                        raise HTTPException(
                            status_code=403,
                            detail="โปรดเพิ่ม Gemini API Key ในหน้า Profile ก่อนใช้งาน AI"
                        )

                    prediction = await predict_item_category(
                        body.item_name,
                        None,
                        gemini_api_key=user_row["gemini_api_key"]
                    )
                    target_category_name = prediction["category_name"]
                    
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s AND category_type = 'EXPENSE' AND (user_id = %s OR is_default = 1) LIMIT 1
                    """, (target_category_name, auth.id)
                )
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code=400, detail=f"Category '{target_category_name}' not found")
                
                category_id = cat_row["category_id"]
                
                await cur.execute(
                    """
                    INSERT INTO expense_transactions
                    (user_id, store_name, receipt_date, total_amount, source, note, created_at)
                    VALUEs (%s, %s, %s, %s, 'manual', %s, NOW())
                    """, (auth.id, body.store_name, body.date, body.amount, body.note)
                )
                transaction_id = cur.lastrowid
                
                await cur.execute(
                    """
                    INSERT INTO expense_items
                    (transaction_id, category_id, item_name, quantity, unit_price, total_price, note)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (transaction_id, category_id, body.item_name, 1, body.amount, body.amount, body.note)
                )
                
                await conn.commit()
                
                # โยน Task ไปเช็กว่ายอดทะลุงบที่ตั้งไว้ไหม เพื่อส่ง Push Notification แบบ Background
                background_tasks.add_task(check_and_notify_budget, auth.id, category_id, body.date.month, body.date.year, db_pool)
                
                return {"message": "Expense created successfully", "receipt": transaction_id}
            except HTTPException:
                await conn.rollback()
                raise
            except Exception as e:
                await conn.rollback()
                raise HTTPException(status_code=500, detail=f"Failed to create expense: {str(e)}")
            
@router.get("/predict-category")
async def get_predicted_category(
    item_name: str = "",
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """Endpoint สำหรับ Frontend ส่งรายชื่อมาถามรายการหมวดหมู่"""
    if not item_name or item_name.strip() == "":
        return {"category_name": "Others"}
    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            sql = """
                    SELECT category_name FROM categories
                    WHERE category_type = "EXPENSE" AND (user_id = %s OR is_default = 1)
                """
            await cur.execute(sql, (auth.id, ))
            print(sql, (auth.id, ))
            rows = await cur.fetchall()
            user_categories = [r['category_name'] for r in rows] if rows else ['Others']
            
            # 🔥 เช็ก Gemini key
            await cur.execute(
                "SELECT gemini_api_key FROM users WHERE user_id=%s",
                (auth.id,)
            )
            user_row = await cur.fetchone()

            if not user_row or not user_row["gemini_api_key"]:
                raise HTTPException(
                    status_code=403,
                    detail="โปรดเพิ่ม Gemini API Key ก่อนใช้ AI"
                )

            gemini_api_key = user_row["gemini_api_key"]
            
            try:
                prediction = await predict_item_category(
                                item_name,
                                user_categories,
                                gemini_api_key=gemini_api_key
                            )
                return {
                    "category_name": prediction.get('category_name', 'Others'), # ให้เหลือแค่ String
                    "all_categories_debug": user_categories # แยก List มาไว้อีก Key แทน
                }
            except Exception as e:
                print(f"Prediction Error: {e}")
                return {"category_name": "Others"}
    
@router.put("/receipt_item/{id}")
async def update_receipt_item(
    id: int = Path(..., ge=1),
    body: UpdateItemBody = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """แก้ไขรายการใช้จ่ายย่อย"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                await cur.execute(
                    """                 
                    SELECT ei.item_id, et.transaction_id AS tid
                    FROM expense_items ei
                    JOIN expense_transactions et ON et.transaction_id = ei.transaction_id
                    WHERE ei.item_id = %s
                    """, (id,)
                )
                owner = await cur.fetchone()
                if not owner:
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail="Item not found")
                
                await cur.execute(
                    """
                    UPDATE expense_items
                    SET item_name=%s, quantity=%s, total_price=%s, category_id=%s, note=%s
                    WHERE item_id=%s
                    """, (body.item_name, body.quantity, body.total_price, body.category_id, body.note, id)
                )
                
                await cur.execute(
                    """
                    UPDATE expense_transactions 
                    SET receipt_date = COALESCE(%s, receipt_date), note = %s 
                    WHERE transaction_id = %s
                    """, (body.receipt_date, body.note, owner["tid"])
                )
                
                await conn.commit()
                return {"ok": True}
        except Exception as e:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=f"Server error: {e}")

@router.put("/incomes/{id}")
async def update_income(
    id: int = Path(..., ge=1),
    body: UpdateIncomeBody = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """แก้ไขรายการรับเงิน"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                await cur.execute("SELECT income_id FROM income_transactions WHERE income_id = %s AND user_id = %s", (id, auth.id))
                if not await cur.fetchone():
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail="Income not found or unauthorized")
                
                await cur.execute(
                    """
                    UPDATE income_transactions
                    SET income_source=%s, amount=%s, category_id=%s, income_date=%s, note=%s
                    WHERE income_id=%s AND user_id=%s
                    """, (body.income_source, body.amount, body.category_id, body.income_date, body.note, id, auth.id)
                )
                await conn.commit()
                return {"message": "Income updated successfully", "income_id": id}
        except Exception as e:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=f"Internal server error: {e}")
        

@router.post("/scan-receipt", response_model=ScanResponse)
async def scan_receipt(
    file: UploadFile = File(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    return await process_receipt_ocr(
        file=file,
        auth=auth,
        db_pool=db_pool
    )
    
from difflib import SequenceMatcher
    
def extract_changed_part(old: str, new: str):
    old = old.strip()
    new = new.strip()

    if old == new:
        return None

    old_words = old.split()
    new_words = new.split()

    matcher = SequenceMatcher(None, old_words, new_words)

    wrong_parts = []
    correct_parts = []

    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag in ("replace", "delete"):
            wrong_parts.extend(old_words[i1:i2])

        if tag in ("replace", "insert"):
            correct_parts.extend(new_words[j1:j2])

    wrong = " ".join(wrong_parts).strip()
    correct = " ".join(correct_parts).strip()

    if len(wrong) >= 2 and len(correct) >= 2:
        return wrong, correct

    return old, new
        
@router.post("/ocr-correction")
async def add_correction(
    body: OCRCorrectionRequest,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    wrong = body.wrong_text.strip()
    correct = body.correct_text.strip()

    if not wrong or not correct:
        raise HTTPException(status_code=400, detail="wrong_text and correct_text are required")

    if wrong == correct:
        return {"status": "skip", "message": "No correction needed"}

    result = extract_changed_part(wrong, correct)

    if result is None:
        return {"status": "skip", "message": "No correction needed"}

    wrong, correct = result

    async with db_pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                """
                INSERT INTO ocr_corrections (wrong_text, correct_text, use_count)
                VALUES (%s, %s, 0)
                ON DUPLICATE KEY UPDATE
                    correct_text = VALUES(correct_text),
                    updated_at = CURRENT_TIMESTAMP
                """,
                (wrong, correct),
            )

            await conn.commit()

    return {
        "status": "ok",
        "wrong_text": wrong,
        "correct_text": correct,
    }
    
@router.post("/receipts/batch")
async def create_receipt_batch(
    body: ReceiptBatchCreateRequest,
    background_tasks: BackgroundTasks,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """บันทึกข้อมูลใบเสร็จที่สแกนมาแบบรวดเดียว (Batch)"""
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()
                
                # 1. สร้าง Transaction หลักก่อน
                sql_tx = """
                    INSERT INTO expense_transactions
                    (user_id, store_name, receipt_date, total_amount, source, created_at)
                    VALUES (%s, %s, %s, %s, 'ocr', NOW())
                """
                # หมายเหตุ: ปรับชื่อฟิลด์ body.merchant_name, body.receipt_date ให้ตรงกับ Schema ของคุณ
                await cur.execute(sql_tx, (
                    auth.id, 
                    body.merchant_name, 
                    body.receipt_date, 
                    body.total_amount
                ))
                transaction_id = cur.lastrowid
                
                # 2. นำ Items ทั้งหมดมา Insert ทีละรายการ
                if body.items and len(body.items) > 0:
                    sql_items = """
                        INSERT INTO expense_items
                        (transaction_id, category_id, item_name, quantity, unit_price, total_price, note)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """
                    # เตรียมข้อมูล Items เข้า List of Tuples เพื่อทำ executemany
                    item_values = [
                        (
                            transaction_id,
                            item.category_id,
                            item.item_name,
                            item.quantity,
                            
                            item.total_price / item.quantity if item.quantity > 0 else item.total_price, 
                            
                            item.total_price,
                            ""
                        ) for item in body.items
                    ]
                    
                    await cur.executemany(sql_items, item_values)
                
                await conn.commit()

                checked_category_ids = set()

                for item in body.items:
                    checked_category_ids.add(item.category_id)

                for category_id in checked_category_ids:
                    background_tasks.add_task(
                        check_and_notify_budget,
                        auth.id,
                        category_id,
                        body.receipt_date.month,
                        body.receipt_date.year,
                        db_pool
                    )

                return {"message": "Receipt batch saved successfully", "transaction_id": transaction_id}                
            
            except Exception as e:
                await conn.rollback()
                print(f"Batch Insert Error: {e}")
                raise HTTPException(status_code=500, detail=f"Failed to save batch: {str(e)}")
            
@router.delete("/items/expense/{item_id}") # เปลี่ยนจาก transaction_id เป็น item_id
async def delete_expense(
    item_id: int = Path(..., ge=1),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor() as cur:
            try:
                await conn.begin()
                
                await cur.execute("SELECT transaction_id FROM expense_items WHERE item_id = %s", (item_id,))
                row = await cur.fetchone()
                
                if not row:
                    raise HTTPException(status_code=404, detail="ไม่พบรายการที่ต้องการลบ")
                
                tid = row[0]

                await cur.execute("DELETE FROM expense_items WHERE item_id = %s", (item_id,))
                
                await cur.execute(
                    "SELECT COUNT(*) FROM expense_items WHERE transaction_id = %s",
                    (tid,)
                )
                count = (await cur.fetchone())[0]

                if count == 0:
                    await cur.execute(
                        "DELETE FROM expense_transactions WHERE transaction_id = %s AND user_id = %s",
                        (tid, auth.id)
                    )
                
                await conn.commit()
                return {"status": "success", "message": "ลบข้อมูลรายจ่ายเรียบร้อย"}
            except Exception as e:
                await conn.rollback()
                raise HTTPException(status_code=500, detail=str(e))
                
@router.delete("/items/income/{income_id}")
async def delete_income(
    income_id: int = Path(..., ge=1),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor() as cur:
            try:
                await conn.begin()
                
                # ลบรายรับ โดยเช็ก user_id เพื่อความปลอดภัย
                await cur.execute(
                    "DELETE FROM income_transactions WHERE income_id = %s AND user_id = %s", 
                    (income_id, auth.id)
                )
                
                await conn.commit()
                return {"status": "success", "message": "ลบข้อมูลรายรับเรียบร้อย"}
            except Exception as e:
                await conn.rollback()
                raise HTTPException(status_code=500, detail=str(e))