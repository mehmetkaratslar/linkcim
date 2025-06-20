// Dosya Konumu: lib/utils/constants.dart

class AppConstants {
  // Renkler
  static const primaryColor = 0xFF2196F3;
  static const secondaryColor = 0xFF1976D2;
  static const backgroundColor = 0xFFF5F5F5;
  static const cardColor = 0xFFFFFFFF;
  static const textColor = 0xFF212121;
  static const hintColor = 0xFF757575;

  // Varsayılan kategoriler
  static const List<String> defaultCategories = [
    'Genel',
    'Yazılım',
    'Eğitim',
    'Eğlence',
    'Spor',
    'Yemek',
    'Müzik',
    'Sanat',
    'Bilim',
    'Teknoloji',
  ];

  // Popüler etiketler
  static const List<String> popularTags = [
    'flutter',
    'dart',
    'programlama',
    'api',
    'widget',
    'eğitim',
    'öğrenme',
    'tutorial',
    'ipucu',
    'teknoloji',
    'yazılım',
    'mobil',
    'uygulama',
    'geliştirme',
    'kodlama',
  ];

  // Text stilleri
  static const double titleFontSize = 18.0;
  static const double subtitleFontSize = 14.0;
  static const double bodyFontSize = 12.0;
  static const double captionFontSize = 10.0;

  // Bosluklar
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // 🎯 DESTEKLENEN PLATFORMLAR
  static const List<String> supportedPlatforms = [
    'Instagram',
    'YouTube',
    'TikTok',
    'Twitter',
  ];

  // 📱 Platform emojileri
  static const Map<String, String> platformEmojis = {
    'Instagram': '📸',
    'YouTube': '📺',
    'TikTok': '🎵',
    'Twitter': '🐦',
    'Genel': '🎬',
  };

  // 🌐 URL Validation - Tüm Platformlar
  static bool isValidVideoUrl(String url) {
    return isValidInstagramUrl(url) ||
        isValidYouTubeUrl(url) ||
        isValidTikTokUrl(url) ||
        isValidTwitterUrl(url);
  }

  // Instagram URL validation
  static bool isValidInstagramUrl(String url) {
    return url.contains('instagram.com') &&
        (url.contains('/p/') || url.contains('/reel/') || url.contains('/tv/'));
  }

  // YouTube URL validation
  static bool isValidYouTubeUrl(String url) {
    return (url.contains('youtube.com/watch') && url.contains('v=')) ||
        (url.contains('youtu.be/')) ||
        (url.contains('youtube.com/shorts/')) ||
        (url.contains('m.youtube.com/watch'));
  }

  // TikTok URL validation
  static bool isValidTikTokUrl(String url) {
    return (url.contains('tiktok.com') && url.contains('/video/')) ||
        (url.contains('vm.tiktok.com/')) ||
        (url.contains('tiktok.com/@') && url.contains('/video/'));
  }

  // Twitter/X URL validation
  static bool isValidTwitterUrl(String url) {
    return (url.contains('twitter.com') && url.contains('/status/')) ||
        (url.contains('x.com') && url.contains('/status/')) ||
        (url.contains('mobile.twitter.com') && url.contains('/status/'));
  }

  // 🔍 Platform Detection
  static String detectPlatform(String url) {
    if (isValidInstagramUrl(url)) return 'Instagram';
    if (isValidYouTubeUrl(url)) return 'YouTube';
    if (isValidTikTokUrl(url)) return 'TikTok';
    if (isValidTwitterUrl(url)) return 'Twitter';
    return 'Genel';
  }

  // 🎬 URL'den başlık çıkarma - Multi-Platform
  static String extractTitleFromUrl(String url) {
    try {
      String platform = detectPlatform(url);
      String emoji = platformEmojis[platform] ?? '🎬';

      switch (platform) {
        case 'Instagram':
          return _extractInstagramTitle(url, emoji);
        case 'YouTube':
          return _extractYouTubeTitle(url, emoji);
        case 'TikTok':
          return _extractTikTokTitle(url, emoji);
        case 'Twitter':
          return _extractTwitterTitle(url, emoji);
        default:
          return '$emoji Video Başlık';
      }
    } catch (e) {
      return '🎬 Video Başlık';
    }
  }

  // Instagram başlık çıkarma
  static String _extractInstagramTitle(String url, String emoji) {
    Uri uri = Uri.parse(url);
    String path = uri.path;

    RegExp regExp = RegExp(r'/(p|reel|tv)/([A-Za-z0-9_-]+)');
    Match? match = regExp.firstMatch(path);

    if (match != null) {
      String type = match.group(1)!;
      String id = match.group(2)!;

      switch (type) {
        case 'p':
          return '$emoji Instagram Gönderi';
        case 'reel':
          return '$emoji Instagram Reel';
        case 'tv':
          return '$emoji Instagram TV';
        default:
          return '$emoji Instagram Video';
      }
    }

    return '$emoji Instagram Video';
  }

  // YouTube başlık çıkarma
  static String _extractYouTubeTitle(String url, String emoji) {
    Uri uri = Uri.parse(url);

    // YouTube Shorts
    if (url.contains('/shorts/')) {
      return '$emoji YouTube Shorts';
    }

    // Normal YouTube video
    if (url.contains('youtube.com/watch') || url.contains('youtu.be/')) {
      // Video ID'yi al
      String? videoId;
      if (url.contains('youtu.be/')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      } else {
        videoId = uri.queryParameters['v'];
      }

      if (videoId != null && videoId.length >= 8) {
        return '$emoji YouTube Video';
      }
    }

    return '$emoji YouTube Video';
  }

  // TikTok başlık çıkarma
  static String _extractTikTokTitle(String url, String emoji) {
    if (url.contains('/video/')) {
      return '$emoji TikTok Video';
    }
    if (url.contains('vm.tiktok.com/')) {
      return '$emoji TikTok Video (Kısa Link)';
    }

    return '$emoji TikTok Video';
  }

  // Twitter başlık çıkarma
  static String _extractTwitterTitle(String url, String emoji) {
    try {
      Uri uri = Uri.parse(url);

      // Username çıkar
      String username = '';
      if (uri.pathSegments.isNotEmpty) {
        username = uri.pathSegments[0];
      }

      // Tweet ID çıkar
      String tweetId = '';
      final statusIndex = uri.pathSegments.indexOf('status');
      if (statusIndex != -1 && statusIndex + 1 < uri.pathSegments.length) {
        tweetId = uri.pathSegments[statusIndex + 1];
      }

      // X.com domain kontrolü
      if (url.contains('x.com')) {
        if (username.isNotEmpty) {
          return '$emoji X/Twitter (@$username)';
        }
        return '$emoji X/Twitter Gönderi';
      }

      // Twitter.com domain
      if (username.isNotEmpty) {
        return '$emoji Twitter (@$username)';
      }

      return '$emoji Twitter Gönderi';
    } catch (e) {
      return '$emoji Twitter Gönderi';
    }
  }

  // 🎨 Platform rengini al
  static int getPlatformColor(String platform) {
    switch (platform) {
      case 'Instagram':
        return 0xFFE4405F; // Instagram kırmızısı
      case 'YouTube':
        return 0xFFFF0000; // YouTube kırmızısı
      case 'TikTok':
        return 0xFF000000; // TikTok siyahı
      case 'Twitter':
        return 0xFF1DA1F2; // Twitter mavisi
      default:
        return primaryColor; // Varsayılan mavi
    }
  }
}
