import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# นำเข้าฟังก์ชันจัดการ Database จากโฟลเดอร์ core
from core.database import init_db_pool, close_db_pool

# นำเข้า Router ทั้งหมดที่เราแยกไว้
from routers import auth, users, categories, budgets, receipts

# ==========================================
# Lifespan Events (การจัดการตอนแอปเปิด-ปิด)
# ==========================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    # สิ่งที่จะทำตอนเซิร์ฟเวอร์เพิ่งรันขึ้นมา
    print("Connecting to Database...")
    await init_db_pool()
    yield
    
    # สิ่งที่จะทำตอนปิดเซิร์ฟเวอร์
    print("Closing Database...")
    await close_db_pool()

# ==========================================
# Application Setup
# ==========================================
app = FastAPI(
    title="SlipTrack FastAPI", 
    description="ระบบ Backend สำหรับจัดการรายรับ-รายจ่ายและ OCR ใบเสร็จแบบ Modular",
    version="2.0.0", 
    lifespan=lifespan
)

# การตั้งค่า CORS เพื่ออนุญาตให้ Frontend (เช่น Flutter ของเรา) เรียก API ได้
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

# ==========================================
# Include Routers (ประกอบร่าง API)
# ==========================================
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(categories.router)
app.include_router(budgets.router)
app.include_router(receipts.router)

# ==========================================
# Root Endpoint (เส้นพื้นฐาน)
# ==========================================
@app.get('/', tags=["Root"])
async def root():
    """เส้นทางเริ่มต้น ไว้เช็กว่าเซิร์ฟเวอร์รันอยู่ปกติไหม"""
    return {
        "msg": "hello fastAPI on SlipTrack V.2 (Modular Architecture) **linux"
    }

# สำหรับรันเซิร์ฟเวอร์ตอน Development
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)