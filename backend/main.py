import os
import time
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI()

# Дозволяємо запити з фронтенду (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost:5432/notesdb")

def get_db_connection():
    # Проста спроба підключення до БД
    try:
        conn = psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def init_db():
    # Автоматичне створення таблиці при старті
    conn = None
    for _ in range(5):  # Чекаємо 5 секунд, поки БД запуститься
        conn = get_db_connection()
        if conn:
            break
        time.sleep(1)

    if conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS notes (
                    id SERIAL PRIMARY KEY,
                    content TEXT NOT NULL
                );
            """)
            conn.commit()
        conn.close()

@app.on_event("startup")
def startup():
    init_db()

class NoteCreate(BaseModel):
    content: str

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.get("/api/notes")
def get_notes():
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM notes ORDER BY id DESC;")
        notes = cur.fetchall()
    conn.close()
    return notes

@app.post("/api/notes")
def create_note(note: NoteCreate):
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    with conn.cursor() as cur:
        cur.execute("INSERT INTO notes (content) VALUES (%s) RETURNING *;", (note.content,))
        new_note = cur.fetchone()
        conn.commit()
    conn.close()
    return new_note
