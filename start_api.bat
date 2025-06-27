@echo off
echo 🎬 Linkcim Video Download API - Windows Başlatıcı
echo ===============================================

:: Python sürümünü kontrol et
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python bulunamadı! Python 3.8+ yükleyin.
    echo 📥 İndirme linki: https://python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python bulundu

:: Gerekli paketleri yükle
echo 📦 Gerekli paketler kontrol ediliyor...
pip install -r requirements.txt
if errorlevel 1 (
    echo ❌ Paket yükleme hatası!
    pause
    exit /b 1
)

echo ✅ Tüm paketler yüklendi

:: Downloads klasörünü oluştur
if not exist "downloads" mkdir downloads
echo 📁 Downloads klasörü hazır

:: API'yi başlat
echo.
echo 🚀 API başlatılıyor...
echo 📍 URL: http://localhost:8000
echo 🔑 API Key: 45541d717524a99df5f994bb9f6cbce825269852be079594b8e35f7752d6f1bd
echo 📋 Swagger UI: http://localhost:8000/docs
echo.
echo ================================================
echo API ÇALIŞIYOR - FLUTTER UYGULAMASINI BAŞLATABİLİRSİNİZ!
echo Durdurmak için Ctrl+C basın
echo ================================================
echo.

python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload

pause 