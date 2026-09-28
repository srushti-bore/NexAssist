from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

router = APIRouter()

# Resolve static downloads directory (d:\NexAssist\backend\static\downloads)
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent.parent
STATIC_DIR = BACKEND_DIR / "static" / "downloads"


@router.get("/info")
async def get_download_info():
    """Get metadata and file availability for desktop and mobile downloads."""
    windows_path = STATIC_DIR / "NexAssist-Setup.exe"
    android_path = STATIC_DIR / "NexAssist-Android.apk"

    windows_size = windows_path.stat().st_size if windows_path.exists() else 0
    android_size = android_path.stat().st_size if android_path.exists() else 0

    return {
        "version": "1.0.0",
        "desktop": {
            "platform": "Windows 64-bit",
            "filename": "NexAssist-Setup.exe",
            "size_bytes": windows_size,
            "size_mb": round(windows_size / (1024 * 1024), 2),
            "available": windows_path.exists(),
            "download_path": "/api/v1/downloads/windows",
        },
        "mobile": {
            "platform": "Android",
            "filename": "NexAssist-Android.apk",
            "size_bytes": android_size,
            "size_mb": round(android_size / (1024 * 1024), 2),
            "available": android_path.exists(),
            "download_path": "/api/v1/downloads/android",
        },
    }


@router.get("/windows")
async def download_windows_installer():
    """Download NexAssist standalone desktop installer for Windows (.exe)."""
    windows_path = STATIC_DIR / "NexAssist-Setup.exe"
    if not windows_path.exists():
        raise HTTPException(
            status_code=404,
            detail={"code": "FILE_NOT_FOUND", "message": "Windows installer file is not available."},
        )

    return FileResponse(
        path=str(windows_path),
        filename="NexAssist-Setup.exe",
        media_type="application/vnd.microsoft.portable-executable",
    )


@router.get("/android")
async def download_android_apk():
    """Download NexAssist mobile package for Android (.apk)."""
    android_path = STATIC_DIR / "NexAssist-Android.apk"
    if not android_path.exists():
        raise HTTPException(
            status_code=404,
            detail={"code": "FILE_NOT_FOUND", "message": "Android APK file is not available."},
        )

    return FileResponse(
        path=str(android_path),
        filename="NexAssist-Android.apk",
        media_type="application/vnd.android.package-archive",
    )
