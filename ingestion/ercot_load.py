import os
import time

import psycopg2
from psycopg2 import sql
from psycopg2.extras import execute_values


def insert_rows(conn, table, columns, rows, conflict=None):
    if not rows:
        return

    query = sql.SQL("INSERT INTO {table} ({columns}) VALUES %s").format(
        table=sql.Identifier(table),
        columns=sql.SQL(", ").join(map(sql.Identifier, columns)),
    )

    if conflict:
        conflict_cols = [conflict] if isinstance(conflict, str) else conflict
        query = sql.SQL("{base} ON CONFLICT ({conflict}) DO NOTHING").format(
            base=query,
            conflict=sql.SQL(", ").join(map(sql.Identifier, conflict_cols)),
        )

    with conn.cursor() as cur:
        execute_values(cur, query, rows)
    conn.commit()


connection = None
cursor = None

try:
    for attempt in range(1, 4):
        try:
            connection = psycopg2.connect(
                dbname=os.getenv("POSTGRES_DB"),
                user=os.getenv("POSTGRES_USER"),
                password= os.getenv("POSTGRES_PASSWORD"),
                host=os.getenv("POSTGRES_HOST"),
                port=os.getenv("POSTGRES_PORT")
            )
            print("Successfully connected to the database!")
            break
        except psycopg2.OperationalError as e:
            print(f"Connection attempt {attempt} failed: {e}")
            if attempt == 3:
                raise
            time.sleep(2)

    cursor = connection.cursor()
finally:
    # 5. Clean up and close database objects
    if cursor:
        cursor.close()
    if connection:
        connection.close()
        print("PostgreSQL connection is safely closed.")
