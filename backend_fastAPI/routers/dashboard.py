from fastapi import APIRouter, Depends
from datetime import datetime
import aiomysql
from typing import Optional

from core.security import require_auth
from core.database import get_db_conn 

from schemas.models import (
    TokenPayload
)

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)

@router.get("/summary")
async def get_dashboard_summary(
    month: Optional[int] = None,
    year: Optional[int] = None,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    target_month = month or datetime.now().month
    target_year = year or datetime.now().year
    target_date_str = f"{target_year}-{target_month:02d}-01"
    
    overview = {"total_income": 0.0, "total_expense": 0.0, "balance": 0.0}
    expense_by_category = []
    six_months_trend = []

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            
            # ==========================================
            # 1. Overview (ภาพรวมเดือนปัจจุบัน)
            # ==========================================
            await cur.execute("""
                SELECT COALESCE(SUM(amount), 0) AS total_income
                FROM income_transactions 
                WHERE user_id = %s 
                  AND MONTH(income_date) = %s
                  AND YEAR(income_date) = %s
            """, (auth.id, target_month, target_year))
            income_row = await cur.fetchone()
            overview["total_income"] = float(income_row["total_income"]) if income_row else 0.0

            await cur.execute("""
                SELECT COALESCE(SUM(total_amount), 0) AS total_expense
                FROM expense_transactions 
                WHERE user_id = %s 
                  AND MONTH(receipt_date) = %s
                  AND YEAR(receipt_date) = %s
            """, (auth.id, target_month, target_year))
            expense_row = await cur.fetchone()
            overview["total_expense"] = float(expense_row["total_expense"]) if expense_row else 0.0

            overview["balance"] = overview["total_income"] - overview["total_expense"]

            # ==========================================
            # 2. Expense by Category (สัดส่วนรายจ่ายเดือนปัจจุบัน)
            # ==========================================
            await cur.execute("""
                SELECT 
                    c.category_name, 
                    SUM(ei.total_price) as amount,
                    MAX(c.color_hex) as color_hex
                FROM expense_items ei
                JOIN expense_transactions et ON ei.transaction_id = et.transaction_id
                JOIN categories c ON ei.category_id = c.category_id
                WHERE et.user_id = %s 
                  AND MONTH(et.receipt_date) = %s
                  AND YEAR(et.receipt_date) = %s
                GROUP BY c.category_name
                ORDER BY amount DESC
            """, (auth.id, target_month, target_year))
            
            cat_rows = await cur.fetchall()
            
            sum_items_total = sum(float(row["amount"]) for row in cat_rows)
            for row in cat_rows:
                amt = float(row["amount"])
                percentage = round((amt / sum_items_total * 100), 1) if sum_items_total > 0 else 0
                expense_by_category.append({
                    "category_name": row["category_name"],
                    "amount": amt,
                    "percentage": percentage,
                    "color_hex": row["color_hex"] or "#FB2966"
                })

            # ==========================================
            # 3. 6-Month Trend (แนวโน้ม 6 เดือนย้อนหลัง)
            # ==========================================
            await cur.execute("""
                SELECT 
                    DATE_FORMAT(t.entry_date, '%%b') as month_label,
                    MONTH(t.entry_date) as month_num,
                    YEAR(t.entry_date) as year_num,
                    SUM(CASE WHEN t.entry_type = 'income' THEN t.amount ELSE 0 END) as income,
                    SUM(CASE WHEN t.entry_type = 'expense' THEN t.amount ELSE 0 END) as expense
                FROM (
                    SELECT income_date as entry_date, amount, 'income' as entry_type
                    FROM income_transactions
                    WHERE user_id = %s 
                      AND income_date >= DATE_SUB(LAST_DAY(%s), INTERVAL 5 MONTH)
                      AND income_date <= LAST_DAY(%s)
                    
                    UNION ALL
                    
                    SELECT receipt_date as entry_date, total_amount as amount, 'expense' as entry_type
                    FROM expense_transactions
                    WHERE user_id = %s 
                      AND receipt_date >= DATE_SUB(LAST_DAY(%s), INTERVAL 5 MONTH)
                      AND receipt_date <= LAST_DAY(%s)
                ) as t
                GROUP BY YEAR(t.entry_date), MONTH(t.entry_date), DATE_FORMAT(t.entry_date, '%%b')
                ORDER BY year_num ASC, month_num ASC
            """, (auth.id, target_date_str, target_date_str, auth.id, target_date_str, target_date_str))
            
            trend_rows = await cur.fetchall()
            for row in trend_rows:
                six_months_trend.append({
                    "month_label": row["month_label"],
                    "income": float(row["income"]),
                    "expense": float(row["expense"])
                })

    return {
        "overview": overview,
        "expense_by_category": expense_by_category,
        "six_months_trend": six_months_trend
    }