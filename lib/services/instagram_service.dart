// Dosya Konumu: lib/services/instagram_service.dart

import 'package:dio/dio.dart';
import 'package:linkcim/utils/url_utils.dart';
import 'dart:convert';

class InstagramService {
  static final Dio _dio = Dio();
  static const bool debugMode = true;

  static void _debugPrint(String message) {
    if (debugMode) {
      print('🔍 [Instagram Service] $message');
    }
  }

  // 🎯 Ana Instagram metadata çekme fonksiyonu
  static Future<Map<String, dynamic>> getVideoMetadata(String url) async {
    try {
      _debugPrint('Instagram analizi başlatılıyor: $url');

      // URL'den temel bilgileri çıkar
      final username = _extractUsernameFromUrl(url) ?? '';
      final postType = UrlUtils.getPostType(url) ?? '';
      final postId = UrlUtils.extractPostId(url) ?? '';

      _debugPrint(
          'Username: $username, Post Type: $postType, Post ID: $postId');

      // Farklı yöntemleri sırayla dene
      Map<String, dynamic>? result;

      // Yöntem 1: Instagram oEmbed API
      result = await _tryOEmbedAPI(url);
      if (result != null && result['success'] == true) {
        _debugPrint('✅ oEmbed API başarılı');
        return _enrichMetadata(result, url, username, postType, postId);
      }

      // Yöntem 2: Instagram web sayfası scraping
      result = await _tryWebScraping(url);
      if (result != null && result['success'] == true) {
        _debugPrint('✅ Web scraping başarılı');
        return _enrichMetadata(result, url, username, postType, postId);
      }

      // Yöntem 3: Embed sayfası scraping
      result = await _tryEmbedScraping(url);
      if (result != null && result['success'] == true) {
        _debugPrint('✅ Embed scraping başarılı');
        return _enrichMetadata(result, url, username, postType, postId);
      }

      // Yöntem 4: Basit metadata oluştur
      _debugPrint('⚠️ Tüm yöntemler başarısız, basit metadata oluşturuluyor');
      return _createBasicMetadata(url, username, postType, postId);
    } catch (e) {
      _debugPrint('❌ Instagram metadata hatası: $e');
      return _createErrorMetadata(url, e.toString());
    }
  }

