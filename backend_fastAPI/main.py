import uvicorn
import os
import jwt
import hashlib
from datetime import datetime, timedelta, timezone, date
from typing import Optional, List, Any
from contextlib import asynccontextmanager
import tempfile
from google import genai
from google.genai import types

import aiomysql
import base64
import json
import httpx
from fastapi import FastAPI, Depends, HTTPException, status, Body, Path, Query, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from dotenv import load_dotenv

from image_utils import preprocess_receipt_image

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY", "")

if not api_key:
    raise ValueError("ไม่พบ GEMINI_API_KEY ในไฟล์ .env ครับ")

gemini_client = genai.Client(api_key=api_key)

# config
MYSQL_HOST = os.getenv("DB_HOST", "localhost")
MYSQL_USER = os.getenv("DB_USER", "root")
MYSQL_PASSWORD = os.getenv("DB_PASSWORD", "password1234")
MYSQL_DB = os.getenv("DB_NAME", "sliptrack")
MYSQL_PORT = int(os.getenv("DB_PORT", "3307"))

POOL_MIN = int(os.getenv("MYSQL_POOL_MIN", "1"))
POOL_MAX = int(os.getenv("MYSQL_POOL_MAX", "10"))

JWT_SECRET = os.getenv("JWT_SECRET", "sliptrackVersion1")
JWT_EXPIRE_HOURS = int(os.getenv("JWT_EXPIRE_HOURS", "1"))
JWT_ALGORITHM = "HS256"

TZ = timezone(timedelta(hours=7))  # Asia/Bangkok

# DB Pool (aiomysql)
pool: Optional[aiomysql.Pool] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    print("Connecting to Database...")
    pool = await aiomysql.create_pool(
        host=MYSQL_HOST,
        port=MYSQL_PORT,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        db=MYSQL_DB,
        autocommit=False,
        minsize=POOL_MIN,
        maxsize=POOL_MAX,
        charset="utf8mb4"
    )
    yield
    print("Closing Database...")
    if pool:
        pool.close()
        await pool.wait_closed()
        
# App & middlewares
app = FastAPI(title="SlipTrack FastAPI", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)
        
# Auth helpers
bearer = HTTPBearer(auto_error=False)

class TokenPayload(BaseModel):
    id: int
    email: str
    exp: int
    
async def get_db_conn() -> aiomysql.Pool:
    if not pool:
        raise HTTPException(status_code=500, detail="DB pool is not ready")
    return pool

def create_jwt(user_id: int, email: str) -> str:
    exp = datetime.now(tz=TZ) + timedelta(hours=JWT_EXPIRE_HOURS)
    payload = {"id": user_id, "email": email, "exp": int(exp.timestamp())}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

async def require_auth(
    credentials: HTTPAuthorizationCredentials = Depends(bearer)
) -> TokenPayload:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="No token provided")
    token = credentials.credentials
    try:
        data = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return TokenPayload(**data)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=403, detail="Invalid or expired token")
    except Exception:
        raise HTTPException(status_code=403, detail="Invalid or expired token")


# Schemas
class LoginBody(BaseModel):
    email: str
    password: str
    
class MonthYearType(BaseModel):
    month: int = Field(..., ge=1, le=12)
    year:int
    type: Optional[str] = Field(default="net") # net | income | expense
    
class MonthYear(BaseModel):
    month: Optional[int] = Field(None, ge=1, le=12)
    year: Optional[int]
    
class CategorySummaryBody(BaseModel):
    month: int
    year: int
    
class UpdateItemBody(BaseModel):
    item_name: str
    quantity: float
    total_price: float
    category_id: int
    receipt_date: Optional[datetime] = None
    
