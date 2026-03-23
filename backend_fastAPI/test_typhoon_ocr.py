import os
import json
from dotenv import load_dotenv
from google import genai
from google.genai import types

# 1. โหลด Environment Variables
load_dotenv()

# 2. นำเข้า Typhoon OCR (จากไฟล์ในโปรเจกต์ของคุณ)
try:
    from typhoon_ocr import ocr_document
except ImportError:
    print("❌ ไม่พบโมดูล 'typhoon_ocr' กรุณาตรวจสอบว่ามีไฟล์นี้อยู่")
    exit(1)

# 3. ตั้งค่า Gemini Client
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("ไม่พบ GEMINI_API_KEY ในไฟล์ .env ครับ")

client = genai.Client(api_key=api_key)

def test_pipeline(image_path: str):
    if not os.path.exists(image_path):
        print(f"❌ ไม่พบไฟล์รูปภาพที่: {image_path}")
        return

    try:
        # ==========================================
        # STAGE 1: Typhoon OCR (Extract Text from Image)
        # ==========================================
        print(f"1️⃣ [STAGE 1] กำลังส่งภาพให้ Typhoon OCR สกัดข้อความ... ⏳")
        raw_text = ocr_document(image_path)
        print("✅ สกัดข้อความดิบสำเร็จ!\n")
        
        # แสดงข้อความดิบให้ดูเล็กน้อยเพื่อเป็นหลักฐาน
        print("--- ข้อความดิบจาก Typhoon ---")
        print(raw_text[:200] + "...\n-----------------------------")

        # ==========================================
        # STAGE 2: Gemini (Parse Text to JSON)
        # ==========================================
        print(f"2️⃣ [STAGE 2] กำลังส่งข้อความดิบให้ Gemini จัดโครงสร้างเป็น JSON... ⏳")
        
        allowed_cats = '"Food", "Transport", "Utilities", "Shopping", "Others"'
        
        # สังเกตว่า Prompt เปลี่ยนไป! เราไม่ได้ส่งภาพ แต่ส่งเป็นตัวหนังสือแทน
        prompt = f"""
        You are an expert Data Extraction AI. I will provide you with raw text extracted from a Thai receipt using OCR.
        Your job is to parse this messy text and organize it into a strict JSON structure.
        
        CRITICAL RULES:
        1. Extract the full merchant name.
        2. Look for discount conditions. If found, put the amount as a POSITIVE number in 'discount'.
        3. Validate math: total_amount MUST equal (subtotal - discount).
        4. Return ONLY valid JSON. 'category' MUST be one of: [{allowed_cats}].
        5. Date format must be YYYY-MM-DD.

        Raw OCR Text from Receipt:
        \"\"\"
        {raw_text}
        \"\"\"

        Target JSON Structure:
        {{
          "merchant_name": "string",
          "receipt_date": "string",
          "subtotal": float,
          "discount": float,
          "total_amount": float,
          "items": [
            {{
              "name": "string (Cleaned item name)",
              "unit_price": float,
              "qty": int,
              "total_item_price": float,
              "category": "string"
            }}
          ]
        }}
        """

        # รัน Gemini 2.5 Flash โดยใช้เนื้อหาเป็น Text อย่างเดียว
        response = client.models.generate_content(
            model='gemini-2.5-flash-lite',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json"
            )
        )
        
        # แสดงผลลัพธ์
        result_json = json.loads(response.text)
        print("\n🎉 จัดโครงสร้างสำเร็จ! ผลลัพธ์ JSON ที่ได้:\n")
        print(json.dumps(result_json, indent=4, ensure_ascii=False))

    except Exception as e:
        print(f"\n❌ เกิดข้อผิดพลาดในระบบ: {e}")

if __name__ == "__main__":
    # ใช้ไฟล์เดิมของคุณทดสอบได้เลย
    TEST_IMAGE = "makro_receipt.jpg" 
    test_pipeline(TEST_IMAGE)