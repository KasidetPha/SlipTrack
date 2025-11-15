import uvicorn
import os
import jwt
import hashlib
from datetime import datetime, timedelta, timezone, date
from typing import Optional, List, Any

import aiomysql
from fastapi import FastAPI, Depends, HTTPException, status, Body, Path
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from dotenv import load_dotenv

load_dotenv()

# config

MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_DB = os.getenv("MYSQL_DB", "sliptrack")
MYSQL_PORT = int(os.getenv("MYSQL_PORT", "3306"))
POOL_MIN = int(os.getenv("MYSQL_POOL_MIN", "1"))
POOL_MAX = int(os.getenv("MYSQL_POOL_MAX", "10"))

JWT_SECRET = os.getenv("JWT_SECRET", "sliptrackVersion1")
JWT_EXPIRE_HOURS = int(os.getenv("JWT_EXPIRE_HOURS", "1"))
JWT_ALGORITHM = "HS256"

TZ = timezone(timedelta(hours=7))  # Asia/Bangkok

# App & middlewares

app = FastAPI(title="SlipTrack FastAPI")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# DB Pool (aiomysql)

pool: aiomysql.Pool | None = None

@app.on_event("startup")
async def startup():
    global pool
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
    
@app.on_event("shutdown")
async def shutdown():
    global pool
    if pool:
        pool.close()
        await pool.wait_closed()
        
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
    
# route

