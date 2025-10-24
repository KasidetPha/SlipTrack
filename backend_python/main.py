from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
# from app.db.pool import init_pool, close_pool
# from app.routers import receipts

def create_app() -> FastAPI:
    app = FastAPI(title="SlipTrack API (FastAPI modular)")
    
    app.add_middleware(
        CORSMiddleware,
        allow_origin=["*"],
        allow_credentials=True,
        allow_method=["*"],
        allow_headers=["*"]
    )