class ReceiptItemOut(BaseModel):
    item_id: int
    full_name: str
    total_price: float
    item_name: str
    tx_date: date
    quantity: float
    category_id: int
    entry_type: str
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    
class CategoryMasterOut(BaseModel):
    category_id: int
    category_name: str
    entry_type: str
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    
class ReceiptItemInCategoryOut(BaseModel):
    item_id: int
    item_name: str
    quantity: float
    total_price: float
    category_id: int
    tx_date: date
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    
class BudgetCategoryItemOut(BaseModel):
    category_id: int
    category_name: str
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    limit: float
    
class BudgetGetResponse(BaseModel):
    month: int
    year: int
    warning_enabled: bool
    warning_percentage: int
    overspending_enabled: bool
    items: List[BudgetCategoryItemOut]
    
class BudgetUpdateItem(BaseModel):
    category_id: int
    limit: float
    
class BudgetUpdateRequest(BaseModel):
    warning_enabled: bool = True
    warning_percentage: int = Field(80, ge=1, le=100)
    overspending_enabled: bool = True
    items: List[BudgetUpdateItem]
    
class CreateIncomeBody(BaseModel):
    amount: float
    source: str
    date: str
    note: Optional[str] = None
    category_name: str
    
class CreateExpenseBody(BaseModel):
    amount: float
    item_name: str
    store_name: Optional[str] = None
    date: date
    note: Optional[str] = None
    category_name: str
    
class MonthlyComparisionResponse(BaseModel):
    this_month: float
    last_month: float
    percent_change: float
    message: str = "ok"
    
class BoundingBox(BaseModel):
    x: int
    y: int
    w: int
    h: int
    
class ReceiptItem(BaseModel):
    name: str
    price: float
    qty: int
    date: str
    category_id: Optional[int] = None
    bounding_box: Optional[BoundingBox] = None
    
class ScanResponse(BaseModel):
    status: str
    merchant_name: str
    items: List[ReceiptItem]
    total_amount: float
    
class ReceiptItemBatchRequest(BaseModel):
    item_name: str
    quantity: int
    total_price: float
    category_id: int
    
class ReceiptBatchCreateRequest(BaseModel):
    merchant_name: str
    receipt_date: date
    total_amount: float
    items: List[ReceiptItemBatchRequest]
    
class UpdateIncomeBody(BaseModel):
    income_source: str
    amount: float
    category_id: int
    income_date: date
    
def encode_image(image_bytes: bytes) -> str:
    return base64.b64encode(image_bytes).decode('utf-8')

# 1. Mapping ให้ตรงกับ Database ของคุณ
CATEGORY_MAP = {
    "Others": 1, 
    "Food": 2, 
    "Shopping": 3, 
    "Bills": 4, 
    "Transportation": 5
}

# 2. Keywords สำหรับช่วยจัดกลุ่ม (ลำดับความสำคัญสูงกว่า AI)
FOOD_KWS = ["ข้าว", "น้ำ", "นม", "ขนม", "อาหาร", "drink", "snack", "noodle"]
SUPPLY_KWS = ["ทิชชู่", "สบู่", "แชมพู", "ผงซักฟอก", "tissue", "soap", "mask", "ครีม"]

def auto_assign_category(item_name: str, ai_category: str) -> int:
    name = item_name.lower()
    
    # เช็ค Keyword ก่อน (แม่นยำกว่าสำหรับของไทย)
    if any(k in name for k in FOOD_KWS): 
        return CATEGORY_MAP["Food"]
    if any(k in name for k in SUPPLY_KWS): 
        return CATEGORY_MAP["Shopping"]
        
    # ถ้าไม่เจอ Keyword ให้ใช้ที่ AI วิเคราะห์มา (เช็ค Case-insensitive)
    return CATEGORY_MAP.get(ai_category, CATEGORY_MAP["Others"])
    
