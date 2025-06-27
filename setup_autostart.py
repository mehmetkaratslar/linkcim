import os
import sys
import subprocess
from pathlib import Path

def setup_autostart():
    """Windows başlangıcında API'yi otomatik başlatacak shortcut oluşturur"""
    
    current_dir = Path(__file__).parent.absolute()
    api_file = current_dir / "api.py"
    python_exe = sys.executable
    
    # Windows Startup klasörü
    startup_folder = Path(os.path.expandvars(r'%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup'))
    
    print("🚀 Linkcim Video API - Otomatik Başlatma Kurulumu")
    print("=" * 55)
    print(f"📂 Startup Klasörü: {startup_folder}")
    
    # Batch file oluştur
    batch_content = f'''@echo off
title Linkcim Video API
cd /d "{current_dir}"
echo 🎬 Linkcim Video API Başlatılıyor...
echo =======================================
"{python_exe}" "{api_file}"
pause
'''
    
    batch_file = current_dir / "start_linkcim_api.bat"
    
    try:
        # Batch dosyasını oluştur
        with open(batch_file, 'w', encoding='utf-8') as f:
            f.write(batch_content)
        
        print(f"✅ Batch dosyası oluşturuldu: {batch_file}")
        
        # Startup klasöründe shortcut oluştur
        shortcut_path = startup_folder / "Linkcim Video API.bat"
        
        # Var olan shortcut'u sil
        if shortcut_path.exists():
            shortcut_path.unlink()
        
        # Yeni shortcut oluştur (basit copy)
        import shutil
        shutil.copy2(batch_file, shortcut_path)
        
        print(f"✅ Otomatik başlatma kuruldu: {shortcut_path}")
        print("\n🎯 Kurulum Tamamlandı!")
        print("📋 Bilgiler:")
        print("   - Windows açıldığında API otomatik başlayacak")
        print("   - API: http://localhost:8000")
        print("   - Logs: Terminalde görülebilir")
        print("\n🔧 Yönetim:")
        print(f"   - Kaldırmak için: {shortcut_path} dosyasını silin")
        print(f"   - Manuel başlatma: {batch_file}")
        
        return True
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

def remove_autostart():
    """Otomatik başlatmayı kaldırır"""
    startup_folder = Path(os.path.expandvars(r'%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup'))
    shortcut_path = startup_folder / "Linkcim Video API.bat"
    
    try:
        if shortcut_path.exists():
            shortcut_path.unlink()
            print("✅ Otomatik başlatma kaldırıldı!")
            return True
        else:
            print("ℹ️ Otomatik başlatma zaten yok")
            return True
            
    except Exception as e:
        print(f"❌ Hata: {e}")
        return False

if __name__ == "__main__":
    print("Linkcim Video API - Otomatik Başlatma")
    print("1. Otomatik başlatmayı kur")
    print("2. Otomatik başlatmayı kaldır")
    choice = input("Seçiminiz (1/2): ").strip()
    
    if choice == "1":
        setup_autostart()
    elif choice == "2":
        remove_autostart()
    else:
        print("Geçersiz seçim") 