#!/usr/bin/env python3
"""
Linkcim Video Download API Başlatıcı
Bu script Python API'sini localhost:8000'de başlatır.
"""

import os
import sys
import subprocess
import time
import webbrowser
from pathlib import Path

def check_python_version():
    """Python sürümünü kontrol et"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 veya üzeri gerekli!")
        print(f"Mevcut sürüm: {sys.version}")
        return False
    print(f"✅ Python sürümü uygun: {sys.version}")
    return True

def install_requirements():
    """Gerekli paketleri yükle"""
    print("📦 Gerekli paketler kontrol ediliyor...")
    try:
        subprocess.check_call([
            sys.executable, "-m", "pip", "install", "-r", "requirements.txt"
        ])
        print("✅ Tüm paketler yüklendi")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Paket yükleme hatası: {e}")
        return False

def create_downloads_folder():
    """Downloads klasörünü oluştur"""
    downloads_dir = Path("downloads")
    downloads_dir.mkdir(exist_ok=True)
    print(f"📁 Downloads klasörü hazır: {downloads_dir.absolute()}")

def start_api():
    """API'yi başlat"""
    print("🚀 API başlatılıyor...")
    print("📍 URL: http://localhost:8000")
    print("🔑 API Key: 45541d717524a99df5f994bb9f6cbce825269852be079594b8e35f7752d6f1bd")
    print("📋 Swagger UI: http://localhost:8000/docs")
    print("\n" + "="*50)
    print("API ÇALIŞIYOR - FLUTTER UYGULAMASINI BAŞLATABİLİRSİNİZ!")
    print("Durdurmak için Ctrl+C basın")
    print("="*50 + "\n")
    
    try:
        subprocess.run([
            sys.executable, "-m", "uvicorn", 
            "api:app", 
            "--host", "0.0.0.0", 
            "--port", "8000", 
            "--reload"
        ])
    except KeyboardInterrupt:
        print("\n🛑 API durduruldu")

def main():
    """Ana fonksiyon"""
    print("🎬 Linkcim Video Download API")
    print("=" * 40)
    
    # Python sürümünü kontrol et
    if not check_python_version():
        return
    
    # Gerekli paketleri yükle
    if not install_requirements():
        return
    
    # Downloads klasörünü oluştur
    create_downloads_folder()
    
    # API'yi başlat
    start_api()

if __name__ == "__main__":
    main() 