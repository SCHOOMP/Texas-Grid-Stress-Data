import os

import psycopg2
from psycopg2 import Error

connection = None
cursor = None

try:
    connection = psycopg2.connect(
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password= os.getenv("POSTGRES_PASSWORD"),
        host=os.getenv("POSTGRES_HOST"),
        port=os.getenv("POSTGRES_PORT")
    )
    print("Successfully connected to the database!")

    cursor = connection.cursor()
finally:
    # 5. Clean up and close database objects
    if cursor:
        cursor.close()
    if connection:
        connection.close()
        print("PostgreSQL connection is safely closed.")
