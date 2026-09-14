"""
Production WSGI entrypoint.

Run with gunicorn, e.g.:
    gunicorn --bind 0.0.0.0:5000 --workers 3 wsgi:app

This is what your systemd unit / Ansible role should invoke.
"""

from app import app, init_db

# Ensure the schema exists on process start (idempotent).
try:
    init_db()
except Exception:  # noqa: BLE001
    # Don't crash the whole process if the DB isn't reachable yet at boot;
    # /health will report it and your orchestration/monitoring should alert.
    pass

if __name__ == "__main__":
    app.run()
