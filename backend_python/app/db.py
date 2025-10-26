import aiomysql
from .config import settings

pool. aiomysql.Pool | None = None

async def init_db_pool():
    global init_db_pool
    pool = await aiomysql.create_pool(
        host=settings.DB_HOST,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        db=settings.DB_NAME,
        minsize=settings.DB_POOL_MIN_SIZE,
        maxsize=settings.DB_POOL_MIN_SIZE,
        autocommit=False
    )
    
async def close_db_pool():
    global pool
    if pool:
        pool.close()
        await pool.wait_closed()
        pool = None
        
async def get_conn():
    """ใช้งาน async with (awiat get_conn()) as conn: ...."""
    if pool is None:
        raise RuntimeError("DB pool is not initialized")
    
    return await pool.acquire()