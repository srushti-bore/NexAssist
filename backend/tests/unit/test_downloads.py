from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)


def test_download_info_endpoint():
    response = client.get("/api/v1/downloads/info")
    assert response.status_code == 200
    data = response.json()
    assert "desktop" in data
    assert "mobile" in data
    assert data["desktop"]["filename"] == "NexAssist-Setup.exe"
    assert data["mobile"]["filename"] == "NexAssist-Android.apk"
    assert data["desktop"]["available"] is True
    assert data["mobile"]["available"] is True


def test_download_windows_endpoint():
    response = client.get("/api/v1/downloads/windows")
    assert response.status_code == 200
    assert response.headers.get("content-type") == "application/vnd.microsoft.portable-executable"
    assert "attachment" in response.headers.get("content-disposition", "")
    assert len(response.content) > 1000000  # Verify binary content is streamed


def test_download_android_endpoint():
    response = client.get("/api/v1/downloads/android")
    assert response.status_code == 200
    assert response.headers.get("content-type") == "application/vnd.android.package-archive"
    assert "attachment" in response.headers.get("content-disposition", "")
    assert len(response.content) > 1000000  # Verify binary content is streamed