# route
async def _get_budget_data(
    db_pool: aiomysql.Pool,
    user_id: int,
    month: int,
    year: int,
) -> dict:
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(
                """
                SELECT
                    warning_enabled,
                    warning_percentage,
                    overspending_enabled
                FROM budget
                WHERE user_id = %s
                """,
                (user_id,),
            )
            setting = await cur.fetchone()
            
            if setting:
                warning_enabled = bool(setting["warning_enabled"])
                warning_percentage = int(setting['warning_percentage'])
                overspending_enabled = bool(setting["overspending_enabled"])
            else:
                warning_enabled = False
                warning_percentage = 80
                overspending_enabled = True
                
            await cur.execute(
                """
                SELECT
                    c.category_id,
                    c.category_name,
                    c.icon_name,
                    c.color_hex,
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
            await conn.commit()
            
    items: List[BudgetCategoryItemOut] = []
    for r in rows:
        items.append(
            BudgetCategoryItemOut(
                category_id=r["category_id"],
                category_name=r["category_name"],
                icon_name=r.get("icon_name"),
                color_hex=r.get("color_hex"),
                limit=float(r["limit_amount"] or 0)
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

@app.get('/')
async def root():
    return {
        "msg": "hello fastAPI V.2"
    }
    
# login
@app.post("/login")
async def login(body: LoginBody, db_pool: aiomysql.Pool = Depends(get_db_conn)):
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
        
# The most top 2 categories -> home page
@app.post("/receipt_item/categories")
async def receipt_item_categories(
    body: MonthYear = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    now = datetime.now(TZ)
    finalMonth = body.month or now.month
    finalYear = body.year or now.year
    
    sql = """
        SELECT 
            c.category_id,
            c.category_name,
            c.icon_name,
            c.color_hex,
            SUM(ei.total_price) AS total_spent
        FROM expense_items ei
        LEFT JOIN categories c
            ON c.category_id = ei.category_id
        LEFT JOIN expense_transactions et
            ON et.transaction_id = ei.transaction_id
        WHERE et.user_id = %s
            AND MONTH(et.receipt_date) = %s
            AND YEAR(et.receipt_date)  = %s
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
            await cur.execute(sql, (auth.id, finalMonth, finalYear))
            rows = await cur.fetchall()
            await conn.commit()
            return rows
    
# recent transactions -> home page
@app.post("/receipt_item", response_model=List[ReceiptItemOut])
async def receipt_item(
    body: MonthYear = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    now = datetime.now(TZ)
    finalMonth = body.month or now.month
    finalYear = body.year or now.year
    
    sql = """
        (
            SELECT
                ei.item_id                             AS item_id,
                u.full_name                            AS full_name,
                ei.total_price                         AS total_price,
                ei.item_name                           AS item_name,
                et.receipt_date                         AS tx_date,
                ei.quantity                            AS quantity,
                c.category_id                         AS category_id,
                c.icon_name                           AS icon_name,
                c.color_hex                           AS color_hex,
                'expense'                              AS entry_type,
                et.created_at                           AS created_at
            FROM expense_transactions et
            LEFT JOIN users u
                ON u.user_id = et.user_id
            LEFT JOIN expense_items ei
                ON ei.transaction_id = et.transaction_id
            LEFT JOIN categories c
                ON c.category_id = ei.category_id
            WHERE et.user_id = %s
            AND MONTH(et.receipt_date) = %s
            AND YEAR(et.receipt_date)  = %s
        )
        UNION ALL
        (
            SELECT
                it.income_id                           AS item_id,
                u.full_name                            AS full_name,
                it.amount                              AS total_price,
                COALESCE(it.income_source, c.category_id, 'รายรับ')      AS item_name,
                it.income_date                         AS tx_date,
                1                                      AS quantity,
                c.category_id                          AS category_id,
                c.icon_name                            AS icon_name,
                c.color_hex                            AS color_hex,
                'income'                               AS entry_type,
                it.created_at                          AS created_at
            FROM income_transactions it
            LEFT JOIN users u
                ON u.user_id = it.user_id
            LEFT JOIN categories c
                ON c.category_id = it.category_id
            WHERE it.user_id = %s
            AND MONTH(it.income_date) = %s
            AND YEAR(it.income_date)  = %s
        )
        ORDER BY tx_date DESC, created_at DESC
    """

    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, finalMonth, finalYear, auth.id, finalMonth, finalYear))
            rows = await cur.fetchall()
            # await conn.commit()
            return rows
        
