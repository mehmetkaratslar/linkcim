FROM python:3.11-slim

# Sistem paketlerini güncelle ve gerekli araçları kur
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Çalışma dizinini ayarla
WORKDIR /app

# Requirements dosyasını kopyala ve bağımlılıkları kur
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyalarını kopyala
COPY . .

# Downloads klasörünü oluştur
RUN mkdir -p downloads

# Port'u açığa çıkar
EXPOSE 8000

# Uygulamayı başlat
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "$PORT"] 