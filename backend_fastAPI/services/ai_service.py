from google import genai
from google.genai import types
import aiomysql
from rapidfuzz import fuzz

from utils.constants import (
    CATEGORY_MAP,
    FOOD_KWS,
    SUPPLY_KWS,
    TRANSPORT_KWS,
    BILL_KWS,
)


def create_user_gemini_client(gemini_api_key: str):
    if not gemini_api_key or gemini_api_key.strip() == "":
        raise ValueError("Gemini API key is required")

    return genai.Client(api_key=gemini_api_key.strip())


def auto_assign_category(item_name: str, ai_category: str) -> int:
    """
    ใช้กับ OCR:
    เช็ก keyword ก่อน ถ้าไม่ตรงค่อยใช้หมวดหมู่ที่ AI ส่งกลับมา
    """
    name = item_name.lower()

    if any(k in name for k in FOOD_KWS):
        return CATEGORY_MAP["Food"]

    if any(k in name for k in SUPPLY_KWS):
        return CATEGORY_MAP["Shopping"]

    if any(k in name for k in TRANSPORT_KWS):
        return CATEGORY_MAP["Transportation"]

    if any(k in name for k in BILL_KWS):
        return CATEGORY_MAP["Bills"]

    return CATEGORY_MAP.get(ai_category, CATEGORY_MAP["Others"])


async def predict_item_category(
    item_name: str,
    available_categories: list | None = None,
    *,
    gemini_api_key: str
) -> dict:
    """
    ใช้สำหรับเดาหมวดหมู่รายจ่ายเท่านั้น
    รองรับ Dynamic Categories ของ user
    """
    name = item_name.lower()

    # 1) Keyword matching ก่อน เพื่อลดการเรียก AI
    if any(k in name for k in FOOD_KWS):
        return {"category_name": "Food"}

    if any(k in name for k in SUPPLY_KWS):
        return {"category_name": "Shopping"}

    if any(k in name for k in TRANSPORT_KWS):
        return {"category_name": "Transportation"}

    if any(k in name for k in BILL_KWS):
        return {"category_name": "Bills"}

    # 2) ถ้า keyword ไม่เจอ ค่อยใช้ Gemini
    if not available_categories:
        available_categories = list(CATEGORY_MAP.keys())

    categories_str = ", ".join([f'"{c}"' for c in available_categories])

    prompt = f"""
        You are a personal finance assistant.
        Classify the expense item: "{item_name}"

        CHOOSE ONLY ONE from this specific list: [{categories_str}]

        Rules:
        1. Reply ONLY with the exact name from the list.
        2. No explanations.
        3. No markdown.
        4. If unsure, pick "Others" if it exists in the list.
    """

    try:
        gemini_client = create_user_gemini_client(gemini_api_key)

        response = gemini_client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=0.0
            )
        )

        predicted_cat = response.text.strip().replace('"', "")

        if predicted_cat in available_categories:
            return {"category_name": predicted_cat}

        for cat in available_categories:
            if cat.lower() in predicted_cat.lower():
                return {"category_name": cat}

    except Exception as e:
        print(f"Gemini category prediction error: {e}")

    return {"category_name": "Others"}

def is_noise_receipt_item(name: str, price: float) -> bool:
    text = (name or "").strip().lower()
    
    summary_like_keywords = [
        "ชิ้น",
        "ยอด",
        "รวม",
        "สุทธิ",
    ]

    if any(k in text for k in summary_like_keywords) and price > 0:
        return True

    noise_keywords = [
        "ยอดสุทธิ",
        "รวมสุทธิ",
        "สุทธิ",
        "ทรูมันนี่",
        "wallet",
        "truemoney",
        "เงินสด",
        "ชำระ",
        "payment",
        "payatall",
        "all member",
        "point",
        "tid",
        "vat",
        "ภาษี",
        "ตราปั๊ม",
        "สมาชิก",
        "คะแนน",
        "ใบเสร็จ",
        "total",
        "cash",
        "vat included",
        "vat",
        "qr",
        "kbank",
        "trace",
        "batch",
        "ref no",
        "คะแนน",
        "ยอดเงินรวม",
        "ยอดเงินส่วนลด",
        "เงื่อนไขส่วนลด",
        "ชำระโดย",
        "ทอน",
    ]

    if price <= 3:
        return True

    return any(k.lower() in text for k in noise_keywords)

def fix_common_ocr_errors(name: str) -> str:
    fixes = {
        "สปอร์ตไรซ์": "พาสเจอร์ไรซ์",
        "พาสปอร์ตไรซ์": "พาสเจอร์ไรซ์",
        "นมรสมะลิสูง": "นมโปรตีนสูง",
        "รสมะลิสูง": "โปรตีนสูง",
        "ไม้ขาวเหลว": "ไม้ขาวเหลว",
        "ไมขาวเหลว": "ไมขาวเหลว",
    }

    for wrong, correct in fixes.items():
        if wrong in name:
            name = name.replace(wrong, correct)

    return name


