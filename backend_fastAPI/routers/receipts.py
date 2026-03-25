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

from core.database import get_db_conn
from core.security import require_auth
from core.config import gemini_client
from schemas.models import (
    TokenPayload, MonthYear, ReceiptItemOut, MonthYearType,
    UpdateItemBody, CreateIncomeBody, CreateExpenseBody,
    MonthlyComparisionResponse, ScanResponse, ReceiptBatchCreateRequest,
    UpdateIncomeBody, ReceiptItem, BoundingBox
)

# นำเข้า Services และ Utils 
from services.ai_service import predict_income_category, predict_item_category, auto_assign_category
from services.fcm_service import check_and_notify_budget
from utils.constants import CATEGORY_MAP

# สมมติว่าคุณย้าย image_utils ไปไว้ใน utils/ แล้วตามโครงสร้างใหม่
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
            c.category_id, c.category_name, c.icon_name, c.color_hex,
            SUM(ei.total_price) AS total_spent
        FROM expense_items ei
        LEFT JOIN categories c ON c.category_id = ei.category_id
        LEFT JOIN expense_transactions et ON et.transaction_id = ei.transaction_id
        WHERE et.user_id = %s AND MONTH(et.receipt_date) = %s AND YEAR(et.receipt_date) = %s
        GROUP BY c.category_id, c.category_name, c.icon_name, c.color_hex
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
    sql = """
        (
            SELECT
                ei.item_id AS item_id, u.full_name AS full_name, ei.total_price AS total_price,
                ei.item_name AS item_name, et.receipt_date AS tx_date, ei.quantity AS quantity,
                c.category_id AS category_id, c.icon_name AS icon_name, c.color_hex AS color_hex,
                'expense' AS entry_type, et.created_at AS created_at, ei.note AS note
            FROM expense_transactions et
            JOIN users u ON u.user_id = et.user_id
            JOIN expense_items ei ON ei.transaction_id = et.transaction_id
            JOIN categories c ON c.category_id = ei.category_id
            WHERE et.user_id = %s AND MONTH(et.receipt_date) = %s AND YEAR(et.receipt_date) = %s
        )
        UNION ALL
        (
            SELECT
                it.income_id AS item_id, u.full_name AS full_name, it.amount AS total_price,
                COALESCE(it.income_source, c.category_id, 'รายรับ') AS item_name,
                it.income_date AS tx_date, 1 AS quantity,
                c.category_id AS category_id, c.icon_name AS icon_name, c.color_hex AS color_hex,
                'income' AS entry_type, it.created_at AS created_at, it.note AS note
            FROM income_transactions it
            LEFT JOIN users u ON u.user_id = it.user_id
            LEFT JOIN categories c ON c.category_id = it.category_id
            WHERE it.user_id = %s AND MONTH(it.income_date) = %s AND YEAR(it.income_date) = %s
        )
        ORDER BY tx_date DESC, created_at DESC
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, body.month, body.year, auth.id, body.month, body.year))
            return await cur.fetchall()

@router.post("/monthlyTotal")
async def monthly_total(
    body: MonthYearType,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    """ดึงยอดรวมรายเดือน แบบสุทธิ(Net), รายรับ(Income) หรือ รายจ่าย(Expense)"""
    month, year, t = body.month, body.year, (body.type or "net")
    
    sql = """
        SELECT
        (SELECT COALESCE(SUM(it.amount), 0) FROM income_transactions it
         WHERE it.user_id = %s AND MONTH(it.income_date) = %s AND YEAR(it.income_date) = %s) AS income_total_amount,
        (SELECT COALESCE(SUM(et.total_amount), 0) FROM expense_transactions et
         WHERE et.user_id = %s AND MONTH(et.receipt_date) = %s AND YEAR(et.receipt_date) = %s) AS expense_total_amount;
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, month, year, auth.id, month, year))
            row = await cur.fetchone()
            
    income_total = float(row.get("income_total_amount", 0)) if row else 0.0
    expense_total = float(row.get("expense_total_amount", 0)) if row else 0.0
    net_total = income_total - expense_total
    
    amount = net_total
    if t == "income": amount = income_total
    elif t == "expense": amount = expense_total
        
    return {
        "month": month, "year": year, "amount": float(amount), "type": t,
        "breakdown": {"income_total_amount": income_total, "expense_total_amount": expense_total, "net_total": net_total}
    }

