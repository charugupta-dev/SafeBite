import sys

try:
    from fastapi.testclient import TestClient
    from api import app

    client = TestClient(app)

    # 1. Health check
    res = client.get("/health")
    assert res.status_code == 200, f"Expected 200, got {res.status_code}"
    assert res.json() == {"status": "ok"}, f"Unexpected health response: {res.json()}"
    print("✓ GET /health PASSED")

    # 2. Empty URL validation
    res = client.post("/summarize", json={"url": "   "})
    assert res.status_code == 400, f"Expected 400, got {res.status_code}"
    print("✓ POST /summarize empty URL validation PASSED")

    print("All backend API basic tests PASSED successfully!")
except Exception as e:
    print(f"Test failed: {e}")
    sys.exit(1)
