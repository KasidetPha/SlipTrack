import uvicorn
import os
import jwt
from datetime import datetime, timedelta, timezone, date
from typing import Optional, List, Any
from contextlib import asynccontextmanager
from google import genai
from google.genai import types

import aiomysql
import base64
import json
from fastapi import FastAPI, Depends, HTTPException, status, Body, Path, Query, File, UploadFile, BackgroundTasks
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import asyncio

from image_utils import preprocess_receipt_image, optimize_image_for_gemini
import time
from PIL import Image
import io

import firebase_admin
from firebase_admin import credentials, messaging

cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)

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
    month: int = Field(default_factory=lambda: datetime.now(TZ).month, ge=1, le=12)
    year: int = Field(default_factory=lambda: datetime.now(TZ).year)
    
class CategorySummaryBody(BaseModel):
    month: int
    year: int
    
class UpdateItemBody(BaseModel):
    item_name: str
    quantity: float
    total_price: float
    category_id: int
    receipt_date: Optional[datetime] = None
    note: Optional[str] = None
    
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
    note: Optional[str] = None
    
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
    limit_amount: float # เปลี่ยนชื่อจาก limit เป็น limit_amount ให้ชัดเจนขึ้น

class BudgetGetResponse(BaseModel):
    month: int
    year: int
    warning_enabled: bool
    warning_percentage: int
    overspending_enabled: bool
    items: List[BudgetCategoryItemOut]

class BudgetUpdateItem(BaseModel):
    category_id: int
    limit_amount: float # เปลี่ยนให้ตรงกับ Response

class BudgetUpdateRequest(BaseModel):
    month: int
    year: int
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
    processed_image_base64: Optional[str] = None
    processed_width: Optional[int] = None
    processed_height: Optional[int] = None
    
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
    note: Optional[str] = None
    
class SuggestCategoryBody(BaseModel):
    item_name: str
    
class CreateCategoryBody(BaseModel):
    category_name: str
    entry_type: str  # 'expense' หรือ 'income'
    icon_name: Optional[str] = "category_rounded" 
    color_hex: Optional[str] = "FF64748B"
    
class FCMTokenBody(BaseModel):
    token: str
    
class NotificationOut(BaseModel):
    notification_id: int
    title: str
    body: str
    notification_type: str
    is_read: bool
    created_at: datetime

# 1. Mapping ให้ตรงกับ Database ของคุณ
CATEGORY_MAP = {
    "Others": 1, 
    "Food": 2, 
    "Shopping": 3, 
    "Bills": 4, 
    "Transportation": 5
}

# 2. Keywords สำหรับช่วยจัดกลุ่ม (ลำดับความสำคัญสูงกว่า AI)
FOOD_KWS = [
    "ข้าว", "น้ำ", "นม", "ขนม", "อาหาร", "drink", "snack", "noodle", 
    "หมู", "ไก่", "เนื้อ", "ปลา", "กุ้ง", "หมึก", "ผัก", "ผลไม้", 
    "กาแฟ", "ชา", "น้ำแข็ง", "เบียร์", "เหล้า", "โค้ก", "เป๊ปซี่", "มาม่า", 
    "ซอส", "น้ำมัน", "น้ำตาล", "เกลือ", "พริก", "กระเทียม", "บุฟเฟ่ต์", "ชาบู", 
    "หมูกระทะ", "เค้ก", "คุกกี้", "ลูกอม", "ช็อกโกแลต",
    "kfc", "mcdonald", "burger", "pizza", "coffee", "tea", "water", 
    "milk", "meat", "pork", "beef", "chicken", "seafood", "fruit"
]

SUPPLY_KWS = [
    "ทิชชู่", "สบู่", "แชมพู", "ผงซักฟอก", "tissue", "soap", "mask", "ครีม",
    "ยาสีฟัน", "แปรงสีฟัน", "น้ำยาบ้วนปาก", "ครีมนวด", "โฟมล้างหน้า", "โลชั่น", 
    "น้ำหอม", "โรลออน", "ยาสระผม", "เครื่องสำอาง", "ลิป", "แป้ง",
    "ปากกา", "ดินสอ", "สมุด", "ยางลบ", "กระดาษ",
    "เสื้อ", "กางเกง", "รองเท้า", "กระเป๋า", "ถุงเท้า",
    "ยา", "พารา", "ยาดม", "พลาสเตอร์", "ถ่าน", "แบตเตอรี่", "หลอดไฟ", "ปลั๊ก",
    "shampoo", "conditioner", "lotion", "toothpaste", "shirt", "pants", 
    "shoes", "bag", "medicine", "pharmacy", "watsons", "boots", "shein"
]

