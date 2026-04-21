from fastapi import APIRouter, Depends, HTTPException, Body, Path
from typing import List
import aiomysql
import pymysql

from core.database import get_db_conn
from core.security import require_auth
from schemas.models import (
    TokenPayload, CategorySummaryBody, ReceiptItemInCategoryOut,
    MonthYear, CategoryMasterOut, CreateCategoryBody, SuggestCategoryBody
)
from services.ai_service import predict_item_category

# ใส่ Prefix ให้ทุก Endpoint ในไฟล์นี้ขึ้นต้นด้วย /categories 
router = APIRouter(prefix="/categories", tags=["Categories"])

@router.post("/summary")
async def categories_summary(
    body: CategorySummaryBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """หน้า Category See All - สรุปยอดรวมว่าแต่ละหมวดหมู่ใช้ไปเท่าไหร่ในเดือนนั้น"""
    if not body.month or not body.year:
        raise HTTPException(status_code=401, detail="Month and Year are required")
    
    sql_main = """
        SELECT 
            c.category_id,
            c.category_name,
            c.icon_name,
            c.color_hex,
            COALESCE(SUM(
                CASE 
                    WHEN et.user_id = %s
                        AND MONTH(et.receipt_date) = %s
                        AND YEAR(et.receipt_date)  = %s
                    THEN ei.total_price
                END
            ), 0) AS total,
            COALESCE(COUNT(
                CASE 
                    WHEN et.user_id = %s
                        AND MONTH(et.receipt_date) = %s
                        AND YEAR(et.receipt_date)  = %s
                    THEN ei.item_name
                END
            ), 0) AS item_count
        FROM categories AS c
        LEFT JOIN expense_items AS ei
            ON ei.category_id = c.category_id
        LEFT JOIN expense_transactions AS et
            ON et.transaction_id = ei.transaction_id
        GROUP BY
            c.category_id,
            c.category_name,
            c.icon_name,
            c.color_hex
        ORDER BY total DESC;
    """
    
    sql_total_month = """
        SELECT COALESCE(SUM(total_amount), 0) AS total_month
        FROM expense_transactions AS et
        WHERE et.user_id = %s
            AND MONTH(et.receipt_date) = %s
            AND YEAR(et.receipt_date) = %s
    """
    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            # ดึงยอดแต่ละหมวดหมู่
            await cur.execute(sql_main, (auth.id, body.month, body.year, auth.id, body.month, body.year))
            rows = await cur.fetchall()
            
            # ดึงยอดรวมของเดือนนี้
            await cur.execute(sql_total_month, (auth.id, body.month, body.year))
            total_row = await cur.fetchone()
            await conn.commit()
            
    total_month = float(total_row.get("total_month", 0)) if total_row else 0.0
    return {"totalMonth": total_month,  "categories": rows}

@router.post("/{categoryId}/items", response_model=List[ReceiptItemInCategoryOut])
async def items_in_category(
    categoryId: int = Path(..., ge=1),
    body: MonthYear = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    """พอกดเข้าไปในแต่ละหมวดหมู่ ก็จะดึงรายการย่อยทั้งหมดออกมา"""
    sql = """
        SELECT 
            ei.item_id       AS item_id,
            ei.item_name     AS item_name,
            ei.quantity      AS quantity,
            ei.total_price   AS total_price,
            ei.category_id   AS category_id,
            et.receipt_date  AS tx_date,
            c.icon_name      AS icon_name,
            c.color_hex      AS color_hex
        FROM expense_items ei
        JOIN expense_transactions et
            ON et.transaction_id  = ei.transaction_id
        JOIN categories c
            ON c.category_id = ei.category_id
        WHERE ei.category_id       = %s
        AND et.user_id             = %s
        AND MONTH(et.receipt_date) = %s
        AND YEAR(et.receipt_date)  = %s
        ORDER BY et.receipt_date DESC, ei.item_id DESC
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (categoryId, auth.id, body.month, body.year))
            rows = await cur.fetchall()
            await conn.commit()
            return rows

@router.get("/master", response_model=List[CategoryMasterOut])
async def get_category_master(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """ดึงข้อมูลหมวดหมู่ตั้งต้นทั้งหมดในระบบ (เอาไปให้หน้าบ้านแคชไว้)"""
    sql = """
        SELECT
            c.category_id       AS category_id,
            c.category_name     AS category_name,
            CASE
                WHEN c.category_type = 'EXPENSE' THEN 'expense'
                ELSE 'income'
            END AS entry_type,
            c.icon_name         AS icon_name,
            c.color_hex         AS color_hex
        FROM categories c
        WHERE c.user_id IS NULL OR c.user_id = %s
        ORDER BY entry_type DESC, category_id
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id,))
            rows = await cur.fetchall()
            await conn.commit()
            
    return rows

