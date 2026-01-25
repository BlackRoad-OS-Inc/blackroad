def test_authz(env_client, services):
    svc = services[0]
    read = svc["endpoints"]["read"]
    resp = env_client.get(read)
    assert resp.status_code == 401
    resp = env_client.get(read, headers={"Authorization": "Bearer test"})
    assert resp.status_code == 200