@app.post("/monthlyTotal")
async def monthlyTotal(
    body: MonthYearType,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    month, year, t = body.month, body.year, (body.type or "net")
    if not (1 <= month <= 12):
        raise HTTPException(status_code=400, detail="month (1-12) และ year (int) จำเป็นต้องส่งมา")
    
    sql = """
        SELECT
        (SELECT COALESCE(SUM(it.amount), 0)
        FROM income_transactions it
        WHERE it.user_id = %s
            AND MONTH(it.income_date) = %s
            AND YEAR(it.income_date)  = %s) AS income_total_amount,
        (SELECT COALESCE(SUM(et.total_amount), 0)
        FROM expense_transactions et
        WHERE et.user_id = %s
            AND MONTH(et.receipt_date) = %s
            AND YEAR(et.receipt_date)  = %s) AS expense_total_amount;
    """
    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, month, year, auth.id, month, year))
            row = await cur.fetchone()
            await conn.commit()
            
    income_total = float(row.get("income_total_amount", 0)) if row else 0.0
    expense_total = float(row.get("expense_total_amount", 0)) if row else 0.0
    net_total = income_total - expense_total
    
    amount = net_total
    if t == "income":
        amount = income_total
    elif t == "expense":
        amount = expense_total
        
    return {
        "month": month,
        "year": year,
        "amount": float(amount),
        "type": t,
        "breakdown": {
            "income_total_amount": income_total,
            "expense_total_amount": expense_total,
            "net_total": net_total
        }
    }

# category see all homepage -> category see all
@app.post("/categories/summary")
async def categories_summary(
    body: CategorySummaryBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):

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
            await cur.execute(sql_main, (auth.id, body.month, body.year, auth.id, body.month, body.year))
            rows = await cur.fetchall()
            
            await cur.execute(sql_total_month, (auth.id, body.month, body.year))
            total_row = await cur.fetchone()
            await conn.commit()
            
    total_month = float(total_row.get("total_month", 0)) if total_row else 0.0
    return {"totalMonth": total_month,  "categories": rows}
    
# edit transaction
@app.put("/receipt_item/{id}")
async def update_receipt_item(
    id: int = Path(..., ge=1),
    body: UpdateItemBody = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                await cur.execute(
                    """                 
                        SELECT 
                            ei.item_id,
                            ei.item_name,
                            ei.quantity,
                            ei.total_price,
                            ei.category_id,
                            et.transaction_id AS tid,
                            et.receipt_date AS tx_date
                        FROM expense_items ei
                        JOIN expense_transactions et ON et.transaction_id = ei.transaction_id
                        WHERE ei.item_id = %s
                    """,
                    (id,)
                )

                owner = await cur.fetchone()
                if not owner:
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail="Item not found")
                
                # update item
                await cur.execute(
                    """
                        UPDATE expense_items
                        SET item_name=%s, quantity=%s, total_price=%s, category_id=%s
                        WHERE item_id=%s
                    """,
                    (body.item_name, body.quantity, body.total_price, body.category_id, id)
                )
                
                if body.receipt_date:
                    await cur.execute(
                        "UPDATE expense_transactions SET receipt_date=%s WHERE transaction_id=%s",
                        (body.receipt_date, owner["tid"])
                    )
                    
                await cur.execute(
                """                 
                    SELECT 
                        ei.item_id, ei.item_name, ei.quantity, ei.total_price, ei.category_id,
                        et.receipt_date
                    FROM expense_items ei
                    JOIN expense_transactions et ON et.transaction_id = ei.transaction_id
                    WHERE ei.item_id = %s
                """, (id,)
                )
                
                row = await cur.fetchone()
                await conn.commit()
                return row or {"ok": True}
        
        except HTTPException:
            raise
        except Exception as e:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=f"Internet server error: {e}")
        
