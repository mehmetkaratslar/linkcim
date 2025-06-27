# ----------------------------
# linkcim  •  Dockerfile
# ----------------------------
# 1) Temel imaj: Python 3.11 (slim)
FROM python:3.11-slim

# 2) Sistem paketlerini güncelle + ffmpeg ve curl kur
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    curl \
  && rm -rf /var/lib/apt/lists/*

# 3) Çalışma dizini
WORKDIR /app

# 4) Requirements -> bağımlılıkların kurulumu
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5) Uygulama kaynak kodu
COPY . .

# 6) downloads klasörü (video indirme çıktıları vb.)
RUN mkdir -p downloads

# 7) Railway genelde PORT env verir; biz de 8000'i expose ediyoruz
EXPOSE 8000

# 8) Uygulama başlangıç komutu
#    - "sh -c" ile kabuk açıyoruz, böylece $PORT genişleyebiliyor
#    - ${PORT:-8000} → PORT tanımlı değilse 8000 kullan
CMD ["sh", "-c", "uvicorn api:app --host 0.0.0.0 --port ${PORT:-8000}"]
