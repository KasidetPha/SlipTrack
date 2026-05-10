from fastapi import APIRouter, Depends, HTTPException, Path
import aiomysql

from core.database import get_db_conn
from dependencies.admin_auth import require_admin

router = APIRouter(
    prefix="/admin",
    tags=["Admin Dashboard"]
)


@router.get("/dashboard")
async def get_admin_dashboard(
    admin=Depends(require_admin),
    db=Depends(get_db_conn)
):
    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:

            # Total Users
            await cur.execute("""
                SELECT COUNT(*) AS total_users
                FROM users
            """)
            total_users = (await cur.fetchone())["total_users"]

            # Receipts Today
            await cur.execute("""
                SELECT COUNT(*) AS receipts_today
                FROM expense_transactions
                WHERE DATE(created_at) = CURDATE()
                AND source = "OCR"
                AND ocr_status = "success"
            """)

            receipts_today = (await cur.fetchone())["receipts_today"]

            # OCR Success Rate + Avg Duration
            await cur.execute("""
                SELECT
                    COUNT(*) AS total_ocr,
                    SUM(CASE WHEN ocr_status = 'success' THEN 1 ELSE 0 END) AS success_count,
                    AVG(ocr_duration_ms) AS avg_duration_ms
                FROM expense_transactions
                WHERE ocr_status IS NOT NULL
            """)
            ocr = await cur.fetchone()

            total_ocr = ocr["total_ocr"] or 0
            success_count = ocr["success_count"] or 0
            avg_duration_ms = ocr["avg_duration_ms"] or 0

            ocr_success_rate = (
                (success_count / total_ocr) * 100
                if total_ocr > 0
                else 0
            )

            avg_ocr_duration = avg_duration_ms / 1000

            # New Users This Month
            await cur.execute("""
                SELECT COUNT(*) AS new_users_this_month
                FROM users
                WHERE created_at >= DATE_FORMAT(NOW(), '%Y-%m-01')
            """)
            new_users_this_month = (await cur.fetchone())["new_users_this_month"]

            # OCR Scans This Month
            await cur.execute("""
                SELECT COUNT(*) AS ocr_scans_this_month
                FROM expense_transactions
                WHERE created_at >= DATE_FORMAT(NOW(), '%Y-%m-01')
                AND ocr_status IS NOT NULL
            """)
            ocr_scans_this_month = (await cur.fetchone())["ocr_scans_this_month"]

            # OCR Error Rate
            await cur.execute("""
                SELECT
                    COUNT(*) AS total_scans,
                    SUM(CASE WHEN ocr_status = 'failed' THEN 1 ELSE 0 END) AS failed_scans
                FROM expense_transactions
                WHERE ocr_status IS NOT NULL
            """)
            error = await cur.fetchone()

            total_scans = error["total_scans"] or 0
            failed_scans = error["failed_scans"] or 0

            ocr_error_rate = (
                (failed_scans / total_scans) * 100
                if total_scans > 0
                else 0
            )

            # Recent OCR Errors
            await cur.execute("""
                SELECT
                    transaction_id AS id,
                    ocr_error_code AS error_type,
                    ocr_error_message AS message,
                    created_at
                FROM expense_transactions
                WHERE ocr_status = 'failed'
                ORDER BY created_at DESC
                LIMIT 10
            """)
            
            recent_ocr_errors = await cur.fetchall()
            
            # OCR Daily Trend 7 days
            await cur.execute("""
                SELECT
                    DATE(created_at) AS date,
                    COUNT(*) AS total_scans,
                    SUM(CASE WHEN ocr_status = 'success' THEN 1 ELSE 0 END) AS success_scans,
                    SUM(CASE WHEN ocr_status = 'failed' THEN 1 ELSE 0 END) AS failed_scans
                FROM expense_transactions
                WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
                AND ocr_status IS NOT NULL
                GROUP BY DATE(created_at)
                ORDER BY DATE(created_at)
            """)
            ocr_daily_trend = await cur.fetchall()

    return {
        "kpis": {
            "receipts_today": receipts_today,
            "ocr_success_rate": round(ocr_success_rate, 2),
            "avg_ocr_duration": round(avg_ocr_duration, 2),
            "total_users": total_users,
        },
        "insights": {
            "new_users_this_month": new_users_this_month,
            "ocr_scans_this_month": ocr_scans_this_month,
            "ocr_error_rate": round(ocr_error_rate, 2),
            "ocr_error_count": failed_scans,
        },
        "recent_ocr_errors": recent_ocr_errors,
        "charts": {
            "ocr_daily_trend": ocr_daily_trend
        },
    }
    
@router.get("/ocr-corrections")
async def get_ocr_corrections(
    admin=Depends(require_admin),
    db=Depends(get_db_conn),
):
    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("""
                SELECT
                    correction_id,
                    wrong_text,
                    correct_text,
                    use_count,
                    created_at,
                    updated_at
                FROM ocr_corrections
                ORDER BY use_count DESC, updated_at DESC
            """)
            rows = await cur.fetchall()

    return rows


@router.delete("/ocr-corrections/{correction_id}")
async def delete_ocr_correction(
    correction_id: int = Path(..., ge=1),
    admin=Depends(require_admin),
    db=Depends(get_db_conn),
):
    async with db.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                """
                DELETE FROM ocr_corrections
                WHERE correction_id = %s
                """,
                (correction_id,),
            )
            await conn.commit()

            if cur.rowcount == 0:
                raise HTTPException(status_code=404, detail="OCR correction not found")

    return {"status": "success", "message": "OCR correction deleted"}

@router.get("/ocr-corrections/top")
async def get_top_ocr_corrections(
    admin=Depends(require_admin),
    db=Depends(get_db_conn),
):
    async with db.acquire() as conn:
        async with conn.cursor(aiomysql.DictCursor) as cur:
            await cur.execute("""
                SELECT
                    wrong_text,
                    correct_text,
                    use_count
                FROM ocr_corrections
                ORDER BY use_count DESC, updated_at DESC
                LIMIT 10
            """)
            rows = await cur.fetchall()

    return rows