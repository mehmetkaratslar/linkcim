#!/bin/bash

echo "🚀 yt-dlp API Sunucu Kurulumu Başlatılıyor..."

# Sistem güncellemesi
echo "📦 Sistem güncelleniyor..."
sudo apt update && sudo apt upgrade -y

# Docker kurulumu
echo "🐳 Docker kuruluyor..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose kurulumu
echo "🔧 Docker Compose kuruluyor..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Proje dizini oluştur
echo "📁 Proje dizini oluşturuluyor..."
mkdir -p ~/ytdlp-api
cd ~/ytdlp-api

# Gerekli dizinleri oluştur
mkdir -p downloads logs ssl

# API Key oluştur
API_KEY=$(openssl rand -hex 32)
echo "🔑 API Key oluşturuldu: $API_KEY"

# .env dosyası oluştur
cat > .env << EOF
API_KEY=$API_KEY
PORT=8000
HOST=0.0.0.0
DEBUG=False
MAX_DOWNLOAD_SIZE=1073741824
DOWNLOAD_TIMEOUT=3600
CLEANUP_INTERVAL=86400
EOF

echo "✅ Kurulum tamamlandı!"
echo ""
echo "🔧 Sonraki adımlar:"
echo "1. docker-compose.yml dosyasındaki API_KEY'i güncelleyin"
echo "2. nginx.conf dosyasındaki domain'i güncelleyin"  
echo "3. docker-compose up -d ile başlatın"
echo ""
echo "🔑 API Key: $API_KEY"
echo "📝 Bu anahtarı güvenli bir yerde saklayın!" 