@router.post("/incomes")
async def create_income(
    body: CreateIncomeBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """บันทึกรายรับใหม่"""
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()
                target_category_name = body.category_name.strip()
                
                # ถ้าแอปส่งมาเป็น auto ให้ AI ช่วยจัดการ
                if target_category_name.lower() == 'auto':
                    prediction = await predict_income_category(body.source)
                    target_category_name = prediction["category_name"]
                    
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s AND category_type = 'INCOME' AND (user_id = %s OR is_default = 1) LIMIT 1
                    """, (target_category_name, auth.id)
                )
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code=400, detail=f"Category {target_category_name} not found")
                
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
            except Exception as e:
                await conn.rollback()
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
                    prediction = await predict_item_category(body.item_name)
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
            except Exception as e:
                await conn.rollback()
                raise HTTPException(status_code=500, detail=f"Failed to create expense: {str(e)}")

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
    transaction_id = None
    api_duration_ms = None
    engine_name = "gemini-2.5-flash"
    
    try:
        start_time = time.time()
        
        image_bytes = await file.read()
        
        print("Optimizing image...")
        optimized_bytes, img_width, img_height = optimize_image_for_gemini(image_bytes, max_size=1500)
        
        processd_b64 = base64.b64encode(optimized_bytes).decode('utf-8')
        img_for_gemini = Image.open(io.BytesIO(optimized_bytes))
        
        print(f"Image ready in {time.time() - start_time:.2f} seconds.")
        
        allowed_cats = ", ".join([f'"{k}"' for k in CATEGORY_MAP.keys()])
        
        # --- 1. ตัดคำสั่ง Bounding Box ออกจาก Prompt ---
        # นำ Prompt นี้ไปแทนที่ Prompt เดิม
        prompt = f"""
            You are a specialized Thai OCR API for retail receipts. You MUST extract data into a strict JSON format.

            ### CRITICAL EXTRACTION RULES:
            1. THAI LANGUAGE ACCURACY: Pay close attention to Thai characters, vowels, and tone marks. Read EXACTLY what is printed. DO NOT autocorrect or guess words if they are cut off.
            2. MULTI-LINE STRUCTURE: A single item often spans 2 or 3 lines (Name -> Barcode/Qty -> Total Price). You MUST combine these into ONE item object. The `name` MUST be extracted from Line 1.
            3. MERCHANT IDENTIFICATION: Identify the store name at the very top of the receipt.
            4. DISCOUNTS: Promotional lines (e.g., "ส่วนลด", "ท้ายบิล") are NOT items. Aggregate them into the `discount` field. Do not include discounts in the items array.
            5. IGNORE NOISE: Ignore phone numbers, tax IDs, points, and membership details.

            ### OUTPUT STRUCTURE:
            {{
              "merchant_name": "string (Store Name)",
              "receipt_date": "YYYY-MM-DD",
              "subtotal": float,
              "discount": float,
              "total_amount": float,
              "items": [
                {{
                  "name": "Exact printed text from the receipt (Thai/English)",
                  "unit_price": float,
                  "qty": int,
                  "total_item_price": float,
                  "category": "Must be one of: [{allowed_cats}]"
                }}
              ]
            }}

            Go. Extract the data now. 
            CRITICAL: Return ONLY the raw JSON. Do not write any markdown code blocks (e.g., ```json). Do not write any explanations.
        """
                
        max_retries = 3
        raw_response = ""
        
        for attempt in range(max_retries):
            try:
                print(f"Sending image to Gemini (Attempt {attempt + 1}/{max_retries})...")
                
                api_start_time = time.time()
                
                response = gemini_client.models.generate_content(
                    model=engine_name,
                    contents=[prompt, img_for_gemini],
                    config=types.GenerateContentConfig(
                        temperature=0.0,
                        response_mime_type="application/json"
                    )
                )
                
                api_end_time = time.time()
                
                api_duration_ms = int((api_end_time - api_start_time) * 1000)
                
                print(f"Gemini API Time (): {api_end_time - api_start_time:.2f} วินาที")
                
                raw_response = response.text.strip()
                break
                
            except Exception as api_err:
                err_str = str(api_err)
                if "503" in err_str or "UNAVAILABLE" in err_str.upper():
                    print(f"Gemini API overloaded. Retrying in 2 seconds...")
                    if attempt < max_retries - 1:
                        await asyncio.sleep(2)
                        continue
                    else:
                        raise HTTPException(status_code=503, detail="ระบบ AI ขัดข้องชั่วคราวเนื่องจากผู้ใช้งานหนาแน่น")
                else:
                    raise HTTPException(status_code=500, detail=f"Gemini API Error: {err_str}")

        if raw_response.startswith("```json"):
            raw_response = raw_response[7:-3]
        elif raw_response.startswith("```"):
            raw_response = raw_response[3:-3]
            
        try:
            ai_data = json.loads(raw_response)
        except json.JSONDecodeError:
            raise HTTPException(status_code=500, detail="รูปแบบข้อมูลที่ได้รับจาก AI ไม่ถูกต้อง")
        
        fallback_date = ai_data.get("receipt_date", datetime.now().strftime("%Y-%m-%d"))
        merchant_name = ai_data.get("merchant_name", "Unknown Store")
        total_amount = float(ai_data.get("total_amount", 0.0))
        
        final_items = []
        item_db_values = []
        
        for it in ai_data.get("items", []):
            item_name = it.get("name", "Unknown")
            ai_suggested_cat = it.get("category", "Others")
            unit_price = float(it.get("unit_price", 0.0))
            qty = int(it.get("qty", 1))
            total_item_price = float(it.get("total_item_price", unit_price * qty))
            
            cat_id = auto_assign_category(item_name, ai_suggested_cat)
            
            # --- 2. ส่งค่า Bounding Box เป็น 0 ทั้งหมด เพื่อไม่ให้ FastAPI แครช ---
            final_items.append(ReceiptItem(
                name=item_name,
                price=unit_price,
                qty=qty,
                date=fallback_date,
                category_id=cat_id,
                bounding_box=BoundingBox(x=0, y=0, w=0, h=0) 
            ))
            
            item_db_values.append((
                cat_id, item_name, qty, unit_price, total_item_price
            ))
            
        async with db_pool.acquire() as conn:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                try:
                    await conn.begin()
                    
                    sql_tx = """
                        INSERT INTO expense_transactions
                        (user_id, store_name, receipt_date, total_amount, source, ocr_status, ocr_duration_ms, ocr_engine, created_at)
                        VALUES (%s, %s, %s, %s, 'ocr', 'success', %s, %s, NOW())
                    """
                    await cur.execute(sql_tx, (auth.id, merchant_name, fallback_date, total_amount, api_duration_ms, engine_name))
                    
                    await conn.commit()
                except Exception as db_err:
                    await conn.rollback()
                    print(f"Database Save Error: {db_err}")
                    raise HTTPException(status_code=500, detail="OCR Success but failed to save to database")
            
        print(f"Total Endpoint Time: {time.time() - start_time:.2f} seconds.")
        return {
            "status": "success",
            "merchant_name": merchant_name,
            "total_amount": total_amount,
            "items": final_items,
            "processed_image_base64": processd_b64,
            "processed_width": img_width,
            "processed_height": img_height
        }
            
    except Exception as e:
        error_msg = str(e)
        error_code = "500"
        if isinstance(e, HTTPException):
            error_code = str(e.status_code)
            
        try:
                async with db_pool.acquire() as conn:
                    async with conn.cursor() as cur:
                        if transaction_id:
                            await cur.execute(
                                "UPDATE expense_transactions SET ocr_status='failed', ocr_error_code=%s, ocr_error_message=%s WHERE transaction_id=%s",
                                (error_code, error_msg, transaction_id)
                            )
                            await conn.commit()
                        else:
                            await cur.execute(
                                """
                                    INSERT INTO expense_transactions
                                    (user_id, source, ocr_status, ocr_error_code, ocr_error_message, ocr_engine, created_at)
                                    VALUES (%s, 'ocr', 'failed', %s, %s, %s, NOW())
                                """,
                                (auth.id, error_code, error_msg, engine_name)
                            )
                        await conn.commit()
        except Exception as db_err:
            print(f"Failed to update status to failed: {db_err}")
        print(f"Server Error: {str(e)}")
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))