def build_receipt_prompt(allowed_cats: str) -> str:
    return f"""
        You are a specialized Thai OCR API for retail receipts. You MUST extract data into a strict JSON format.

            ### CRITICAL EXTRACTION RULES:
            1. THAI LANGUAGE ACCURACY: Pay close attention to Thai characters, vowels, and tone marks. Read EXACTLY what is printed. DO NOT autocorrect or guess words if they are cut off.
            2. MULTI-LINE STRUCTURE: A single item often spans 2 or 3 lines (Name -> Barcode/Qty -> Total Price). You MUST combine these into ONE item object. The `name` MUST be extracted from Line 1.
            3. MERCHANT IDENTIFICATION: Identify the store name at the very top of the receipt.
            4. DISCOUNTS: Promotional lines (e.g., "ส่วนลด", "ท้ายบิล") are NOT items. Aggregate them into the `discount` field. Do not include discounts in the items array.
            5. IGNORE NOISE: Ignore phone numbers, tax IDs, points, and membership details.
            6. ITEM ROW ONLY:
                Only include real purchased products.
                Do NOT include payment methods, totals, subtotal, VAT, member points, stamps, transaction IDs, receipt numbers, phone numbers, or service/payment lines.
            7. 7-ELEVEN RULE:
                For 7-Eleven receipts, product rows usually appear before total/payment lines.
                Ignore lines such as:
                - ยอดสุทธิ
                - รวมสุทธิ
                - เงินสด
                - ทรูมันนี่วอลเล็ท
                - TrueMoney
                - All Member
                - Point
                - TID
                - R#
                - ตราปั๊ม
                - ภาษี
                - VAT
                - PayAtAll
            8. STAMP / OVERLAP RULE:
                Ignore red stamps, logos, handwritten marks, QR codes, and overlapping marks.
                Extract only clearly printed receipt text.
                Do not create items from stamp text or unclear overlapped text.
            9. TOTAL RULE:
                The final total_amount must be the payable amount after discount.
                For Makro/CP Axtra receipts, use the amount near TOTAL or payment line.
                Do not use subtotal before discount as total_amount.
            10. PRODUCT NAME RULE:
                Read Thai product names exactly from the product name line.
                Do not replace food words with unrelated objects.
                For example, "ไข่ขาวเหลวพาสเจอร์ไรซ์" must not become "ไม้กวาด".
            11. STRICT OCR RULE:
                DO NOT guess, invent, or replace product words with unrelated words.
                If text is unclear, keep the closest visible characters.
                Preserve visible Thai keywords exactly.
            12. KEYWORD PRESERVATION RULE:
                If a product line contains food keywords such as:
                "นม", "โปรตีน", "ช็อกโกแลต", "ไข่", "ข้าว", "กล้วย"
                these keywords MUST be preserved in the item name.
                Do not transform them into unrelated words such as "ไม้กวาด" or "มาร์เกรต".

            ### OUTPUT STRUCTURE:
            {{
              "merchant_name": "string (Store Name)",
              "receipt_date": "YYYY-MM-DD",
              "subtotal": float,
              "discount": float,
              "total_amount": float,
              "items": [
                {{
                    "name": "Only real purchased product name, not payment/summary text",
                    "unit_price": float,
                    "qty": int,
                    "total_item_price": float,
                    "category": "Must be one of: [{allowed_cats}]"
                }}
              ]
            }}

            Go. Extract the data now.
            CRITICAL: Return ONLY the raw JSON. Do not write any markdown code blocks. Do not write any explanations.
        """
    
def call_gemini_receipt_ocr(client, prompt, image):
    response = client.models.generate_content(
        model="gemini-2.5-flash-lite",
        contents=[prompt, image],
        config=types.GenerateContentConfig(
            temperature=0.0,
            response_mime_type="application/json"
        )
    )

    return response.text.strip()

async def get_ocr_corrections(db_pool):
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("SELECT wrong_text, correct_text FROM ocr_corrections")
            return await cur.fetchall()
        
async def apply_ocr_corrections(name: str, db_pool, threshold: int = 70):
    corrections = await get_ocr_corrections(db_pool)

    used = []
    fixed_name = name

    for row in corrections:
        wrong = row["wrong_text"]
        correct = row["correct_text"]

        if wrong in fixed_name:
            fixed_name = fixed_name.replace(wrong, correct)
            used.append(wrong)
            continue

        score = fuzz.partial_ratio(wrong, fixed_name)

        print("FUZZ:", wrong, "vs", fixed_name, "=", score)

        if score >= threshold:
            fixed_name = fixed_name.replace(wrong, correct)
            used.append(wrong)

    if used:
        async with db_pool.acquire() as conn:
            async with conn.cursor() as cur:
                await cur.executemany("""
                    UPDATE ocr_corrections
                    SET use_count = use_count + 1
                    WHERE wrong_text = %s
                """, [(w,) for w in used])
            await conn.commit()

    return fixed_name