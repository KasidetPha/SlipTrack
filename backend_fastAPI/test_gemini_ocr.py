import os
import json
from dotenv import load_dotenv
from PIL import Image

# Import ตัวใหม่ตามมาตรฐานล่าสุดของ Google
from google import genai
from google.genai import types

# 1. โหลด Environment Variables จากไฟล์ .env
load_dotenv()

# 2. ตั้งค่า Client ตัวใหม่ของ Gemini
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("ไม่พบ GEMINI_API_KEY ในไฟล์ .env ครับ")

client = genai.Client(api_key=api_key)

def test_receipt_scanner(image_path: str):
    # 3. โหลดรูปภาพ
    try:
        img = Image.open(image_path)
    except FileNotFoundError:
        print(f"❌ ไม่พบไฟล์รูปภาพที่: {image_path}")
        return

# 4. เตรียม Prompt (ขั้นเด็ดขาด: บังคับให้อ่านทีละตัวอักษร ห้ามเดา)
    allowed_cats = '"Food", "Transport", "Utilities", "Shopping", "Others"'
    prompt = f"""
    You are a STRICT OCR data entry machine. Your ONLY job is to transcribe the EXACT Thai characters from the receipt image.
    
    CRITICAL RULES:
    1. ZERO HALLUCINATION: Transcribe character-by-character. DO NOT use autocorrect. DO NOT guess brand names.
    2. If the text says "ซันชายน์นมโปรตีนสูงช็อกโกแลต340X3", you MUST output exactly that. Do not change it to "ชินนามอนมินิ" or "นมรสจืด". Read the actual pixels.
    3. Extract the full merchant name (e.g., "CP Axtra PCL พงษ์เพชร").
    4. Look for discount conditions (e.g., "เงื่อนไขส่วนลด"). If found, put the amount as a POSITIVE number in 'discount'. If no discount, 0.0.
    5. Validate math: total_amount MUST equal (subtotal - discount).
    6. Return ONLY valid JSON. 'category' MUST be one of: [{allowed_cats}].
    7. Date format must be YYYY-MM-DD.

    Target JSON Structure:
    {{
      "merchant_name": "string",
      "receipt_date": "string",
      "subtotal": float,
      "discount": float,
      "total_amount": float,
      "items": [
        {{
          "name": "string (EXACT printed text, NO autocomplete)",
          "unit_price": float,
          "qty": int,
          "total_item_price": float,
          "category": "string"
        }}
      ]
    }}
    """
        
    print(f"กำลังส่งภาพ '{image_path}' ให้ Gemini ประมวลผลผ่าน SDK ใหม่... ⏳")
    
    # 5. เรียกใช้งาน API ด้วยรูปแบบใหม่
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash-lite',
            contents=[prompt, img],
            config=types.GenerateContentConfig(
                response_mime_type="application/json"
            )
        )
        
        # 6. แปลงผลลัพธ์เป็น JSON และแสดงผล
        result_json = json.loads(response.text)
        print("\n✅ สแกนสำเร็จ! ผลลัพธ์ JSON ที่ได้:\n")
        print(json.dumps(result_json, indent=4, ensure_ascii=False))
        
    except Exception as e:
        print(f"\n❌ เกิดข้อผิดพลาดในการประมวลผล: {e}")

if __name__ == "__main__":
    # ใช้ไฟล์ makro_receipt.jpg ของคุณได้เลยครับ
    TEST_IMAGE = "makro_receipt.jpg" 
    test_receipt_scanner(TEST_IMAGE)