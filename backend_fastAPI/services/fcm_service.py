import aiomysql
from firebase_admin import messaging

def send_push_notification(token: str, title: str, body: str) -> bool:
    """
    ฟังก์ชันพื้นฐานสำหรับยิงแจ้งเตือนไปยังแอปพลิเคชัน
    รับ Token ของเครื่องเป้าหมาย, หัวข้อ และเนื้อหา
    """
    if not token:
        print("ไม่มี Token ไม่สามารถส่งแจ้งเตือนได้")
        return False

    try:
        # สร้างรูปแบบข้อความที่ Firebase เข้าใจ
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            token=token,
        )

        # สั่งยิงข้อความผ่าน Firebase Admin SDK
        response = messaging.send(message)
        print(f"ส่งแจ้งเตือนสำเร็จ! Message ID: {response}")
        return True
    except Exception as e:
        print(f"ส่งแจ้งเตือนไม่สำเร็จ: {e}")
        return False


async def check_and_notify_budget(user_id: int, category_id: int, month: int, year: int, db_pool: aiomysql.Pool):
    """
    ฟังก์ชันตรวจสอบงบประมาณและส่งแจ้งเตือนหากเกินเกณฑ์
    (มักจะถูกเรียกใช้งานแบบ Background Task ตอนที่มีรายจ่ายใหม่เข้ามา)
    """
    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            
            # 1. ดึงข้อมูล Token ของผู้ใช้ และการตั้งค่าว่าอนุญาตให้แจ้งเตือนไหม
            await cur.execute("""
                SELECT u.fcm_token, b.warning_enabled, b.warning_percentage, b.overspending_enabled 
                FROM users u
                LEFT JOIN budget b ON u.user_id = b.user_id
                WHERE u.user_id = %s
            """, (user_id,))
            user_config = await cur.fetchone()

            # ถ้าผู้ใช้ไม่ได้เปิดการแจ้งเตือน หรือไม่มี Token ก็จบการทำงานทันที
            if not user_config or not user_config['fcm_token'] or not user_config['warning_enabled']:
                return

            # 2. ดึงลิมิตงบประมาณที่ผู้ใช้ตั้งไว้ สำหรับหมวดหมู่นั้นๆ ในเดือน/ปี นี้
            await cur.execute("""
                SELECT amount FROM expense_budgets 
                WHERE user_id = %s AND category_id = %s AND month = %s AND year = %s
            """, (user_id, category_id, month, year))
            budget_row = await cur.fetchone()
            
            # ถ้าไม่ได้ตั้งงบไว้ (เป็น 0 หรือไม่มีข้อมูล) ก็จบการทำงาน
            if not budget_row or budget_row['amount'] <= 0:
                return
            
            limit = float(budget_row['amount'])

            # 3. คำนวณยอดใช้จ่าย "รวมทั้งหมด" ของหมวดหมู่นี้ในเดือนปัจจุบัน
            await cur.execute("""
                SELECT SUM(ei.total_price) as total_spent
                FROM expense_items ei
                JOIN expense_transactions et ON ei.transaction_id = et.transaction_id
                WHERE et.user_id = %s AND ei.category_id = %s 
                AND MONTH(et.receipt_date) = %s AND YEAR(et.receipt_date) = %s
            """, (user_id, category_id, month, year))
            spent_row = await cur.fetchone()
            
            spent = float(spent_row['total_spent'] or 0)
            warning_limit = limit * (user_config['warning_percentage'] / 100)

            # 4. ตรวจสอบเงื่อนไขและยิงแจ้งเตือนกลับไปยังแอป
            
            # กรณีที่ 1: ใช้จ่ายเกินวงเงินที่ตั้งไว้แล้ว (Overspending)
            if spent > limit and user_config['overspending_enabled']:
                send_push_notification(
                    token=user_config['fcm_token'],
                    title="งบประมาณเกินแล้ว!",
                    body=f"คุณใช้จ่ายในหมวดหมู่ {category_id} ไป ฿{spent:,.2f} ซึ่งเกินงบ ฿{limit:,.2f} ที่ตั้งไว้"
                )
                
            # กรณีที่ 2: ใช้จ่ายถึงจุดที่ต้องเตือน (Warning) เช่น ตั้งไว้ 80% ของงบ
            elif spent >= warning_limit:
                send_push_notification(
                    token=user_config['fcm_token'],
                    title="ระวัง! งบประมาณใกล้เต็ม",
                    body=f"ยอดใช้จ่ายหมวด {category_id} ถึง {user_config['warning_percentage']}% ของงบแล้ว (฿{spent:,.2f} / ฿{limit:,.2f})"
                )