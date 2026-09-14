-- Schema for the demo API. The app also creates this automatically on
-- startup (see init_db() in app.py / wsgi.py), so this file is mainly for
-- reference and for manual/RDS bootstrap if you prefer not to let the app
-- create its own schema in production.

CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