@router.post("/")
async def create_category(
    body: CreateCategoryBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """สร้างหมวดหมู่ใหม่เองได้ตามใจชอบ"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                cat_type = "EXPENSE" if body.entry_type.lower() == "expense" else "INCOME"
                
                sql = """
                    INSERT INTO categories 
                    (user_id, category_name, category_type, icon_name, color_hex, is_default)
                    VALUES (%s, %s, %s, %s, %s, 0)
                """
                
                await cur.execute(sql, (
                    auth.id, 
                    body.category_name, 
                    cat_type, 
                    body.icon_name, 
                    body.color_hex
                ))
                
                await conn.commit()
                return {
                    "message": "Category created successfully", 
                    "category_id": cur.lastrowid
                }
                
        except Exception as e:
            await conn.rollback()
            print(f"Error creating category: {e}")
            raise HTTPException(status_code=500, detail="Failed to create category")
        
@router.put("/{category_id}")
async def update_category(
    category_id: int,
    body: CreateCategoryBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """แก้ไขหมวดหมู่ (เปลี่ยนชื่อ, สี, ไอคอน)"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                cat_type = "EXPENSE" if body.entry_type.lower() == "expense" else "INCOME"
                
                sql = """
                    UPDATE categories
                    SET category_name = %s, category_type = %s, icon_name = %s, color_hex = %s
                    WHERE category_id = %s AND user_id = %s
                """
                print(sql, (
                    body.category_name,
                    cat_type,
                    body.icon_name,
                    body.color_hex,
                    category_id,
                    auth.id
                ))
                
                await cur.execute(sql, (
                    body.category_name,
                    cat_type,
                    body.icon_name,
                    body.color_hex,
                    category_id,
                    auth.id
                ))
                
                
                if cur.rowcount == 0:
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail="ไม่พบหมวดหมู่นี้ หรือคุณไม่มีสิทธิ์แก้ไข")
                
                await conn.commit()
                return {"message": "category updated successfully"}
        except pymysql.err.IntegrityError as e:
            await conn.rollback()
            if e.args[0] == 1062:
                raise HTTPException(status_code=400, detail="ชื่อหมวดหมู่นี้มีอยู่แล้ว")
            raise HTTPException(status_code=500, detail="Database error")
        except Exception as e:
            await conn.rollback()
            print(f"Error updating category: {e}")
            raise HTTPException(status_code=500, detail="Failed to update category")
        
@router.delete("/{category_id}")
async def delete_category(
    category_id: int,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """ลบหมวดหมู่ที่ตัวเองสร้าง"""
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                sql = "DELETE FROM categories WHERE category_id = %s AND user_id = %s"
                await cur.execute(sql, (category_id, auth.id))
                
                if cur.rowcount == 0:
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail='ไม่พบหมวดหมู่นี้หรือ คุณไม่มีสิทธิ์ลบ')
                
                await conn.commit()
                return {"message": "Category deleted successfully"}
            
        except pymysql.err.IntegrityError as e:
            await conn.rollback()
            if e.args[0] == 1451:
                raise HTTPException(
                    status_code=400,
                    detail="ไม่สามารถลบหมวดหมู่นี้ได้ เนื่องจากมีรายการบันทึกบัญชีที่ใช้งานหมวดหมู่นี้อยู่"
                )
            raise HTTPException(status_code=500, detail="Database integrity error")
            
        except HTTPException:
            raise
        except Exception as e:
            await conn.rollback()
            print(f"Error deleting category: {e}")
            raise HTTPException(status_code=500, detail="Failed to delete category")
        
    
@router.post("/suggest")
async def suggest_category(
    body: SuggestCategoryBody,
    auth: TokenPayload = Depends(require_auth)
):
    """พิมพ์ชื่อของมา เดี๋ยวให้ AI เดาให้ว่าควรจัดอยู่หมวดหมู่ไหน"""
    if not body.item_name or body.item_name.strip() == "":
        from utils.constants import CATEGORY_MAP # ดึงแค่ตรงนี้กันเหนียว
        return {"category_name": "Others", "category_id": CATEGORY_MAP["Others"]}
    
    # เรียกใช้ฟังก์ชันจากไฟล์ ai_service ที่เราแยกไว้
    result = await predict_item_category(body.item_name)
    return result