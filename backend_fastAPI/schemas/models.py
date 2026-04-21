from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date

# ดึง Timezone จากไฟล์ตั้งค่ามาใช้กำหนดค่า Default ให้กับเวลาปัจจุบัน
from core.config import TZ

# ==========================================
# ข้อมูลสำหรับการยืนยันตัวตน (Authentication)
# ==========================================

class TokenPayload(BaseModel):
    """ข้อมูลที่ซ่อนอยู่ข้างใน JWT Token"""
    id: int
    email: str
    exp: int

class LoginBody(BaseModel):
    """ข้อมูลที่หน้าบ้านต้องส่งมาตอน Login"""
    email: str
    password: str

class FCMTokenBody(BaseModel):
    """ข้อมูล Token ของ Firebase สำหรับใช้ส่งแจ้งเตือน"""
    token: str


# ==========================================
# ตัวช่วยจัดการเรื่องเดือนและปี (Common Parameters)
# ==========================================

class MonthYearType(BaseModel):
    """ใช้กำหนดเดือน ปี และประเภท (เช่น net, income, expense)"""
    month: int = Field(..., ge=1, le=12)
    year: int
    type: Optional[str] = Field(default="net") 

class MonthYear(BaseModel):
    """ใช้กำหนดเดือน ปี แบบมีค่า Default เป็นเดือน/ปี ปัจจุบันอัตโนมัติ"""
    month: int = Field(default_factory=lambda: datetime.now(TZ).month, ge=1, le=12)
    year: int = Field(default_factory=lambda: datetime.now(TZ).year)


# ==========================================
# หมวดหมู่ (Categories)
# ==========================================

class CategorySummaryBody(BaseModel):
    month: int
    year: int

class CategoryMasterOut(BaseModel):
    """รูปแบบข้อมูลหมวดหมู่ตอนส่งกลับไปให้หน้าบ้าน"""
    category_id: int
    category_name: str
    entry_type: str
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None

class CreateCategoryBody(BaseModel):
    """ข้อมูลสำหรับสร้างหมวดหมู่ใหม่"""
    category_name: str
    entry_type: str  # 'expense' หรือ 'income'
    icon_name: Optional[str] = "category_rounded" 
    color_hex: Optional[str] = "FF64748B"

class SuggestCategoryBody(BaseModel):
    """ชื่อไอเทมที่ต้องการให้ AI ช่วยเดาหมวดหมู่"""
    item_name: str
    

# ==========================================
# รายรับ - รายจ่าย (Transactions)
# ==========================================

class ReceiptItemOut(BaseModel):
    """ข้อมูลรายการใช้จ่าย 1 รายการ แบบละเอียด (สำหรับโชว์ในหน้า Home)"""
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

class ReceiptItemInCategoryOut(BaseModel):
    """ข้อมูลรายการใช้จ่ายที่ถูกจัดกลุ่มในหมวดหมู่แล้ว"""
    item_id: int
    item_name: str
    quantity: float
    total_price: float
    category_id: int
    tx_date: date
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None

class UpdateItemBody(BaseModel):
    """ข้อมูลสำหรับอัปเดต/แก้ไขรายการใช้จ่าย"""
    item_name: str
    quantity: float
    total_price: float
    category_id: int
    receipt_date: Optional[datetime] = None
    note: Optional[str] = None

class CreateIncomeBody(BaseModel):
    amount: float
    source: str
    date: str
    note: Optional[str] = None
    category_name: str

class UpdateIncomeBody(BaseModel):
    income_source: str
    amount: float
    category_id: int
    income_date: date
    note: Optional[str] = None

class CreateExpenseBody(BaseModel):
    amount: float
    item_name: str
    store_name: Optional[str] = None
    date: date
    note: Optional[str] = None
    category_name: str

class MonthlyComparisionResponse(BaseModel):
    """ข้อมูลสำหรับเปรียบเทียบยอดรวมเดือนนี้กับเดือนที่แล้ว"""
    this_month: float
    last_month: float
    percent_change: float
    message: str = "ok"


# ==========================================
# การจัดการงบประมาณ (Budgets)
# ==========================================

class BudgetCategoryItemOut(BaseModel):
    """ข้อมูลลิมิตงบประมาณแต่ละหมวดหมู่"""
    category_id: int
    category_name: str
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None
    limit_amount: float

class BudgetGetResponse(BaseModel):
    """ข้อมูลหน้าสรุปงบประมาณทั้งหมด (รวมการตั้งค่าแจ้งเตือน)"""
    month: int
    year: int
    warning_enabled: bool
    warning_percentage: int
    overspending_enabled: bool
    items: List[BudgetCategoryItemOut]

class BudgetUpdateItem(BaseModel):
    category_id: int
    limit_amount: float 

class BudgetUpdateRequest(BaseModel):
    """ข้อมูลสำหรับการบันทึก/อัปเดตการตั้งค่างบประมาณ"""
    month: int
    year: int
    warning_enabled: bool = True
    warning_percentage: int = Field(80, ge=1, le=100)
    overspending_enabled: bool = True
    items: List[BudgetUpdateItem]


# ==========================================
# การสแกนใบเสร็จ (OCR Scanner)
# ==========================================

class BoundingBox(BaseModel):
    """พิกัดกรอบข้อความในรูปภาพ (ปัจจุบัน AI ส่งกลับมาเป็น 0 เพื่อป้องกันแครช)"""
    x: int
    y: int
    w: int
    h: int

class ReceiptItem(BaseModel):
    """รายการสินค้าแต่ละชิ้นที่ AI อ่านได้จากใบเสร็จ"""
    name: str
    price: float
    qty: int
    date: str
    category_id: Optional[int] = None
    bounding_box: Optional[BoundingBox] = None

class ScanResponse(BaseModel):
    """ผลลัพธ์ทั้งหมดที่ตอบกลับหลังจากสแกนใบเสร็จเสร็จสิ้น"""
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
    """ข้อมูลสำหรับกดยืนยันบันทึกใบเสร็จที่สแกนมาลง Database"""
    merchant_name: str
    receipt_date: date
    total_amount: float
    items: List[ReceiptItemBatchRequest]


# ==========================================
# การแจ้งเตือน (Notifications)
# ==========================================

class NotificationOut(BaseModel):
    """รูปแบบข้อมูลประวัติการแจ้งเตือนที่ส่งให้หน้าบ้าน"""
    notification_id: int
    title: str
    body: str
    notification_type: str
    is_read: bool
    created_at: datetime