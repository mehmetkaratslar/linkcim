import os
import sys
import subprocess
import time
from pathlib import Path

def install_as_service():
    """Windows servis olarak Python API'yi kurar"""
    
    # Gerekli dizinler
    current_dir = Path(__file__).parent.absolute()
    api_file = current_dir / "api.py"
    
    # Python executable path
    python_exe = sys.executable
    
    print("🔧 Linkcim Video API - Windows Servisi Kurulumu")
    print("=" * 50)
    
    # NSSM (Non-Sucking Service Manager) gerekli
    nssm_path = current_dir / "nssm.exe"
    
    if not nssm_path.exists():
        print("❌ NSSM bulunamadı. İndiriliyor...")
        try:
            # NSSM indirme
            import urllib.request
            import zipfile
            
            nssm_url = "https://nssm.cc/release/nssm-2.24.zip"
            zip_path = current_dir / "nssm.zip"
            
            print("📦 NSSM indiriliyor...")
            urllib.request.urlretrieve(nssm_url, zip_path)
            
            print("📂 NSSM çıkarılıyor...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(current_dir)
            
            # Doğru NSSM dosyasını kopyala
            import shutil
            nssm_source = current_dir / "nssm-2.24" / "win64" / "nssm.exe"
            shutil.copy2(nssm_source, nssm_path)
            
            # Temizlik
            zip_path.unlink()
            shutil.rmtree(current_dir / "nssm-2.24")
            
            print("✅ NSSM başarıyla indirildi")
            
        except Exception as e:
            print(f"❌ NSSM indirme hatası: {e}")
            print("Manuel indirme: https://nssm.cc/download")
            return False
    
    # Servisi kur
    service_name = "LinkcimVideoAPI"
    
    try:
        print(f"🔧 '{service_name}' servisi kuruluyor...")
        
        # Mevcut servisi durdur ve kaldır
        subprocess.run([str(nssm_path), "stop", service_name], 
                      capture_output=True, text=True)
        subprocess.run([str(nssm_path), "remove", service_name, "confirm"], 
                      capture_output=True, text=True)
        
        # Yeni servisi kur
        result = subprocess.run([
            str(nssm_path), "install", service_name,
            python_exe, str(api_file)
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ Servis kurulum hatası: {result.stderr}")
            return False
        
        # Servis ayarları
        subprocess.run([str(nssm_path), "set", service_name, "DisplayName", 
                       "Linkcim Video Download API"], capture_output=True)
        subprocess.run([str(nssm_path), "set", service_name, "Description", 
                       "Video indirme API servisi"], capture_output=True)
        subprocess.run([str(nssm_path), "set", service_name, "AppDirectory", 
                       str(current_dir)], capture_output=True)
        subprocess.run([str(nssm_path), "set", service_name, "Start", 
                       "SERVICE_AUTO_START"], capture_output=True)
        
        # Servisi başlat
        result = subprocess.run([str(nssm_path), "start", service_name], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Servis başarıyla kuruldu ve başlatıldı!")
            print(f"📍 Servis Adı: {service_name}")
            print("🔧 Servis Yönetimi:")
            print("   - Durdur: net stop LinkcimVideoAPI")
            print("   - Başlat: net start LinkcimVideoAPI")
            print("   - Kaldır: nssm remove LinkcimVideoAPI confirm")
            return True
        else:
            print(f"❌ Servis başlatma hatası: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Servis kurulum hatası: {e}")
        return False

def uninstall_service():
    """Servisi kaldırır"""
    current_dir = Path(__file__).parent.absolute()
    nssm_path = current_dir / "nssm.exe"
    service_name = "LinkcimVideoAPI"
    
    if not nssm_path.exists():
        print("❌ NSSM bulunamadı")
        return False
    
    try:
        print(f"🗑️ '{service_name}' servisi kaldırılıyor...")
        
        subprocess.run([str(nssm_path), "stop", service_name], 
                      capture_output=True, text=True)
        result = subprocess.run([str(nssm_path), "remove", service_name, "confirm"], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Servis başarıyla kaldırıldı!")
            return True
        else:
            print(f"❌ Servis kaldırma hatası: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "uninstall":
        uninstall_service()
    else:
        print("Linkcim Video API - Servis Kurulumu")
        print("1. Windows servisi olarak kur")
        print("2. Servisi kaldır")
        choice = input("Seçiminiz (1/2): ").strip()
        
        if choice == "1":
            install_as_service()
        elif choice == "2":
            uninstall_service()
        else:
            print("Geçersiz seçim") 