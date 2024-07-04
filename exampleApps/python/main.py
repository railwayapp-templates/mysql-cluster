from fastapi import FastAPI, HTTPException
from aiomysql import create_pool
import os
from typing import List, Dict
import random
import string
import asyncio

app = FastAPI()

MYSQL_ROUTER_HOST = os.getenv("MYSQL_ROUTER_HOST")
MYSQL_ROUTER_PORT = int(os.getenv("MYSQL_ROUTER_PORT", 6446))
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DB = os.getenv("MYSQL_DB")

pool = None

async def init_db():
    global pool
    pool = await create_pool(
        host=MYSQL_ROUTER_HOST,
        port=MYSQL_ROUTER_PORT,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        db=MYSQL_DB,
        autocommit=True,
    )
    # Create the database if it doesn't exist
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(f"CREATE DATABASE IF NOT EXISTS {MYSQL_DB}")
            await cur.execute(f"USE {MYSQL_DB}")

@app.on_event("startup")
async def startup():
    await init_db()
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("""
                CREATE TABLE IF NOT EXISTS items (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    `key` VARCHAR(255) NOT NULL,
                    `value` VARCHAR(255) NOT NULL
                )
            """)

def generate_random_string(length=8):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

@app.get("/")
async def set_item():
    random_key = generate_random_string()
    random_value = generate_random_string()
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("""
                INSERT INTO items (`key`, `value`) VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)
            """, (random_key, random_value))
            return {"status": "success", "key": random_key, "value": random_value}

@app.get("/get", response_model=List[Dict[str, str]])
async def get_all_items():
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("SELECT `key`, `value` FROM items")
            result = await cur.fetchall()
            items = [{"key": row[0], "value": row[1]} for row in result]
            return items

@app.get("/health")
async def healthcheck():
    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("SELECT `key`, `value` FROM items ORDER BY RAND() LIMIT 1")
            result = await cur.fetchone()
            if result:
                return {"status": "success", "document": {"key": result[0], "value": result[1]}}
            else:
                raise HTTPException(status_code=500, detail="No documents found in the collection")
