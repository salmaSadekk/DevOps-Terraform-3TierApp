"""
Unit tests for the API. The DB layer (get_conn/put_conn) is mocked so these
run in CI (GitHub Actions) without needing a live Postgres instance.

For a real end-to-end check against an actual database, use
docker-compose.yml in the project root and run tests against it manually,
or add a separate 'integration' CI job that spins up a postgres service.
"""

import pytest
import app as app_module


class FakeCursor:
    def __init__(self, fetchone_result=None, fetchall_result=None, rowcount=0):
        self._fetchone_result = fetchone_result
        self._fetchall_result = fetchall_result or []
        self.rowcount = rowcount
        self.executed = []

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def execute(self, query, params=None):
        self.executed.append((query, params))

    def fetchone(self):
        return self._fetchone_result

    def fetchall(self):
        return self._fetchall_result


class FakeConn:
    def __init__(self, cursor):
        self._cursor = cursor
        self.committed = False
        self.rolled_back = False

    def cursor(self, cursor_factory=None):
        return self._cursor

    def commit(self):
        self.committed = True

    def rollback(self):
        self.rolled_back = True


@pytest.fixture
def client():
    app_module.app.config["TESTING"] = True
    return app_module.app.test_client()


def test_health_ok(monkeypatch, client):
    fake_cursor = FakeCursor(fetchone_result=(1,))
    fake_conn = FakeConn(fake_cursor)
    monkeypatch.setattr(app_module, "get_conn", lambda: fake_conn)
    monkeypatch.setattr(app_module, "put_conn", lambda c: None)

    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_health_db_down(monkeypatch, client):
    def broken_get_conn():
        raise RuntimeError("db unreachable")

    monkeypatch.setattr(app_module, "get_conn", broken_get_conn)

    resp = client.get("/health")
    assert resp.status_code == 503
    assert resp.get_json()["status"] == "degraded"


def test_list_items_empty(monkeypatch, client):
    fake_cursor = FakeCursor(fetchall_result=[])
    fake_conn = FakeConn(fake_cursor)
    monkeypatch.setattr(app_module, "get_conn", lambda: fake_conn)
    monkeypatch.setattr(app_module, "put_conn", lambda c: None)

    resp = client.get("/api/items")
    assert resp.status_code == 200
    assert resp.get_json() == []


def test_create_item_requires_name(client):
    resp = client.post("/api/items", json={"description": "no name here"})
    assert resp.status_code == 400


def test_create_item_success(monkeypatch, client):
    fake_row = {"id": 1, "name": "widget", "description": "a widget", "created_at": "2026-01-01T00:00:00Z"}
    fake_cursor = FakeCursor(fetchone_result=fake_row)
    fake_conn = FakeConn(fake_cursor)
    monkeypatch.setattr(app_module, "get_conn", lambda: fake_conn)
    monkeypatch.setattr(app_module, "put_conn", lambda c: None)

    resp = client.post("/api/items", json={"name": "widget", "description": "a widget"})
    assert resp.status_code == 201
    assert resp.get_json()["name"] == "widget"
    assert fake_conn.committed is True


def test_get_item_not_found(monkeypatch, client):
    fake_cursor = FakeCursor(fetchone_result=None)
    fake_conn = FakeConn(fake_cursor)
    monkeypatch.setattr(app_module, "get_conn", lambda: fake_conn)
    monkeypatch.setattr(app_module, "put_conn", lambda c: None)

    resp = client.get("/api/items/999")
    assert resp.status_code == 404


def test_delete_item_not_found(monkeypatch, client):
    fake_cursor = FakeCursor(rowcount=0)
    fake_conn = FakeConn(fake_cursor)
    monkeypatch.setattr(app_module, "get_conn", lambda: fake_conn)
    monkeypatch.setattr(app_module, "put_conn", lambda c: None)

    resp = client.delete("/api/items/999")
    assert resp.status_code == 404


def test_delete_item_success(monkeypatch, client):
    fake_cursor = FakeCursor(rowcount=1)
    fake_conn = FakeConn(fake_cursor)
    monkeypatch.setattr(app_module, "get_conn", lambda: fake_conn)
    monkeypatch.setattr(app_module, "put_conn", lambda c: None)

    resp = client.delete("/api/items/1")
    assert resp.status_code == 204
    assert fake_conn.committed is True
