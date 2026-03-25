import os
from datetime import timedelta, timezone
from dotenv import load_dotenv
from google import genai
import firebase_admin
from firebase_admin import credentials

load_dotenv()

# --- Database Configuration ---
MYSQL_HOST = os.getenv("DB_HOST", "localhost")
MYSQL_USER = os.getenv("DB_USER", "root")
MYSQL_PASSWORD = os.getenv("DB_PASSWORD", "password1234")
MYSQL_DB = os.getenv("DB_NAME", "sliptrack")
MYSQL_PORT = int(os.getenv("DB_PORT", "3307"))

POOL_MIN = int(os.getenv("MYSQL_POOL_MIN", "1"))
POOL_MAX = int(os.getenv("MYSQL_POOL_MAX", "10"))

# --- JWT Configuration ---
JWT_SECRET = os.getenv("JWT_SECRET", "sliptrackVersion1")
JWT_EXPIRE_HOURS = int(os.getenv("JWT_EXPIRE_HOURS", "1"))
JWT_ALGORITHM = "HS256"

# --- Timezone ---
TZ = timezone(timedelta(hours=7))  # Asia/Bangkok

# --- Gemini Configuration ---
api_key = os.getenv("GEMINI_API_KEY", "")
if not api_key:
    raise ValueError("ไม่พบ GEMINI_API_KEY ในไฟล์ .env ครับ")
gemini_client = genai.Client(api_key=api_key)

# --- Firebase Configuration ---
# เช็กก่อนว่ามีแอปถูก initialize ไว้หรือยัง เพื่อป้องกัน Error ตอน Hot Reload
if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-key.json")
    firebase_admin.initialize_app(cred)