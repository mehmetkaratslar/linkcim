# Linkcim 🎬

**Linkcim** - Instagram, YouTube, TikTok ve Twitter videolarını AI destekli kategorilendirme ile yöneten güçlü Flutter uygulaması.

## ✨ Özellikler

- 🎯 **Multi-Platform Destek**: Instagram, YouTube, TikTok, Twitter
- 🤖 **AI Destekli Analiz**: OpenAI GPT-4o, Whisper ve Vision API entegrasyonu
- 📱 **Modern UI**: Güzel ve kullanıcı dostu arayüz
- 💾 **Yerel Veritabanı**: Hive ile hızlı veri saklama
- 🔍 **Gelişmiş Arama**: Platform, kategori ve yazar bazlı filtreleme
- 📥 **Video İndirme**: Tüm platformlardan video indirme desteği
- 🎵 **Ses Analizi**: Whisper API ile video ses içeriği analizi
- 👁️ **Görsel Analiz**: Vision API ile video thumbnail analizi

## 🚀 Kurulum

### Ön Gereksinimler

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / VS Code
- OpenAI API Anahtarı

### Adım 1: Projeyi Klonlayın

```bash
git clone https://github.com/mehmetkaratslar/linkcim.git
cd linkcim
```

### Adım 2: Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### Adım 3: API Konfigürasyonu

1. API config dosyasını oluşturun:
```bash
cp lib/config/api_config.example.dart lib/config/api_config.dart
```

2. `lib/config/api_config.dart` dosyasını açın ve OpenAI API anahtarınızı girin:
```dart
static const String openaiApiKey = 'sk-your-actual-api-key-here';
```

3. OpenAI API anahtarını [platform.openai.com/api-keys](https://platform.openai.com/api-keys) adresinden alabilirsiniz.

### Adım 4: Uygulamayı Çalıştırın

```bash
flutter run
```

## 📱 Kullanım

### Video Ekleme
1. Ana sayfada "+" butonuna tıklayın
2. Instagram, YouTube, TikTok veya Twitter video URL'sini yapıştırın
3. AI otomatik olarak videoyu analiz edecek ve kategorize edecek

### Video İndirme
- Video kartlarındaki yeşil "İndir" butonuna tıklayın
- İndirilen videolar "İndirilenler" sayfasından erişilebilir

### Arama ve Filtreleme
- Arama sayfasında platform ve yazar bazlı filtreleme yapabilirsiniz
- Kategorilere göre videoları gruplandırabilirsiniz

## 🏗️ Proje Yapısı

```
lib/
├── config/           # API konfigürasyonları
├── models/           # Veri modelleri
├── screens/          # Uygulama sayfaları
├── services/         # API ve veritabanı servisleri
├── utils/            # Yardımcı fonksiyonlar
└── widgets/          # Özel widget'lar
```

## 🔧 Teknolojiler

- **Framework**: Flutter 3.x
- **Veritabanı**: Hive (NoSQL)
- **AI Services**: OpenAI (GPT-4o, Whisper, Vision)
- **HTTP Client**: Dio
- **State Management**: Provider
- **Video Player**: Chewie
- **File Sharing**: Share Plus

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 🔒 Güvenlik

- API anahtarları asla repository'ye commit edilmemelidir
- `.gitignore` dosyası hassas bilgileri korur
- Tüm API çağrıları HTTPS üzerinden yapılır


---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!