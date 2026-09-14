"""
Simple 3-tier demo REST API.

Endpoints:
    GET    /health              -> liveness + DB connectivity check
    GET    /api/items           -> list all items
    GET    /api/items/<id>      -> get one item
    POST   /api/items           -> create an item
    PUT    /api/items/<id>      -> update an item
    DELETE /api/items/<id>      -> delete an item

Configuration is via environment variables (12-factor style), which is what
your Ansible role / systemd unit / ECS task def / etc. will inject:

    DB_HOST      (default: localhost)
    DB_PORT      (default: 5432)
    DB_NAME      (default: appdb)
    DB_USER      (default: appuser)
    DB_PASSWORD  (default: apppassword)
    PORT         (default: 5000)
"""

import os
import logging

from flask import Flask, jsonify, request
import psycopg2
import psycopg2.extras
from psycopg2 import pool

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
log = logging.getLogger("app")

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": os.environ.get("DB_PORT", "5432"),
    "dbname": os.environ.get("DB_NAME", "appdb"),
    "user": os.environ.get("DB_USER", "appuser"),
    "password": os.environ.get("DB_PASSWORD", "apppassword"),
}

app = Flask(__name__)

# A small connection pool rather than one connection per request. Created
# lazily so the app can still import/boot (e.g. for tests) even if the DB
# is not reachable yet.
_pool = None


def get_pool():
    global _pool
    if _pool is None:
        _pool = psycopg2.pool.SimpleConnectionPool(1, 10, **DB_CONFIG)
    return _pool


def get_conn():
    return get_pool().getconn()


def put_conn(conn):
    get_pool().putconn(conn)


def init_db():
    """Create the schema if it doesn't exist yet. Safe to call repeatedly."""
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS items (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
                """
            )
        conn.commit()
    finally:
        put_conn(conn)


@app.route("/health", methods=["GET"])
def health():
    """
    Liveness + readiness check.
    Returns 200 if the app is up and can reach the database,
    503 if the app is up but the database is not reachable.
    Used by the ALB target group health check.
    """
    try:
        conn = get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")
                cur.fetchone()
        finally:
            put_conn(conn)
        return jsonify(status="ok", db="ok"), 200
    except Exception as exc:  # noqa: BLE001
        log.error("Health check failed: %s", exc)
        return jsonify(status="degraded", db="unreachable"), 503


@app.route("/api/items", methods=["GET"])
def list_items():
    conn = get_conn()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute("SELECT id, name, description, created_at FROM items ORDER BY id;")
            rows = cur.fetchall()
        return jsonify([dict(r) for r in rows]), 200
    finally:
        put_conn(conn)


@app.route("/api/items/<int:item_id>", methods=["GET"])
def get_item(item_id):
    conn = get_conn()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT id, name, description, created_at FROM items WHERE id = %s;",
                (item_id,),
            )
            row = cur.fetchone()
        if row is None:
            return jsonify(error="item not found"), 404
        return jsonify(dict(row)), 200
    finally:
        put_conn(conn)


@app.route("/api/items", methods=["POST"])
def create_item():
    data = request.get_json(silent=True) or {}
    name = data.get("name")
    description = data.get("description")

    if not name:
        return jsonify(error="'name' is required"), 400

    conn = get_conn()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO items (name, description)
                VALUES (%s, %s)
                RETURNING id, name, description, created_at;
                """,
                (name, description),
            )
            row = cur.fetchone()
        conn.commit()
        return jsonify(dict(row)), 201
    finally:
        put_conn(conn)


@app.route("/api/items/<int:item_id>", methods=["PUT"])
def update_item(item_id):
    data = request.get_json(silent=True) or {}
    name = data.get("name")
    description = data.get("description")

    conn = get_conn()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                UPDATE items
                SET name = COALESCE(%s, name),
                    description = COALESCE(%s, description)
                WHERE id = %s
                RETURNING id, name, description, created_at;
                """,
                (name, description, item_id),
            )
            row = cur.fetchone()
        if row is None:
            conn.rollback()
            return jsonify(error="item not found"), 404
        conn.commit()
        return jsonify(dict(row)), 200
    finally:
        put_conn(conn)


@app.route("/api/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM items WHERE id = %s;", (item_id,))
            deleted = cur.rowcount
        conn.commit()
        if deleted == 0:
            return jsonify(error="item not found"), 404
        return "", 204
    finally:
        put_conn(conn)


if __name__ == "__main__":
    # Local/dev entrypoint only. In production this is served by gunicorn
    # (see wsgi.py) under systemd, per the ansible role.
    init_db()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))