@app.get('/')
async def root():
    return {
        "msg": "hello fastAPI"
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
            ec.category_id,
            ec.category_name,
            ec.icon_name,
            ec.color_hex,
            SUM(ri.total_price) AS total_spent
        FROM receipt_items ri
        LEFT JOIN expense_categories ec
            ON ec.category_id = ri.category_id
        LEFT JOIN receipts r
            ON r.receipt_id = ri.receipt_id
        WHERE r.user_id = %s
            AND MONTH(r.receipt_date) = %s
            AND YEAR(r.receipt_date)  = %s
        GROUP BY
            ec.category_id,
            ec.category_name,
            ec.icon_name,
            ec.color_hex
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
                ri.item_id                             AS item_id,
                u.full_name                            AS full_name,
                ri.total_price                         AS total_price,
                ri.item_name                           AS item_name,
                r.receipt_date                         AS tx_date,
                ri.quantity                            AS quantity,
                ec.category_id                         AS category_id,
                ec.icon_name                           AS icon_name,
                ec.color_hex                           AS color_hex,
                'expense'                              AS entry_type
            FROM receipts r
            LEFT JOIN users u
                ON u.user_id = r.user_id
            LEFT JOIN receipt_items ri
                ON ri.receipt_id = r.receipt_id
            LEFT JOIN expense_categories ec
                ON ec.category_id = ri.category_id
            WHERE r.user_id = %s
            AND MONTH(r.receipt_date) = %s
            AND YEAR(r.receipt_date)  = %s
        )
        UNION ALL
        (
            SELECT
                i.income_id                            AS item_id,
                u.full_name                            AS full_name,
                i.amount                               AS total_price,
                ic.income_category_name                AS item_name,
                i.income_date                          AS tx_date,
                1                                      AS quantity,          -- ไม่มี quantity เลยใส่ 1 ไว้
                ic.income_category_id                  AS category_id,
                ic.icon_name                           AS icon_name,
                ic.color_hex                           AS color_hex,
                'income'                               AS entry_type
            FROM incomes i
            LEFT JOIN users u
                ON u.user_id = i.user_id
            LEFT JOIN income_categories ic
                ON ic.income_category_id = i.income_category_id
            WHERE i.user_id = %s
            AND MONTH(i.income_date) = %s
            AND YEAR(i.income_date)  = %s
        )
        ORDER BY tx_date DESC
    """

    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql, (auth.id, finalMonth, finalYear, auth.id, finalMonth, finalYear))
            rows = await cur.fetchall()
            await conn.commit()
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
        (SELECT COALESCE(SUM(i.amount), 0)
        FROM incomes i
        WHERE i.user_id = %s
            AND MONTH(i.income_date) = %s
            AND YEAR(i.income_date)  = %s) AS income_total_amount,
        (SELECT COALESCE(SUM(r.total_amount), 0)
        FROM receipts r
        WHERE r.user_id = %s
            AND MONTH(r.receipt_date) = %s
            AND YEAR(r.receipt_date)  = %s) AS expense_total_amount;
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
            cate.category_id,
            cate.category_name,
            cate.icon_name,
            cate.color_hex,
            COALESCE(SUM(
                CASE 
                    WHEN re.user_id = %s
                        AND MONTH(re.receipt_date) = %s
                        AND YEAR(re.receipt_date)  = %s
                    THEN ri.total_price
                END
            ), 0) AS total,
            COALESCE(COUNT(
                CASE 
                    WHEN re.user_id = %s
                        AND MONTH(re.receipt_date) = %s
                        AND YEAR(re.receipt_date)  = %s
                    THEN ri.item_name
                END
            ), 0) AS item_count
        FROM expense_categories AS cate
        LEFT JOIN receipt_items AS ri
            ON ri.category_id = cate.category_id
        LEFT JOIN receipts AS re
            ON re.receipt_id = ri.receipt_id
        GROUP BY
            cate.category_id,
            cate.category_name,
            cate.icon_name,
            cate.color_hex
        ORDER BY total DESC;
    """
    
    sql_total_month = """
        SELECT COALESCE(SUM(total_amount), 0) AS total_month
        FROM receipts AS re
        WHERE re.user_id = %s
            AND MONTH(re.receipt_date) = %s
            AND YEAR(re.receipt_date) = %s
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
                        SELECT ri.receipt_id AS rid
                        FROM receipt_items AS ri
                        JOIN receipts AS re ON re.receipt_id = ri.receipt_id
                        WHERE ri.item_id = %s AND re.user_id = %s
                        FOR UPDATE
                    """, (id, auth.id)
                )
                
                owner = await cur.fetchone()
                if not owner:
                    await conn.rollback()
                    raise HTTPException(status_code=404, detail="Item not found")
                
                # update item
                await cur.execute(
                    """
                        UPDATE receipt_items
                        SET item_name=%s, quantity=%s, total_price=%s, category_id=%s
                        WHERE item_id=%s
                    """,
                    (body.item_name, body.quantity, body.total_price, body.category_id, id)
                )
                
                if body.receipt_date:
                    await cur.execute(
                        "UPDATE receipts SET receipt_date=%s WHERE receipt_id=%s",
                        (body.receipt_date, owner["rid"])
                    )
                    
                await cur.execute(
                """                  
                    SELECT 
                        ri.item_id, ri.item_name, ri.quantity, ri.total_price, ri.category_id,
                        re.receipt_date
                    FROM receipt_items ri
                    JOIN receipts re ON re.receipt_id = ri.receipt_id
                    WHERE ri.item_id = %s
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
        
@app.post("/categories/{categoryId}/items")
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
            ri.item_id       AS item_id,
            ri.item_name     AS item_name,
            ri.quantity      AS quantity,
            ri.total_price   AS total_price,
            ri.category_id   AS category_id,
            re.receipt_date  AS receipt_date,
            ec.icon_name     AS icon_name,
            ec.color_hex     AS color_hex
        FROM receipt_items ri
        JOIN receipts re
            ON re.receipt_id  = ri.receipt_id
        JOIN expense_categories ec
            ON ec.category_id = ri.category_id
        WHERE ri.category_id       = %s
        AND re.user_id           = %s
        AND MONTH(re.receipt_date) = %s
        AND YEAR(re.receipt_date)  = %s
        ORDER BY re.receipt_date DESC, ri.item_id DESC
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
            ec.category_id       AS category_id,
            ec.category_name     AS category_name,
            'expense'            AS entry_type,
            ec.icon_name         AS icon_name,
            ec.color_hex         AS color_hex
        FROM expense_categories ec

        UNION ALL

        SELECT
            ic.income_category_id   AS category_id,
            ic.income_category_name AS category_name,
            'income'                AS entry_type,
            ic.icon_name            AS icon_name,
            ic.color_hex            AS color_hex
        FROM income_categories ic

        ORDER BY entry_type, category_id;
    """

    
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute(sql)
            rows = await cur.fetchall()
            await conn.commit()
            
    return rows

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)