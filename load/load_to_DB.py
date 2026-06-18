import os
import json
import glob
import psycopg2
from dotenv import load_dotenv
from pathlib import Path

load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

if not all([DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD]):
    print("ERROR: Missing database settings. Check your .env file.")
    exit()

print("Connecting to Postgres...")
conn = psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
)
cur = conn.cursor()

current_dir = Path.cwd()
print(current_dir)

# Change to a specific directory
os.chdir('../')

files = glob.glob("data/btc/raw/*.csv", recursive=True)
print("Found", len(files), "files to load")

if conn is not None:
    print("Connected")

conn.close()