@app.post("/categories/{categoryId}/items",
            response_model=List[ReceiptItemInCategoryOut])
async def items_in_category(
    categoryId: int = Path(..., ge=1),
    body: MonthYear = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    now = datetime.now(TZ)
    month = (body.month or now.month)
    year = (body.year or now.year)
    
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
            await cur.execute(sql, (categoryId, auth.id, month, year))
            rows = await cur.fetchall()
            await conn.commit()
            return rows

@app.get("/categories/master", response_model=List[CategoryMasterOut])
async def get_category_master(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
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
        ORDER BY entry_type DESC, category_id
    """
    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql)
            rows = await cur.fetchall()
            await conn.commit()
            
    return rows

@app.get("/budgets", response_model=BudgetGetResponse)
async def get_budgets(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=2000, le=2100),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    data = await _get_budget_data(db_pool, auth.id, month, year)
    return data

@app.put("/budgets", response_model=BudgetGetResponse)
async def update_budgets(
    payload: BudgetUpdateRequest = Body(...),
    month: int = Query(..., ge=1, le=12),
    year: int = Query(..., ge=2000, le=2100),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                await cur.execute(
                    """
                    INSERT INTO budget
                        (user_id, warning_enabled, warning_percentage, overspending_enabled)
                    VALUES (%s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        warning_enabled = VALUES(warning_enabled),
                        warning_percentage = VALUES(warning_percentage),
                        overspending_enabled = VALUES(overspending_enabled)
                    """,
                    (
                        auth.id,
                        1 if payload.warning_enabled else 0,
                        payload.warning_percentage,
                        1 if payload.overspending_enabled else 0,
                    )
                )
                
                for item in payload.items:
                    await cur.execute(
                        """
                        INSERT INTO expense_budgets
                            (user_id, category_id, year, month, amount)
                        VALUES (%s, %s, %s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            amount = VALUES(amount)
                        """,
                        (
                            auth.id,
                            item.category_id,
                            year,
                            month,
                            float(item.limit)
                        )
                    )
                await conn.commit()
        except Exception as e:
            await conn.rollback()
            raise HTTPException(
                status_code=500,
                detail=f"Failed to update budgets: {e}"
            )
    data = await _get_budget_data(db_pool, auth.id, month, year)
    return data

@app.post("/incomes")
async def create_income(
    body: CreateIncomeBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()
                
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s
                        AND category_type = 'INCOME'
                        AND (user_id = %s OR is_default = 1)
                    LIMIT 1
                    """,
                    (body.category_name, auth.id)
                )
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code = 400, detail=f"Category {body.category_name} not found")
                
                category_id = cat_row["category_id"]
                
                sql = """
                    INSERT INTO income_transactions
                    (user_id, category_id, amount, income_date, income_source, note, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, NOW())
                """
                
                await cur.execute(sql, (
                    auth.id,
                    category_id,
                    body.amount,
                    body.date,
                    body.source,
                    body.note
                ))
                
                await conn.commit()
                return {"message": "Income created successfully"}
            except Exception as e:
                await conn.rollback()
                print(f"Error creating income: {e}")
                raise HTTPException(status_code=500, detail="Failed to create income")
            
@app.post('/expenses')
async def create_expense(
    body:CreateExpenseBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()
                
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s
                        AND category_type = 'EXPENSE'
                        AND (user_id = %s OR is_default = 1)
                    LIMIT 1
                    """,
                    (body.category_name, auth.id)
                )
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code=400, detail=f"Category '{body.category_name}' not found")
                
                category_id = cat_row["category_id"]
                
                sql_receipt = """
                    INSERT INTO expense_transactions
                    (user_id, store_name, receipt_date, total_amount, source, note, created_at)
                    VALUEs (%s, %s, %s, %s, 'manual', %s, NOW())
                """
                
                await cur.execute(sql_receipt, (
                    auth.id,
                    body.store_name,
                    body.date,
                    body.amount,
                    body.note
                ))
                
                transaction_id = cur.lastrowid
                
                sql_item = """
                    INSERT INTO expense_items
                    (transaction_id, category_id, item_name, quantity, unit_price, total_price)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """
                
                await cur.execute(sql_item, (
                    transaction_id,
                    category_id,
                    body.item_name,
                    1,
                    body.amount,
                    body.amount
                ))
                
                await conn.commit()
                return {"message": "Expense created successfully", "receipt": transaction_id}
            except HTTPException as he:
                await conn.rollback()
                raise he
            except Exception as e:
                await conn.rollback()
                print(f"Error create expense: {e}")
                raise HTTPException(status_code=500, detail=f"Failed to create expense: {str(e)}")
            
@app.post('/monthlyComparison', response_model=MonthlyComparisionResponse)
async def monthly_comparison(
    body: MonthYearType,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
    if body.month == 1:
        prev_month = 12
        prev_year = body.year - 1
    else:
        prev_month = body.month - 1
        prev_year = body.year
        
    table_name = 'expense_transactions'
    date_col = 'receipt_date'
    amount_col = 'total_amount'
    
    if body.type == "income":
        table_name = "income_transactions"
        date_col = "income_date"
        amount_col = "amount"
        
    sql = f"""
        SELECT
            COALESCE(SUM(CASE
                WHEN MONTH({date_col}) = %s AND YEAR({date_col}) = %s THEN {amount_col}
                ELSE 0
            END), 0) as this_month_total,
            COALESCE(SUM(CASE
                WHEN MONTH({date_col}) = %s AND YEAR({date_col}) = %s THEN {amount_col}
                ELSE 0
            END), 0) as last_month_total
        FROM {table_name}
        WHERE user_id = %s
    """
    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (
                body.month, body.year,
                prev_month, prev_year,
                auth.id
            ))
            row = await cur.fetchone()
            
    this_month = float(row['this_month_total'])
    last_month = float(row['last_month_total'])
    
    percent_change = 0.0
    
    if last_month == 0:
        if this_month > 0:
            percent_change = 100.0
        elif this_month < 0:
            percent_change = -100.0
        else:
            percent_change = 0.0
    else:
        percent_change = ((this_month - last_month) / last_month) * 100
        
    return {
        "this_month": this_month,
        "last_month": last_month,
        "percent_change": percent_change
    }
    
# @app.post("/scan-receipt", response_model=ScanResponse)
# async def scan_receipt(file: UploadFile = File(...)):
#     tmp_path = None
#     try:
#         # 1. อ่านไฟล์ที่ส่งมาจาก Flutter เป็น Bytes
#         image_bytes = await file.read()
        
#         # 2. ส่งไปทำความสะอาด จะได้ไฟล์ .png ชั่วคราวกลับมา
#         # สมมติว่าฟังก์ชันนี้คืนค่า path ของไฟล์ที่ clean แล้ว
#         tmp_path = preprocess_receipt_image(image_bytes)
        
#         # โหลดรูปภาพด้วย PIL
#         from PIL import Image
#         img = Image.open(tmp_path)

#         # 3. เตรียม Prompt ตามแบบทดสอบ
#         allowed_cats = ", ".join([f'"{k}"' for k in CATEGORY_MAP.keys()])
#         prompt = f"""
#         You are a STRICT OCR data entry machine. Your ONLY job is to transcribe the EXACT Thai characters from the receipt image.
        
#         CRITICAL RULES:
#         1. ZERO HALLUCINATION: Transcribe character-by-character. DO NOT use autocorrect. DO NOT guess brand names.
#         2. If the text says "ซันชายน์นมโปรตีนสูงช็อกโกแลต340X3", you MUST output exactly that. Do not change it to "ชินนามอนมินิ" or "นมรสจืด". Read the actual pixels.
#         3. Extract the full merchant name (e.g., "CP Axtra PCL พงษ์เพชร").
#         4. Look for discount conditions (e.g., "เงื่อนไขส่วนลด"). If found, put the amount as a POSITIVE number in 'discount'. If no discount, 0.0.
#         5. Validate math: total_amount MUST equal (subtotal - discount).
#         6. Return ONLY valid JSON. 'category' MUST be one of: [{allowed_cats}].
#         7. Date format must be YYYY-MM-DD.

#         Target JSON Structure:
#         {{
#           "merchant_name": "string",
#           "receipt_date": "string",
#           "subtotal": float,
#           "discount": float,
#           "total_amount": float,
#           "items": [
#             {{
#               "name": "string (EXACT printed text, NO autocomplete)",
#               "unit_price": float,
#               "qty": int,
#               "total_item_price": float,
#               "category": "string"
#             }}
#           ]
#         }}
#         """

#         # 4. เรียกใช้งาน Gemini API ด้วย SDK ใหม่
#         print("กำลังส่งภาพให้ Gemini ประมวลผล...")
#         response = gemini_client.models.generate_content(
#             model='gemini-2.5-flash-lite', # หรือใช้ gemini-2.5-flash ถ้ารองรับ
#             contents=[prompt, img],
#             config=types.GenerateContentConfig(
#                 response_mime_type="application/json"
#             )
#         )
        
#         # เนื่องจากตั้งค่า response_mime_type เป็น JSON แล้ว ข้อมูลที่ได้น่าจะเป็น JSON ที่ถูกต้องเลย
#         raw_response = response.text.strip()
        
#         # คลีนข้อมูลเผื่อไว้กรณี Gemini ส่ง Markdown block มา
#         if raw_response.startswith("```json"):
#             raw_response = raw_response[7:-3]
#         elif raw_response.startswith("```"):
#             raw_response = raw_response[3:-3]
            
#         ai_data = json.loads(raw_response)

#         # 5. ประกอบร่างข้อมูลเพื่อส่งกลับให้ Flutter
#         final_items = []
#         fallback_date = ai_data.get("receipt_date", datetime.now().strftime("%Y-%m-%d"))
        
#         for it in ai_data.get("items", []):
#             item_name = it.get("name", "Unknown")
#             ai_suggested_cat = it.get("category", "Others")
            
#             # แปลงโครงสร้างให้ตรงกับ ReceiptItem ของคุณ
#             final_items.append(ReceiptItem(
#                 name=item_name,
#                 price=float(it.get("unit_price", 0.0)), # ใช้ unit_price จาก prompt
#                 qty=int(it.get("qty", 1)),
#                 date=fallback_date, # ใช้ date จากใบเสร็จ
#                 category_id=auto_assign_category(item_name, ai_suggested_cat),
#                 bounding_box=BoundingBox(x=0, y=0, w=0, h=0) 
#             ))

#         return {
#             "status": "success",
#             "merchant_name": ai_data.get("merchant_name", "ไม่ทราบชื่อร้าน"),
#             "total_amount": float(ai_data.get("total_amount", 0.0)),
#             "items": final_items
#         }

#     except Exception as e:
#         print(f"Server Error: {str(e)}")
#         raise HTTPException(status_code=500, detail=str(e))
#     finally:
#         # ลบไฟล์ชั่วคราวออกจากระบบ
#         if tmp_path and os.path.exists(tmp_path):
#             os.remove(tmp_path)

@app.post("/scan-receipt", response_model=ScanResponse)
async def scan_receipt():
    return {
        "status": "success",
        "merchant_name": "CP Axtra PCL พงษ์เพชร",
        "items": [
            {
            "name": "กล้วยหอม กุ้ง 4 ลูก",
            "price": 29,
            "qty": 2,
            "date": "2025-10-20",
            "category_id": 2,
            "bounding_box": {
                "x": 0,
                "y": 0,
                "w": 0,
                "h": 0
            }
            },
            {
            "name": "เบญจรงค์ ข้าวหอมมะลิ 100% 5กก.",
            "price": 182,
            "qty": 1,
            "date": "2025-10-20",
            "category_id": 2,
            "bounding_box": {
                "x": 0,
                "y": 0,
                "w": 0,
                "h": 0
            }
            },
            {
            "name": "ARO ไข่ขาวเหลวสปาร์โร่โชว์ 2 กก.",
            "price": 174,
            "qty": 1,
            "date": "2025-10-20",
            "category_id": 2,
            "bounding_box": {
                "x": 0,
                "y": 0,
                "w": 0,
                "h": 0
            }
            },
            {
            "name": "ซันชายน์นมโปรตีนสูงช็อกโกแลต340X3",
            "price": 135,
            "qty": 1,
            "date": "2025-10-20",
            "category_id": 2,
            "bounding_box": {
                "x": 0,
                "y": 0,
                "w": 0,
                "h": 0
            }
            }
        ],
        "total_amount": 520
        }

@app.post("/debug-image")
async def debug_image(file: UploadFile = File(...)):
    """API สำหรับอัปโหลดรูปและดูผลลัพธ์ Pre-processing โดยเฉพาะ"""
    image_bytes = await file.read()
    
    # โยนเข้าฟังก์ชันทำความสะอาดภาพ
    tmp_path = preprocess_receipt_image(image_bytes)
    
    # คืนค่ากลับไปเป็นไฟล์รูปภาพ (เบราว์เซอร์จะแสดงรูปให้เห็นทันที)
    from fastapi.responses import FileResponse
    return FileResponse(tmp_path, media_type="image/png")
    
@app.post("/receipts/batch")
async def create_batch_receipt(
    body: ReceiptBatchCreateRequest,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            try:
                await conn.begin()
                
                sql_receipt = """
                    INSERT INTO expense_transactions
                    (user_id, store_name, receipt_date, total_amount, source, created_at)
                    VALUES (%s, %s, %s, %s, 'ocr', NOW())
                """
                
                await cur.execute(sql_receipt, (
                    auth.id,
                    body.merchant_name,
                    body.receipt_date,
                    body.total_amount
                ))
                
                transaction_id = cur.lastrowid
                
                if body.items:
                    item_values = []
                    
                    for item in body.items:
                        qty = item.quantity if item.quantity > 0 else 1
                        unit_price = item.total_price / qty
                        
                        item_values.append((
                            transaction_id,
                            item.category_id,
                            item.item_name,
                            item.quantity,
                            unit_price,
                            item.total_price
                        ))
                        
                    sql_items = """
                        INSERT INTO expense_items
                        (transaction_id, category_id, item_name, quantity, unit_price, total_price)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """
                    
                    await cur.executemany(sql_items, item_values)
                
                await conn.commit()
                
                return {
                    "message": "Receipt saved successfully",
                    "transaction_id": transaction_id
                }
                    
                        
            except Exception as e:
                await conn.rollback()
                print(f"Error saving batch: {e}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to save  receipt: {str(e)}"
                )
                
@app.put("/incomes/{id}")
async def update_income(
    id: int = Path(..., ge=1),
    body: UpdateIncomeBody = Body(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                await cur.execute(
                    "SELECT income_id FROM income_transactions WHERE income_id = %s AND user_id = %s",
                    (id, auth.id)
                )
                owner = await cur.fetchone()                
                if not owner:
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail="Income not found or unauthorized")
                
                await cur.execute(
                    """
                        UPDATE income_transactions
                        SET income_source=%s, amount=%s, category_id=%s, income_date=%s
                        WHERE income_id=%s AND user_id=%s
                    """,
                    (body.income_source, body.amount, body.category_id, body.income_date, id, auth.id)
                )
                
                await conn.commit()
                return {"message": "Income updated successfully", "income_id": id}
        except HTTPException:
            raise
        except Exception as e:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=f"Internal server error: {e}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)