def test_health_check(client):
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["status"] == "healthy"
    assert "checks" in data
    assert "qr_storage" in data["checks"]
    assert "firebase" in data["checks"]


def test_readiness_check(client):
    response = client.get("/api/v1/health/ready")

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["status"] == "ready"
    assert "checks" in data
    assert data["checks"]["database"]["available"] is True
    assert data["checks"]["qr_storage"]["available"] is True


def test_liveness_check(client):
    response = client.get("/api/v1/health/live")

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["status"] == "alive"