TRANSPORT_KWS = [
    "bus", "รถ", "เดินทาง", "bts", "mrt", "taxi", "วิน", "ทางด่วน", "grab", "bolt", "toll",
    "arl", "srt", "ค่าน้ำมัน", "เติมน้ำมัน", "แก๊ส", "ค่าที่จอด", "จอดรถ", 
    "สองแถว", "เรือ", "เครื่องบิน", "ตั๋ว", "ค่าผ่านทาง", "easy pass", "m-flow",
    "ปตท", "บางจาก", "ptt", "bangchak", "shell", "caltex", "esso",
    "flight", "ticket", "train", "boat", "ferry", "parking", "fuel", "gas", "petrol"
]

BILL_KWS = [
    "ค่าไฟ", "ค่าน้ำ", "ค่าเน็ต", "ค่าโทรศัพท์", "บัตรเครดิต", "bill", "internet", "ais", "true", "dtac",
    "รายเดือน", "เติมเงิน", "ประกัน", "สินเชื่อ", "ผ่อน", "ภาษี", 
    "การไฟฟ้า", "กฟน", "กฟภ", "การประปา", "กปน", "กปภ", "3bb", "nt", "tot", 
    "ชำระ", "ค่างวด", "ค่าเช่า", "หอพัก",
    "netflix", "spotify", "youtube premium", "icloud", "google one",
    "rent", "electricity", "water bill", "phone bill", "credit card", "insurance", "tax", "subscription"
]

def auto_assign_category(item_name: str, ai_category: str) -> int:
    name = item_name.lower()
    
    if any(k in name for k in FOOD_KWS): return CATEGORY_MAP["Food"]
    if any(k in name for k in SUPPLY_KWS): return CATEGORY_MAP["Shopping"]
    if any(k in name for k in TRANSPORT_KWS): return CATEGORY_MAP["Transportation"]
    if any(k in name for k in BILL_KWS): return CATEGORY_MAP["Bills"]
        
    return CATEGORY_MAP.get(ai_category, CATEGORY_MAP["Others"])
    
async def predict_item_category(item_name: str) -> dict:
    name = item_name.lower()
    
    # สเต็ป 1: ดักด้วย Keyword ก่อน (จัดการคำว่า 'bus' ได้อยู่หมัดตรงนี้เลย)
    if any(k in name for k in FOOD_KWS): 
        return {"category_name": "Food", "category_id": CATEGORY_MAP["Food"]}
    if any(k in name for k in SUPPLY_KWS): 
        return {"category_name": "Shopping", "category_id": CATEGORY_MAP["Shopping"]}
    if any(k in name for k in TRANSPORT_KWS): 
        return {"category_name": "Transportation", "category_id": CATEGORY_MAP["Transportation"]}
    if any(k in name for k in BILL_KWS): 
        return {"category_name": "Bills", "category_id": CATEGORY_MAP["Bills"]}
        
    # สเต็ป 2: ถ้าไม่เจอ Keyword ค่อยให้ Gemini ช่วยคิด
    allowed_cats = ", ".join([f'"{k}"' for k in CATEGORY_MAP.keys()])
    prompt = f"""
    Classify the following receipt item into EXACTLY ONE of these categories: [{allowed_cats}].
    Item name: "{item_name}"
    Return ONLY the exact category name as plain text. No markdown, no extra words.
    If it is related to vehicles, travel, or fares, classify as "Transportation".
    """
    try:
        response = gemini_client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(temperature=0.0)
        )
        predicted_cat = response.text.strip()
        
        if predicted_cat in CATEGORY_MAP:
            return {"category_name": predicted_cat, "category_id": CATEGORY_MAP[predicted_cat]}
    except Exception as e:
        print(f"Gemini prediction failed for '{item_name}': {e}")
        
    return {"category_name": "Others", "category_id": CATEGORY_MAP["Others"]}

# --- Keywords สำหรับฝั่ง Income (ดักทุกทาง) ---

