def test_health(env_client, services):
    for svc in services:
        resp = env_client.get(svc["endpoints"]["health"])
        data = resp.json()
        assert resp.status_code == 200
        assert data.get("status") == "ok"