  // 📡 Instagram oEmbed API
  static Future<Map<String, dynamic>?> _tryOEmbedAPI(String url) async {
    try {
      _debugPrint('oEmbed API deneniyor...');
      final oembedUrl =
          'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(url)}';

      final response = await _dio.get(
        oembedUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json',
          },
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        return {
          'success': true,
          'title': data['title']?.toString() ?? '',
          'author': data['author_name']?.toString() ?? '',
          'author_url': data['author_url']?.toString() ?? '',
          'thumbnail': data['thumbnail_url']?.toString() ?? '',
          'width': data['thumbnail_width'] ?? 0,
          'height': data['thumbnail_height'] ?? 0,
          'html': data['html']?.toString() ?? '',
          'provider_name': data['provider_name']?.toString() ?? 'Instagram',
        };
      }
    } catch (e) {
      _debugPrint('oEmbed API hatası: $e');
    }
    return null;
  }

  // 🌐 Instagram web sayfası scraping
  static Future<Map<String, dynamic>?> _tryWebScraping(String url) async {
    try {
      _debugPrint('Web scraping deneniyor...');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
          },
          sendTimeout: Duration(seconds: 15),
          receiveTimeout: Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        final html = response.data.toString();

        // Meta tag'lerden bilgileri çıkar
        final title = _extractMetaContent(html, 'og:title') ??
            _extractMetaContent(html, 'twitter:title') ??
            _extractTitle(html) ??
            '';

        final description = _extractMetaContent(html, 'og:description') ??
            _extractMetaContent(html, 'twitter:description') ??
            _extractMetaContent(html, 'description') ??
            '';

        final image = _extractMetaContent(html, 'og:image') ??
            _extractMetaContent(html, 'twitter:image') ??
            '';

        // JSON-LD structured data'dan bilgileri çıkar
        final jsonLd = _extractJsonLd(html);

        // Instagram'a özel bilgileri çıkar
        final instagramData = _extractInstagramSpecificData(html);

        return {
          'success': true,
          'title': _cleanText(title),
          'description': _cleanText(description),
          'thumbnail': image,
          'json_ld': jsonLd,
          'instagram_data': instagramData,
          'hashtags': _extractHashtags(description),
        };
      }
    } catch (e) {
      _debugPrint('Web scraping hatası: $e');
    }
    return null;
  }

  // 📱 Embed sayfası scraping
  static Future<Map<String, dynamic>?> _tryEmbedScraping(String url) async {
    try {
      _debugPrint('Embed scraping deneniyor...');
      final embedUrl = UrlUtils.convertToEmbedUrl(url);

      final response = await _dio.get(
        embedUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final html = response.data.toString();

        // Embed sayfasından bilgileri çıkar
        final title = _extractMetaContent(html, 'og:title') ??
            _extractMetaContent(html, 'twitter:title') ??
            '';

        final thumbnail = _extractMetaContent(html, 'og:image') ??
            _extractMetaContent(html, 'twitter:image') ??
            '';

        return {
          'success': true,
          'title': _cleanText(title),
          'thumbnail': thumbnail,
        };
      }
    } catch (e) {
      _debugPrint('Embed scraping hatası: $e');
    }
    return null;
  }

  // 🔧 Yardımcı fonksiyonlar
  static String _extractUsernameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // instagram.com/username/p/... formatından username çıkar
      if (pathSegments.isNotEmpty) {
        final username = pathSegments[0];
        return username.replaceAll('@', '');
      }
    } catch (e) {
      _debugPrint('Username çıkarma hatası: $e');
    }
    return '';
  }

  static String? _extractMetaContent(String html, String property) {
    try {
      // Meta property için regex
      RegExp regExp = RegExp(
        '<meta[^>]*(?:property|name)=["\']${RegExp.escape(property)}["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      );

      Match? match = regExp.firstMatch(html);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  static String? _extractTitle(String html) {
    try {
      RegExp titleRegex =
          RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false);
      Match? match = titleRegex.firstMatch(html);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? _extractJsonLd(String html) {
    try {
      // JSON-LD script tag'ini bul
      int startIndex = html.indexOf('application/ld+json');
      if (startIndex != -1) {
        int scriptStart = html.indexOf('>', startIndex) + 1;
        int scriptEnd = html.indexOf('</script>', scriptStart);
        if (scriptEnd != -1) {
          final jsonStr = html.substring(scriptStart, scriptEnd).trim();
          if (jsonStr.isNotEmpty) {
            return jsonDecode(jsonStr) as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      _debugPrint('JSON-LD çıkarma hatası: $e');
    }
    return null;
  }

  static Map<String, dynamic> _extractInstagramSpecificData(String html) {
    try {
      // Instagram'a özel script tag'lerinden bilgi çıkar
      final Map<String, dynamic> data = {};

      // window._sharedData'dan bilgi çıkar
      RegExp sharedDataRegex = RegExp(
        r'window\._sharedData\s*=\s*({.*?});',
        caseSensitive: false,
        dotAll: true,
      );

      Match? match = sharedDataRegex.firstMatch(html);
      if (match != null) {
        try {
          final jsonStr = match.group(1);
          if (jsonStr != null) {
            final sharedData = jsonDecode(jsonStr);
            data['shared_data'] = sharedData;
          }
        } catch (e) {
          _debugPrint('SharedData parse hatası: $e');
        }
      }

      return data;
    } catch (e) {
      _debugPrint('Instagram specific data hatası: $e');
      return {};
    }
  }

  static List<String> _extractHashtags(String text) {
    try {
      RegExp hashtagRegex = RegExp(r'#\w+');
      return hashtagRegex
          .allMatches(text)
          .map((match) => match.group(0)!)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML taglarını kaldır
        .replaceAll(RegExp(r'\s+'), ' ') // Fazla boşlukları kaldır
        .replaceAll(RegExp(r'&[^;]+;'), '') // HTML entity'leri kaldır
        .trim();
  }

  // 📊 Metadata zenginleştirme
  static Map<String, dynamic> _enrichMetadata(
    Map<String, dynamic> baseData,
    String url,
    String username,
    String postType,
    String postId,
  ) {
    // Başlık iyileştirme
    String title = baseData['title']?.toString() ?? '';
    if (title.isEmpty || title == 'Instagram') {
      if (username.isNotEmpty) {
        title = '📷 @$username - Instagram $postType';
      } else {
        title = '📷 Instagram $postType';
      }
    }

    // Yazar bilgisi iyileştirme
    String author = baseData['author']?.toString() ?? '';
    if (author.isEmpty || author == 'Instagram') {
      if (username.isNotEmpty) {
        author = '@$username';
      } else {
        author = 'Instagram User';
      }
    }

    return {
      ...baseData,
      'title': title,
      'author': author,
      'author_username': username,
      'url': url,
      'post_id': postId,
      'post_type': postType,
      'platform': 'Instagram',
      'platform_icon': '📷',
      'estimated_thumbnail': UrlUtils.getThumbnailUrl(url),
      'embed_url': UrlUtils.convertToEmbedUrl(url),
      'short_url': UrlUtils.shortenUrl(url),
    };
  }

  // 📝 Basit metadata oluşturma
  static Map<String, dynamic> _createBasicMetadata(
    String url,
    String username,
    String postType,
    String postId,
  ) {
    final title = username.isNotEmpty
        ? '📷 @$username - Instagram $postType'
        : '📷 Instagram $postType';

    final author = username.isNotEmpty ? '@$username' : 'Instagram User';

    return {
      'success': true,
      'title': title,
      'description':
          'Instagram $postType${username.isNotEmpty ? ' by @$username' : ''}',
      'author': author,
      'author_username': username,
      'thumbnail': '',
      'url': url,
      'post_id': postId,
      'post_type': postType,
      'platform': 'Instagram',
      'platform_icon': '📷',
      'hashtags': [],
      'likes': 0,
      'comments': 0,
      'is_video': postType == 'reel' || postType == 'video',
    };
  }

  // ❌ Hata metadata oluşturma
  static Map<String, dynamic> _createErrorMetadata(String url, String error) {
    final postType = UrlUtils.getPostType(url) ?? '';
    final username = _extractUsernameFromUrl(url) ?? '';

    return {
      'success': false,
      'title': '📷 Instagram $postType',
      'description': 'Video bilgileri alınamadı',
      'author': username.isNotEmpty ? '@$username' : 'Instagram',
      'author_username': username,
      'thumbnail': '',
      'error': error,
      'url': url,
      'post_type': postType,
      'platform': 'Instagram',
      'platform_icon': '📷',
    };
  }

  // 🎯 Instagram oEmbed API (alternatif kullanım)
  static Future<Map<String, dynamic>> getOEmbedData(String url) async {
    try {
      final oembedUrl =
          'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(url)}';

      final response = await _dio.get(
        oembedUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        return {
          'success': true,
          'title': data['title']?.toString() ?? 'Instagram Video',
          'author': data['author_name']?.toString() ?? 'Instagram',
          'thumbnail': data['thumbnail_url']?.toString() ?? '',
          'width': data['thumbnail_width'] ?? 0,
          'height': data['thumbnail_height'] ?? 0,
          'html': data['html']?.toString() ?? '',
        };
      }
    } catch (e) {
      _debugPrint('Instagram oEmbed hatası: $e');
    }

    return {'success': false};
  }

  // ✅ Video erişilebilir mi kontrol et
  static Future<bool> isVideoAccessible(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 📊 Instagram post bilgilerini zenginleştir
  static Map<String, dynamic> enrichVideoData(String url, String title) {
    final postId = UrlUtils.extractPostId(url);
    final postType = UrlUtils.getPostType(url);
    final username = _extractUsernameFromUrl(url);
    final cleanUrl = UrlUtils.cleanUrl(url);

    return {
      'originalUrl': url,
      'cleanUrl': cleanUrl,
      'embedUrl': UrlUtils.convertToEmbedUrl(url),
      'postId': postId,
      'postType': postType,
      'username': username,
      'shortUrl': UrlUtils.shortenUrl(url),
      'estimatedThumbnail': UrlUtils.getThumbnailUrl(url),
    };
  }
}
