# 🌐 Linkcim Video API - Bulut Sunucu Deployment

Bu rehber, API'nizi bulut sunucuya kurmak için farklı seçenekler sunuyor.

## 🚀 1. Railway (Önerilen - Ücretsiz)

### Adımlar:
1. [Railway.app](https://railway.app) hesabı açın
2. GitHub'a bu projeyi yükleyin
3. Railway'de "Deploy from GitHub" seçin
4. Environment variables ekleyin:
   - `PORT=8000`
   - Diğer gerekli env'ler

### Dockerfile (Railway için):
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Avantajlar:
- ✅ Ücretsiz plan (500 saat/ay)
- ✅ Otomatik SSL
- ✅ Kolay deployment
- ✅ Custom domain

---

## 🔥 2. Heroku (Kolay)

### Gerekli Dosyalar:

**Procfile:**
```
web: uvicorn api:app --host 0.0.0.0 --port $PORT
```

**runtime.txt:**
```
python-3.11.0
```

### Deployment:
```bash
# Heroku CLI kur
pip install heroku3

# Login
heroku login

# Uygulama oluştur
heroku create linkcim-video-api

# Deploy et
git push heroku main
```

---

## ⚡ 3. Vercel (Serverless)

### vercel.json:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "api.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "api.py"
    }
  ]
}
```

### Deployment:
```bash
npm i -g vercel
vercel
```

---

## 🐳 4. DigitalOcean Droplet

### 1. Droplet Oluştur:
- Ubuntu 22.04 LTS
- $5/ay plan yeterli

### 2. Sunucu Kurulumu:
```bash
# SSH ile bağlan
ssh root@your-server-ip

# Sistem güncelle
apt update && apt upgrade -y

# Python ve dependencies
apt install python3 python3-pip nginx -y

# Proje klonla
git clone https://github.com/yourusername/linkcim.git
cd linkcim

# Dependencies kur
pip3 install -r requirements.txt

# Systemd servis oluştur
nano /etc/systemd/system/linkcim-api.service
```

### 3. Systemd Servis:
```ini
[Unit]
Description=Linkcim Video API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/linkcim
ExecStart=/usr/bin/python3 api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 4. Nginx Reverse Proxy:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 5. Servisi Başlat:
```bash
systemctl enable linkcim-api
systemctl start linkcim-api
systemctl enable nginx
systemctl start nginx
```

---

## 💻 5. Flutter App Güncellemesi

API URL'sini bulut sunucuya yönlendirin:

```dart
// lib/config/api_config.dart
class ApiConfig {
  // Yerel geliştirme
  static const String LOCAL_BASE_URL = 'http://localhost:8000';
  
  // Bulut sunucu
  static const String CLOUD_BASE_URL = 'https://your-app.railway.app';
  
  // Aktif URL
  static const String BASE_URL = CLOUD_BASE_URL; // Bunu değiştirin
}
```

---

## 🎯 Önerilen Çözüm

**Yeni başlayanlar için**: Railway.app
- Ücretsiz
- Kolay kurulum
- Otomatik deployment

**Profesyonel kullanım**: DigitalOcean
- Tam kontrol
- Daha ucuz (uzun vadede)
- Özelleştirilebilir

---

## 🔧 Local Geliştirme vs Bulut

| Özellik | Local | Bulut |
|---------|-------|--------|
| Maliyet | Ücretsiz | $0-5/ay |
| Erişim | Sadece ev | Her yerden |
| Performans | Yüksek | Orta |
| Güvenilirlik | Düşük | Yüksek |
| Kurulum | Kolay | Orta |

**Sonuç**: Bulut sunucu kullanmanızı öneriyorum! 🌟 