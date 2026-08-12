"""FastAPI application entry point."""
from fastapi import FastAPI

app = FastAPI(title="TG Support API")


@app.get("/health")
async def health():
    return {"status": "ok"}
