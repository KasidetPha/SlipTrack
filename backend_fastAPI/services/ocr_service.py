import time
import base64
import json
import io
import asyncio
from datetime import datetime

import aiomysql
from PIL import Image
from fastapi import HTTPException
from google import genai

from schemas.models import ReceiptItem, BoundingBox
from utils.constants import CATEGORY_MAP
from utils.image_utils import optimize_image_for_gemini

from services.ai_service import (
    build_receipt_prompt,
    call_gemini_receipt_ocr,
    auto_assign_category,
    is_noise_receipt_item,
    fix_common_ocr_errors,
    apply_ocr_corrections
)


async def process_receipt_ocr(
    *,
    file,
    auth,
    db_pool: aiomysql.Pool
):
    transaction_id = None
    api_duration_ms = None
    engine_name = "gemini-2.5-flash-lite"

    try:
        start_time = time.time()

        image_bytes = await file.read()

        print("Optimizing image...")
        optimized_bytes, img_width, img_height = optimize_image_for_gemini(
            image_bytes,
            max_size=2048
        )

        processed_b64 = base64.b64encode(optimized_bytes).decode("utf-8")
        img_for_gemini = Image.open(io.BytesIO(optimized_bytes))

        print(f"Image ready in {time.time() - start_time:.2f} seconds.")

        allowed_cats = ", ".join([f'"{k}"' for k in CATEGORY_MAP.keys()])
        prompt = build_receipt_prompt(allowed_cats)

        max_retries = 3
        raw_response = ""

        async with db_pool.acquire() as conn:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await cur.execute(
                    "SELECT gemini_api_key FROM users WHERE user_id=%s",
                    (auth.id,)
                )
                user_row = await cur.fetchone()

        if not user_row or not user_row["gemini_api_key"]:
            raise HTTPException(
                status_code=403,
                detail="กรุณาเพิ่ม Gemini API Key ก่อนใช้งาน OCR"
            )

        gemini_client = genai.Client(api_key=user_row["gemini_api_key"])

        for attempt in range(max_retries):
            try:
                print(f"Sending image to Gemini (Attempt {attempt + 1}/{max_retries})...")

                api_start_time = time.time()

                raw_response = call_gemini_receipt_ocr(
                    gemini_client,
                    prompt,
                    img_for_gemini
                )

                api_end_time = time.time()
                api_duration_ms = int((api_end_time - api_start_time) * 1000)

                print(f"Gemini API Time: {api_end_time - api_start_time:.2f} วินาที")
                break

            except Exception as api_err:
                err_str = str(api_err)

                if "503" in err_str or "UNAVAILABLE" in err_str.upper():
                    print("Gemini API overloaded. Retrying in 2 seconds...")

                    if attempt < max_retries - 1:
                        await asyncio.sleep(2)
                        continue

                    raise HTTPException(
                        status_code=503,
                        detail="ระบบ AI ขัดข้องชั่วคราวเนื่องจากผู้ใช้งานหนาแน่น"
                    )

                raise HTTPException(
                    status_code=500,
                    detail=f"Gemini API Error: {err_str}"
                )

        if raw_response.startswith("```json"):
            raw_response = raw_response[7:-3]
        elif raw_response.startswith("```"):
            raw_response = raw_response[3:-3]

        try:
            ai_data = json.loads(raw_response)
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=500,
                detail="รูปแบบข้อมูลที่ได้รับจาก AI ไม่ถูกต้อง"
            )

        fallback_date = ai_data.get(
            "receipt_date",
            datetime.now().strftime("%Y-%m-%d")
        )
        merchant_name = ai_data.get("merchant_name", "Unknown Store")

        async with db_pool.acquire() as conn:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                final_items = []

                await cur.execute("""
                    SELECT category_id, icon_name, color_hex
                    FROM categories
                """)
                categories = await cur.fetchall()

                category_map = {
                    c["category_id"]: c for c in categories
                }

                for it in ai_data.get("items", []):
                    item_name = fix_common_ocr_errors(it.get("name", "Unknown"))
                    item_name = await apply_ocr_corrections(item_name, db_pool)
                    ai_suggested_cat = it.get("category", "Others")
                    unit_price = float(it.get("unit_price", 0.0))
                    qty = int(it.get("qty", 1))
                    total_item_price = float(
                        it.get("total_item_price", unit_price * qty)
                    )

                    if is_noise_receipt_item(item_name, total_item_price):
                        continue

                    cat_id = auto_assign_category(item_name, ai_suggested_cat)
                    cat_row = category_map.get(cat_id)

                    final_items.append(ReceiptItem(
                        name=item_name,
                        price=unit_price,
                        qty=qty,
                        date=fallback_date,
                        category_id=cat_id,
                        icon_name=cat_row["icon_name"] if cat_row else None,
                        color_hex=cat_row["color_hex"] if cat_row else None,
                        bounding_box=BoundingBox(x=0, y=0, w=0, h=0)
                    ))

                total_amount = float(ai_data.get("total_amount", 0.0))

                try:
                    await conn.begin()

                    sql_tx = """
                        INSERT INTO expense_transactions
                        (user_id, store_name, receipt_date, total_amount, source,
                         ocr_status, ocr_duration_ms, ocr_engine, created_at)
                        VALUES (%s, %s, %s, %s, 'ocr', 'success', %s, %s, NOW())
                    """

                    await cur.execute(
                        sql_tx,
                        (
                            auth.id,
                            merchant_name,
                            fallback_date,
                            total_amount,
                            api_duration_ms,
                            engine_name
                        )
                    )

                    transaction_id = cur.lastrowid

                    await conn.commit()

                except Exception as db_err:
                    await conn.rollback()
                    print(f"Database Save Error: {db_err}")
                    raise HTTPException(
                        status_code=500,
                        detail="OCR Success but failed to save to database"
                    )

        print(f"Total Endpoint Time: {time.time() - start_time:.2f} seconds.")

        return {
            "status": "success",
            "merchant_name": merchant_name,
            "total_amount": total_amount,
            "items": final_items,
            "processed_image_base64": processed_b64,
            "processed_width": img_width,
            "processed_height": img_height
        }

    except Exception as e:
        if isinstance(e, HTTPException) and e.status_code == 403:
            raise e

        error_msg = str(e)
        error_code = str(e.status_code) if isinstance(e, HTTPException) else "500"

        try:
            async with db_pool.acquire() as conn:
                async with conn.cursor() as cur:
                    if transaction_id:
                        await cur.execute(
                            """
                            UPDATE expense_transactions
                            SET ocr_status='failed',
                                ocr_error_code=%s,
                                ocr_error_message=%s
                            WHERE transaction_id=%s
                            """,
                            (error_code, error_msg, transaction_id)
                        )
                    else:
                        await cur.execute(
                            """
                            INSERT INTO expense_transactions
                            (user_id, store_name, receipt_date, total_amount, source,
                            ocr_status, ocr_error_code, ocr_error_message, ocr_engine, created_at)
                            VALUES (%s, 'Unknown Store', CURDATE(), 0, 'ocr', 'failed', %s, %s, %s, NOW())
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