SALARY_KWS = [
    'salary', 'payroll', 'เงินเดือน', 'โบนัส', 'bonus', 
    'เบี้ยเลี้ยง', 'ค่าตำแหน่ง', 'เงินประจำ', 'ค่าตอบแทน', 'เงินบำนาญ', 
    'สวัสดิการ', 'allowance', 'pension', 'เงินช่วยเหลือ', 'ฐานเงินเดือน'
]

WAGE_KWS = [
    'wage', 'job', 'freelance', 'ค่าจ้าง', 'รับจ๊อบ', 'parttime', 'พาร์ทไทม์', 
    'งานพิเศษ', 'จ้าง', 'ค่านายหน้า', 'คอมมิชชั่น', 'commission', 
    'ค่าแรง', 'ค่ากะ', 'โอที', 'ot', 'overtime', 'สอนพิเศษ', 'tutor', 
    'งานนอก', 'รับงาน', 'ค่าเหนื่อย', 'ติวเตอร์', 'ขับแกร็บ', 'grab', 'lineman'
]

GIFT_KWS = [
    'gift', 'present', 'donate', 'ให้', 'ของขวัญ', 'แต๊ะเอีย', 'พ่อให้', 'แม่ให้', 
    'อั่งเปา', 'ถูกหวย', 'ลอตเตอรี่', 'lottery', 'รางวัล', 'เงินคืน', 
    'cashback', 'คืนเงิน', 'refund', 'ทุนการศึกษา', 'บริจาค', 'ได้ฟรี', 
    'ปันผล', 'ดอกเบี้ย', 'interest', 'dividend', 'แฟนให้', 'พี่ให้', 
    'เพื่อนคืนเงิน', 'ลูกหนี้', 'เงินทอน', 'คนละครึ่ง', 'รัฐให้'
]

SALE_KWS = [
    'sale', 'business', 'store', 'ขาย', 'ค้าขาย', 'กำไร', 'ลูกค้า', 
    'รายได้จากร้าน', 'ขายของ', 'ยอดขาย', 'ออเดอร์', 'order', 
    'shopee', 'lazada', 'tiktok shop', 'รายรับร้าน', 'ค่าของ', 'ค่าสินค้า', 
    'กำไรสุทธิ', 'revenue', 'profit', 'ปิดยอด', 'โอนค่าของ', 'พรีออเดอร์'
]

async def predict_income_category(source_name: str) -> dict:
    name = source_name.lower()
    
    # สเต็ป 1: ดักด้วย Keyword
    if any(k in name for k in SALARY_KWS): return {"category_name": "Salary"}
    if any(k in name for k in WAGE_KWS): return {"category_name": "Wages"}
    if any(k in name for k in GIFT_KWS): return {"category_name": "Gift"}
    if any(k in name for k in SALE_KWS): return {"category_name": "Sales"}
        
    # สเต็ป 2: ถ้าไม่เจอให้ Gemini ช่วยคิด
    prompt = f"""
    Classify the following income source into EXACTLY ONE of these categories: ["Salary", "Wages", "Gift", "Sales", "Others"].
    Income source: "{source_name}"
    Return ONLY the exact category name as plain text. No markdown, no extra words.
    """
    try:
        response = gemini_client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(temperature=0.0)
        )
        predicted_cat = response.text.strip()
        
        valid_cats = ["Salary", "Wages", "Gift", "Business Sales", "Others"]
        if predicted_cat in valid_cats:
            return {"category_name": predicted_cat}
    except Exception as e:
        print(f"Gemini income prediction failed for '{source_name}': {e}")
        
    return {"category_name": "Others"}

async def _get_budget_data(
    db_pool: aiomysql.Pool,
    user_id: int,
    month: int,
    year: int,
) -> dict:
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            # 1. ดึงการตั้งค่าการแจ้งเตือนจากตาราง budget
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
                
            # 2. ดึงหมวดหมู่รายจ่ายทั้งหมด และ Join กับเป้าหมายงบประมาณ (ถ้ามี)
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
    
def send_push_notification(token: str, title: str, body: str):
    """
    ฟังก์ชันสำหรับส่งแจ้งเตือนไปยัง FCM Token ที่ระบุ
    """
    if not token:
        print("ไม่มี Token ไม่สามารถส่งแจ้งเตือนได้")
        return False

    try:
        # สร้างรูปแบบข้อความ
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=token,
        )

        # สั่งยิงข้อความ
        response = messaging.send(message)
        print(f"ส่งแจ้งเตือนสำเร็จ! Message ID: {response}")
        return True
    except Exception as e:
        print(f"ส่งแจ้งเตือนไม่สำเร็จ: {e}")
        return False

