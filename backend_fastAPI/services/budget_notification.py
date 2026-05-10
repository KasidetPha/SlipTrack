import aiomysql
import asyncio

from services.fcm_service import send_push_notification


async def check_and_notify_budget(
    user_id: int,
    category_id: int,
    month: int,
    year: int,
    db_pool: aiomysql.Pool
):
    print("RUNNING BUDGET CHECK:", user_id, category_id, month, year)

    async with db_pool.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:

            await cur.execute("""
                SELECT b.amount, c.category_name
                FROM expense_budgets b
                JOIN categories c ON b.category_id = c.category_id
                WHERE b.user_id = %s
                  AND b.category_id = %s
                  AND b.month = %s
                  AND b.year = %s
                LIMIT 1
            """, (user_id, category_id, month, year))

            budget = await cur.fetchone()
            print("BUDGET:", budget)

            if not budget:
                return

            budget_amount = float(budget["amount"])
            category_name = budget["category_name"]
            
            if budget_amount <= 0:
                print("SKIP BUDGET CHECK: budget amount is 0")
                return

            await cur.execute("""
                SELECT warning_enabled, warning_percentage, overspending_enabled
                FROM budget
                WHERE user_id = %s
                LIMIT 1
            """, (user_id,))

            setting = await cur.fetchone()

            warning_enabled = True
            warning_percentage = 80
            overspending_enabled = True

            if setting:
                warning_enabled = bool(setting["warning_enabled"])
                warning_percentage = int(setting["warning_percentage"])
                overspending_enabled = bool(setting["overspending_enabled"])

            await cur.execute("""
                SELECT COALESCE(SUM(ei.total_price), 0) AS total_spent
                FROM expense_transactions et
                JOIN expense_items ei ON et.transaction_id = ei.transaction_id
                WHERE et.user_id = %s
                  AND ei.category_id = %s
                  AND MONTH(et.receipt_date) = %s
                  AND YEAR(et.receipt_date) = %s
            """, (user_id, category_id, month, year))

            row = await cur.fetchone()
            total_spent = float(row["total_spent"])

            warning_limit = budget_amount * (warning_percentage / 100)

            print("TOTAL:", total_spent)
            print("BUDGET_AMOUNT:", budget_amount)
            print("WARNING_LIMIT:", warning_limit)

            notification_type = None
            title = ""
            body = ""

            if overspending_enabled and total_spent > budget_amount:
                notification_type = "budget_exceeded"
                title = f"งบ {category_name} เกินแล้ว"
                body = f"ใช้ไป {total_spent:.2f} / {budget_amount:.2f} บาท"

            elif warning_enabled and total_spent >= warning_limit:
                notification_type = "budget_warning"
                title = f"งบ {category_name} ใกล้เต็มแล้ว"
                body = f"ใช้ไป {total_spent:.2f} / {budget_amount:.2f} บาท"

            print("NOTIFICATION_TYPE:", notification_type)

            if not notification_type:
                return

            await cur.execute("""
                SELECT notification_id
                FROM notifications
                WHERE user_id = %s
                  AND notification_type = %s
                  AND MONTH(created_at) = %s
                  AND YEAR(created_at) = %s
                  AND title LIKE %s
                LIMIT 1
            """, (
                user_id,
                notification_type,
                month,
                year,
                f"%{category_name}%"
            ))

            exists = await cur.fetchone()
            print("EXISTS:", exists)

            if exists:
                return

            await cur.execute("""
                INSERT INTO notifications
                (user_id, title, body, notification_type, is_read, created_at, updated_at)
                VALUES (%s, %s, %s, %s, 0, NOW(), NOW())
            """, (user_id, title, body, notification_type))

            await cur.execute("""
                SELECT fcm_token
                FROM users
                WHERE user_id = %s
            """, (user_id,))

            user = await cur.fetchone()

            if user and user.get("fcm_token"):
                await asyncio.to_thread(
                    send_push_notification,
                    token=user["fcm_token"],
                    title=title,
                    body=body
                )

            await conn.commit()

            print("BUDGET NOTIFICATION CREATED")