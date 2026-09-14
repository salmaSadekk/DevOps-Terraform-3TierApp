# Demo 3-Tier API (application/ tier)

A deliberately minimal Flask REST API backed by PostgreSQL. It exists to
give the Terraform/Ansible/CI-CD parts of the DevOps project something
real to provision, configure, deploy, and monitor — the app itself is not
the point of the project, so it's kept small on purpose.

## Endpoints

| Method | Path              | Description                          |
|--------|-------------------|---------------------------------------|
| GET    | `/health`         | Liveness + DB connectivity check (used by ALB target group) |
| GET    | `/api/items`      | List all items                        |
| GET    | `/api/items/<id>` | Get a single item                     |
| POST   | `/api/items`      | Create an item (`{"name": "...", "description": "..."}`) |
| PUT    | `/api/items/<id>` | Update an item                        |
| DELETE | `/api/items/<id>` | Delete an item                        |

The `items` table is created automatically on startup (`init_db()`), so
there's no manual migration step for this simple schema. `schema.sql` is
kept for reference / manual RDS bootstrap if you'd rather not let the app
touch schema in production.

## Configuration

All config is via environment variables (12-factor style) — this is what
your Ansible role / systemd `EnvironmentFile` / Secrets Manager injection
should set:

| Variable      | Default        |
|---------------|----------------|
| `DB_HOST`     | `localhost`    |
| `DB_PORT`     | `5432`         |
| `DB_NAME`     | `appdb`        |
| `DB_USER`     | `appuser`      |
| `DB_PASSWORD` | `apppassword`  |
| `PORT`        | `5000`         |

## Run locally with Docker (fastest way to try it end to end)

```bash
docker compose up --build
curl http://localhost:5000/health
curl http://localhost:5000/api/items
curl -X POST http://localhost:5000/api/items \
  -H 'Content-Type: application/json' \
  -d '{"name": "first item", "description": "hello db"}'
```

## Run locally without Docker

Requires a local/reachable Postgres instance.

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements-dev.txt

export DB_HOST=localhost DB_NAME=appdb DB_USER=appuser DB_PASSWORD=apppassword

python app.py          # dev server on :5000
# or, closer to production:
gunicorn --bind 0.0.0.0:5000 --workers 3 wsgi:app
```

## Tests

Unit tests mock the database layer entirely, so they run in CI without a
live Postgres instance — this is what your GitHub Actions "automated
application tests" step should call:

```bash
pip install -r requirements-dev.txt
pytest -v
```

## Deploying on the actual EC2 instances (via Ansible)

1. Ansible copies `app.py`, `wsgi.py`, `requirements.txt` to e.g. `/opt/app`.
2. Ansible creates a venv and installs requirements.
3. Ansible templates `deploy/app.env.example` → `/etc/app/app.env` with
   real values (ideally pulled from Secrets Manager / SSM, not stored in
   the Ansible repo).
4. Ansible templates `deploy/app.service` → `/etc/systemd/system/app.service`.
5. Ansible runs `systemctl daemon-reload && systemctl enable --now app`,
   or `systemctl restart app` on redeploy.
6. The ALB target group health check hits `/health` on port 5000.

## Notes

- `/health` returns `200` only if the app can also reach the database —
  that's intentional, so the ALB pulls an instance out of rotation if its
  DB connectivity breaks, not just if the process is alive.
- The connection pool (`psycopg2.pool.SimpleConnectionPool`) avoids
  opening a new DB connection per request, which matters once this sits
  behind a load balancer and an Auto Scaling Group.
- This is intentionally not doing auth, rate limiting, pagination, or
  input validation beyond the basics — add those if you want to extend
  the portfolio project further, but they're not required for the
  infra/DevOps goals of this project.
