import aiomysql
from typing import Optional
from fastapi import HTTPException
from core.config import (
    MYSQL_HOST, MYSQL_PORT, MYSQL_USER, 
    MYSQL_PASSWORD, MYSQL_DB, POOL_MIN, POOL_MAX
)

# DB Pool
pool: Optional[aiomysql.Pool] = None

async def init_db_pool():
    global pool
    pool = await aiomysql.create_pool(
        host=MYSQL_HOST,
        port=MYSQL_PORT,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        db=MYSQL_DB,
        autocommit=False,
        minsize=POOL_MIN,
        maxsize=POOL_MAX,
        charset="utf8mb4"
    )

async def close_db_pool():
    global pool
    if pool:
        pool.close()
        await pool.wait_closed()

async def get_db_conn() -> aiomysql.Pool:
    if not pool:
        raise HTTPException(status_code=500, detail="DB pool is not ready")
    return pool