# route
@app.get('/')
async def root():
    return {
        "msg": "hello fastAPI on SlipTrack V.1 **linux"
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
            await cur.execute(sql, (auth.id, body.month, body.year))
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
    
    sql = """
        (
            SELECT
                ei.item_id                             AS item_id,
                u.full_name                            AS full_name,
                ei.total_price                         AS total_price,
                ei.item_name                           AS item_name,
                et.receipt_date                        AS tx_date,
                ei.quantity                            AS quantity,
                c.category_id                          AS category_id,
                c.icon_name                            AS icon_name,
                c.color_hex                            AS color_hex,
                'expense'                              AS entry_type,
                et.created_at                          AS created_at,
                ei.note                                AS note
            FROM expense_transactions et
            JOIN users u
                ON u.user_id = et.user_id
            JOIN expense_items ei
                ON ei.transaction_id = et.transaction_id
            JOIN categories c
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
                it.created_at                          AS created_at,
                it.note                                AS note
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
            await cur.execute(sql, (auth.id, body.month, body.year, auth.id, body.month, body.year))
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
                        SET item_name=%s, quantity=%s, total_price=%s, category_id=%s, note=%s
                        WHERE item_id=%s
                    """,
                    (body.item_name, body.quantity, body.total_price, body.category_id, body.note, id)
                )
                
                await cur.execute(
                    """
                        UPDATE expense_transactions 
                        SET receipt_date = COALESCE(%s, receipt_date), note = %s 
                        WHERE transaction_id = %s
                    """,
                    (body.receipt_date, body.note, owner["tid"])
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

@app.post("/categories")
async def create_category(
    body: CreateCategoryBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor(aiomysql.DictCursor) as cur:
                await conn.begin()
                
                # แปลงค่า type ให้ตรงกับ ENUM ใน Database
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
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn),
):
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
                        (
                            auth.id,
                            item.category_id,
                            payload.year,
                            payload.month,
                            float(item.limit_amount)
                        )
                    )
                await conn.commit()
                
        except Exception as e:
            await conn.rollback()
            raise HTTPException(
                status_code=500,
                detail=f"Failed to update budgets: {e}"
            )
            
    # ดึงข้อมูลที่เพิ่งอัปเดตกลับไปให้ Frontend
    data = await _get_budget_data(db_pool, auth.id, payload.month, payload.year)
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
                
                target_category_name = body.category_name.strip()
                
                if target_category_name.lower() == 'auto':
                    prediction = await predict_income_category(body.source)
                    target_category_name = prediction["category_name"]
                    
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s
                        AND category_type = 'INCOME'
                        AND (user_id = %s OR is_default = 1)
                    LIMIT 1
                    """,
                    (target_category_name, auth.id)
                )
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code=400, detail=f"Category {target_category_name} not found")
                
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
                
                target_category_name = body.category_name
                
                if target_category_name.lower() == "auto":
                    prediction = await predict_item_category(body.item_name)
                    target_category_name = prediction["category_name"]
                    
                await cur.execute(
                    """
                    SELECT category_id FROM categories
                    WHERE category_name = %s
                        AND category_type = 'EXPENSE'
                        AND (user_id = %s OR is_default = 1)
                    LIMIT 1
                    """,
                    (target_category_name, auth.id)
                )
                
                cat_row = await cur.fetchone()
                
                if not cat_row:
                    raise HTTPException(status_code=400, detail=f"Category '{target_category_name}' not found")
                
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
                    (transaction_id, category_id, item_name, quantity, unit_price, total_price, note)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """
                
                await cur.execute(sql_item, (
                    transaction_id,
                    category_id,
                    body.item_name,
                    1,
                    body.amount,
                    body.amount,
                    body.note
                ))
                
                await conn.commit()
                background_tasks.add_task(check_and_notify_budget, auth.id, category_id, db_pool)
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
    
@app.post("/scan-receipt", response_model=ScanResponse)
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
                    
                    # transaction_id = cur.lastrowid
                    
                    # if item_db_values:
                    #     final_db_values = [(transaction_id, *val) for val in item_db_values]
                        
                    #     sql_items = """
                    #         INSERT INTO expense_items
                    #         (transaction_id, category_id, item_name, quantity, unit_price, total_price)
                    #         VALUES (%s, %s, %s, %s, %s, %s)
                    #     """
                    #     await cur.executemany(sql_items, final_db_values)
                        
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
    
