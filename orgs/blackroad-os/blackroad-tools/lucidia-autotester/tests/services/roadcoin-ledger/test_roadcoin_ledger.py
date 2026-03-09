def test_read_path(env_client, services):
    service = next(s for s in services if s["slug"] == "roadcoin-ledger")
    resp = env_client.get(service["endpoints"]["read"], headers={"Authorization": "Bearer test"})
    assert resp.status_code == 200
