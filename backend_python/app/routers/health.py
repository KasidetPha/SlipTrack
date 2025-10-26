from fastapi import APIRouter

router = APIRouter(prefix="", tags=["health"])

@router.get('/')
async def root():
    return {"msg": "Hello FastAPI"}