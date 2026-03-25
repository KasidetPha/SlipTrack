from google.genai import types
from core.config import gemini_client

# นำเข้าลิสต์คำศัพท์และ Mapping จากไฟล์ constants
from utils.constants import (
    CATEGORY_MAP, 
    FOOD_KWS, SUPPLY_KWS, TRANSPORT_KWS, BILL_KWS,
    SALARY_KWS, WAGE_KWS, GIFT_KWS, SALE_KWS
)

def auto_assign_category(item_name: str, ai_category: str) -> int:
    """
    ฟังก์ชันเช็ก Keyword ก่อน เพื่อหาว่าตรงกับหมวดหมู่พื้นฐานไหม
    ถ้าไม่ตรง ค่อยเชื่อ AI ที่ส่งค่ามา
    """
    name = item_name.lower()
    
    if any(k in name for k in FOOD_KWS): return CATEGORY_MAP["Food"]
    if any(k in name for k in SUPPLY_KWS): return CATEGORY_MAP["Shopping"]
    if any(k in name for k in TRANSPORT_KWS): return CATEGORY_MAP["Transportation"]
    if any(k in name for k in BILL_KWS): return CATEGORY_MAP["Bills"]
        
    return CATEGORY_MAP.get(ai_category, CATEGORY_MAP["Others"])
    
async def predict_item_category(item_name: str) -> dict:
    """
    ฟังก์ชันหลักสำหรับเดาหมวดหมู่รายจ่าย 
    สเต็ป 1: หาจาก Keyword 
    สเต็ป 2: ถ้าไม่เจอ ค่อยเรียกใช้ Gemini
    """
    name = item_name.lower()
    
    # ดักด้วย Keyword ก่อน (จัดการคำแปลกๆ หรือคำเฉพาะได้อยู่หมัดตรงนี้เลย)
    if any(k in name for k in FOOD_KWS): 
        return {"category_name": "Food", "category_id": CATEGORY_MAP["Food"]}
    if any(k in name for k in SUPPLY_KWS): 
        return {"category_name": "Shopping", "category_id": CATEGORY_MAP["Shopping"]}
    if any(k in name for k in TRANSPORT_KWS): 
        return {"category_name": "Transportation", "category_id": CATEGORY_MAP["Transportation"]}
    if any(k in name for k in BILL_KWS): 
        return {"category_name": "Bills", "category_id": CATEGORY_MAP["Bills"]}
        
    # ถ้าไม่เจอ Keyword ค่อยให้ Gemini ช่วยคิด
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
        
        # เช็กว่าคำตอบที่ AI ส่งมา อยู่ในหมวดหมู่ของเราจริงๆ
        if predicted_cat in CATEGORY_MAP:
            return {"category_name": predicted_cat, "category_id": CATEGORY_MAP[predicted_cat]}
    except Exception as e:
        print(f"Gemini prediction failed for '{item_name}': {e}")
        
    # ถ้า AI เดาพลาด หรือพัง ให้ตกไปอยู่หมวด Others
    return {"category_name": "Others", "category_id": CATEGORY_MAP["Others"]}


async def predict_income_category(source_name: str) -> dict:
    """
    ฟังก์ชันสำหรับเดาหมวดหมู่ฝั่งรายรับ
    ทำงานคล้ายกันคือเช็ก Keyword ก่อน แล้วค่อยพึ่ง AI
    """
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