import sys

try:
    from fastapi.testclient import TestClient
    try:
        from api import app
    except ImportError:
        from python_files.api import app

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

    # 3. Agent empty message validation
    res = client.post("/agent", json={"message": "   "})
    assert res.status_code == 400, f"Expected 400, got {res.status_code}"
    print("✓ POST /agent empty message validation PASSED")

    # 4. Agent tool execution test
    res = client.post("/agent", json={"message": "How much is the bag?"})
    assert res.status_code == 200, f"Expected 200, got {res.status_code}"
    data = res.json()
    assert data["success"] is True
    assert len(data["tools_used"]) >= 1, f"Expected tool to be called, got: {data['tools_used']}"
    assert "get_price(bag)" in data["tools_used"][0]
    print(f"✓ POST /agent tool test PASSED: {data['tools_used']}")

    # 5. Agent small talk (no tool) test
    res = client.post("/agent", json={"message": "Hi! What can you help with?"})
    assert res.status_code == 200, f"Expected 200, got {res.status_code}"
    data = res.json()
    assert data["success"] is True
    assert len(data["tools_used"]) == 0, f"Expected 0 tools, got: {data['tools_used']}"
    print("✓ POST /agent small talk (0 tools) PASSED")

    print("\nAll backend API tests (Summarizer + Shop Agent) PASSED successfully!")
except Exception as e:
    print(f"Test failed: {e}")
    sys.exit(1)