@app.post("/debug-image")
async def debug_image(file: UploadFile = File(...)):
    image_bytes = await file.read()
    
    processed_bytes, width, height = preprocess_receipt_image(image_bytes)
    import io
    # ส่งรูปกลับเป็น Stream และแนบขนาดภาพไปใน Header
    return StreamingResponse(
        io.BytesIO(processed_bytes), 
        media_type="image/png",
        headers={
            "X-Image-Width": str(width),
            "X-Image-Height": str(height)
        }
    )
    
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
                
                sql_find_latest = """
                    SELECT transaction_id 
                    FROM expense_transactions 
                    WHERE user_id = %s 
                    ORDER BY transaction_id DESC 
                    LIMIT 1
                """
                await cur.execute(sql_find_latest, (auth.id,))
                latest_tx = await cur.fetchone()
                
                if not latest_tx:
                    raise HTTPException(status_code=404, detail="ไม่พบรายการสแกนก่อนหน้าที่จะทำการบันทึก")
                    
                transaction_id = latest_tx['transaction_id']
                
                sql_update_receipt = """
                    UPDATE expense_transactions
                    SET store_name = %s, 
                        receipt_date = %s, 
                        total_amount = %s, 
                        ocr_status = 'success',
                        updated_at = NOW()
                    WHERE transaction_id = %s
                """
                
                await cur.execute(sql_update_receipt, (
                    body.merchant_name,
                    body.receipt_date,
                    body.total_amount,
                    transaction_id
                ))
                
                await cur.execute("DELETE FROM expense_items WHERE transaction_id = %s", (transaction_id,))
                
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
                background_tasks.add_task(check_and_notify_budget, auth.id, category_id, db_pool)
                
                return {
                    "message": "Receipt updated successfully",
                    "transaction_id": transaction_id
                }
                    
            except Exception as e:
                await conn.rollback()
                print(f"Error saving batch: {e}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to update receipt: {str(e)}"
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
                        SET income_source=%s, amount=%s, category_id=%s, income_date=%s, note=%s
                        WHERE income_id=%s AND user_id=%s
                    """,
                    (body.income_source, body.amount, body.category_id, body.income_date, body.note, id, auth.id)
                )
                
                await conn.commit()
                return {"message": "Income updated successfully", "income_id": id}
        except HTTPException:
            raise
        except Exception as e:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=f"Internal server error: {e}")
        
@app.post("/categories/suggest")
async def suggest_category(
    body: SuggestCategoryBody,
    auth: TokenPayload = Depends(require_auth)
):
    if not body.item_name or body.item_name.strip() == "":
        return {"category_name": "Others", "category_id": CATEGORY_MAP["Others"]}
    
    result = await predict_item_category(body.item_name)
    return result

@app.get("/api/users/profile")
async def get_user_profile(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    sql = """
        SELECT 
            u.email, u.username, u.full_name,
            (SELECT COALESCE(SUM(amount), 0) FROM income_transactions WHERE user_id = u.user_id) AS total_income,
            (SELECT COALESCE(SUM(total_amount), 0) FROM expense_transactions WHERE user_id = u.user_id) AS total_expense
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
                "balance": current_balance
            }
                        
