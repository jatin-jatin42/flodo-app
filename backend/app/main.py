from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from contextlib import asynccontextmanager
from .routers import tasks

import asyncio

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize DB schema with retries
    max_retries = 5
    for i in range(max_retries):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            print("Database connected and schema initialized!")
            break
        except Exception as e:
            if i == max_retries - 1:
                raise e
            print(f"Database not ready ({e}), retrying... ({i+1}/{max_retries})")
            await asyncio.sleep(2)
    yield

app = FastAPI(title="Task Management API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(tasks.router)

@app.get("/")
async def root():
    return {"message": "API is running"}