@app.post("/users/fcm-token")
async def update_fcm_token(
    body: FCMTokenBody,
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        try:
            async with conn.cursor() as cur:
                await conn.begin()
                
                # อัปเดต fcm_token ให้กับ user ที่กำลังล็อกอินอยู่
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
        
@app.post("/debug/test-notification")
async def test_notification(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    """
    API เส้นนี้ใช้สำหรับทดสอบยิงแจ้งเตือนเข้าเครื่องตัวเอง
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            # 1. ดึง FCM Token ของ User คนที่กำลังเรียก API นี้
            await cur.execute("SELECT fcm_token FROM users WHERE user_id = %s", (auth.id,))
            user = await cur.fetchone()
            
            if not user or not user.get("fcm_token"):
                raise HTTPException(
                    status_code=404, 
                    detail="ไม่พบ FCM Token ในระบบ กรุณาเปิดแอป Flutter เพื่อรายงานตัวก่อน"
                )
            
            # 2. ลองส่งแจ้งเตือน
            success = await asyncio.to_thread(
                send_push_notification,
                token=user["fcm_token"],
                title="🚀 SlipTrack Test",
                body=f"ยินดีด้วย! ระบบแจ้งเตือนของคุณเชื่อมต่อกับ FastAPI สำเร็จแล้วเมื่อเวลา {datetime.now(TZ).strftime('%H:%M:%S')}"
            )
            
            if success:
                return {"status": "success", "message": "Notification sent!", "token_used": user["fcm_token"][:15] + "..."}
            else:
                raise HTTPException(status_code=500, detail="ส่งแจ้งเตือนไม่สำเร็จ ตรวจสอบ Server Log")
            
async def check_and_notify_budget(user_id: int, category_id: int, db_pool: aiomysql.Pool):
    """
    ฟังก์ชันตรวจสอบงบประมาณและส่งแจ้งเตือนหากเกินเกณฑ์
    """

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            # 1. ดึงข้อมูล fcm_token และการตั้งค่า warning
            await cur.execute("""
                SELECT u.fcm_token, b.warning_enabled, b.warning_percentage, b.overspending_enabled 
                FROM users u
                LEFT JOIN budget b ON u.user_id = b.user_id
                WHERE u.user_id = %s
            """, (user_id,))
            user_config = await cur.fetchone()

            # ถ้าไม่เปิดแจ้งเตือน หรือไม่มี Token ก็ไม่ต้องทำต่อ
            if not user_config or not user_config['fcm_token'] or not user_config['warning_enabled']:
                return

            # 2. ดึงงบประมาณ (Limit) ของหมวดหมู่นี้
            await cur.execute("""
                SELECT amount FROM expense_budgets 
                WHERE user_id = %s AND category_id = %s AND month = %s AND year = %s
            """, (user_id, category_id, body.month, body.year))
            budget_row = await cur.fetchone()
            
            if not budget_row or budget_row['amount'] <= 0:
                return
            
            limit = float(budget_row['amount'])

            # 3. ดึงยอดใช้จ่ายรวมของหมวดหมู่นี้ในเดือนปัจจุบัน
            await cur.execute("""
                SELECT SUM(ei.total_price) as total_spent
                FROM expense_items ei
                JOIN expense_transactions et ON ei.transaction_id = et.transaction_id
                WHERE et.user_id = %s AND ei.category_id = %s 
                AND MONTH(et.receipt_date) = %s AND YEAR(et.receipt_date) = %s
            """, (user_id, category_id, body.month, body.year))
            spent_row = await cur.fetchone()
            
            spent = float(spent_row['total_spent'] or 0)
            warning_limit = limit * (user_config['warning_percentage'] / 100)

            # 4. ตรวจสอบเงื่อนไขและยิงแจ้งเตือน
            # กรณีที่ 1: เกินวงเงิน (Overspending)
            if spent > limit and user_config['overspending_enabled']:
                send_push_notification(
                    token=user_config['fcm_token'],
                    title="งบประมาณเกินแล้ว!",
                    body=f"คุณใช้จ่ายในหมวดหมู่ {category_id} ไป ฿{spent:,.2f} ซึ่งเกินงบ ฿{limit:,.2f} ที่ตั้งไว้"
                )
            # กรณีที่ 2: เกินเกณฑ์แจ้งเตือน (Warning)
            elif spent >= warning_limit:
                send_push_notification(
                    token=user_config['fcm_token'],
                    title="ระวัง! งบประมาณใกล้เต็ม",
                    body=f"ยอดใช้จ่ายหมวด {category_id} ถึง {user_config['warning_percentage']}% ของงบแล้ว (฿{spent:,.2f} / ฿{limit:,.2f})"
                )
                
@app.get("/notifications", response_model=List[NotificationOut])
async def get_notifications(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
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
            
            # แปลง 1/0 เป็น True/False
            for row in rows:
                row['is_read'] = bool(row['is_read'])
                
            return rows

@app.put("/notifications/{id}/read")
async def mark_notification_read(
    id: int = Path(...),
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
    async with db_pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "UPDATE notifications SET is_read = TRUE WHERE notification_id = %s AND user_id = %s",
                (id, auth.id)
            )
            await conn.commit()
            return {"message": "Marked as read"}
        
@app.get("/notifications/unread-count")
async def get_unread_cound(
    auth: TokenPayload = Depends(require_auth),
    db_pool: aiomysql.Pool = Depends(get_db_conn)
):
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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)