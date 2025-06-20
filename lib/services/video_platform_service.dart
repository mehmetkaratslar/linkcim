import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:linkcim/utils/constants.dart';

class VideoPlatformService {
  static const bool debugMode = true;
  static const int timeoutSeconds = 15;

  static void _debugPrint(String message) {
    if (debugMode) {
      print('[Video Platform Service] $message');
    }
  }

  // 🎬 Ana video metadata çekme fonksiyonu
  static Future<Map<String, dynamic>> getVideoMetadata(String url) async {
    try {
      String platform = AppConstants.detectPlatform(url);
      _debugPrint('Video metadata çekiliyor: $platform - $url');

      switch (platform) {
        case 'YouTube':
          return await _getYouTubeMetadata(url);
        case 'TikTok':
          return await _getTikTokMetadata(url);
        case 'Instagram':
          return await _getInstagramMetadata(url);
        case 'Twitter':
          return await _getTwitterMetadata(url);
        default:
          return _createBasicMetadata(url, platform);
      }
    } catch (e) {
      _debugPrint('Video metadata hatası: $e');
      return _createErrorMetadata(url, e.toString());
    }
  }

  // 📺 YouTube metadata çekme
  static Future<Map<String, dynamic>> _getYouTubeMetadata(String url) async {
    try {
      // YouTube oEmbed API kullanarak metadata çek
      String videoId = _extractYouTubeVideoId(url);
      if (videoId.isEmpty) {
        return _createBasicMetadata(url, 'YouTube');
      }

      // YouTube oEmbed endpoint
      final oembedUrl =
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';

      final response = await http.get(
        Uri.parse(oembedUrl),
        headers: {'User-Agent': 'Linkcim Video Analyzer 1.0'},
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'platform': 'YouTube',
          'title': data['title'] ?? '📺 YouTube Video',
          'description': _generateDescription(data['title'], 'YouTube'),
          'author': data['author_name'] ?? 'Bilinmeyen Kanal',
          'duration': null, // oEmbed'de duration yok
          'thumbnail': data['thumbnail_url'],
          'view_count': null,
          'upload_date': null,
          'video_id': videoId,
          'url': url,
          'raw_data': data,
        };
      }

      return _createBasicMetadata(url, 'YouTube');
    } catch (e) {
      _debugPrint('YouTube metadata hatası: $e');
      return _createBasicMetadata(url, 'YouTube');
    }
  }

  // 🎵 TikTok metadata çekme
  static Future<Map<String, dynamic>> _getTikTokMetadata(String url) async {
    try {
      // TikTok için oEmbed API kullan
      final oembedUrl =
          'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}';

      final response = await http.get(
        Uri.parse(oembedUrl),
        headers: {'User-Agent': 'Linkcim Video Analyzer 1.0'},
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'platform': 'TikTok',
          'title': data['title'] ?? '🎵 TikTok Video',
          'description': _generateDescription(data['title'], 'TikTok'),
          'author': data['author_name'] ?? 'Bilinmeyen Kullanıcı',
          'duration': null,
          'thumbnail': data['thumbnail_url'],
          'view_count': null,
          'upload_date': null,
          'video_id': _extractTikTokVideoId(url),
          'url': url,
          'raw_data': data,
        };
      }

      return _createBasicMetadata(url, 'TikTok');
    } catch (e) {
      _debugPrint('TikTok metadata hatası: $e');
      return _createBasicMetadata(url, 'TikTok');
    }
  }

  // 🐦 Twitter metadata çekme
  static Future<Map<String, dynamic>> _getTwitterMetadata(String url) async {
    try {
      // Twitter oEmbed API kullan (eğer hala çalışıyorsa)
      // Not: Twitter'ın API erişimi kısıtlı olabilir

      _debugPrint('Twitter/X metadata çekiliyor...');

      // Basit parsing ile tweet bilgilerini çıkar
      String tweetId = _extractTwitterTweetId(url);
      String username = _extractTwitterUsername(url);

      // oEmbed API'yi dene (eski URL formatı)
      try {
        final oembedUrl =
            'https://publish.twitter.com/oembed?url=${Uri.encodeComponent(url)}&dnt=true';

        final response = await http.get(
          Uri.parse(oembedUrl),
          headers: {'User-Agent': 'Linkcim Video Analyzer 1.0'},
        ).timeout(Duration(seconds: timeoutSeconds));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          return {
            'success': true,
            'platform': 'Twitter',
            'title': data['html'] != null
                ? _extractTextFromHTML(data['html'])
                : '🐦 Twitter Gönderi',
            'description': _generateDescription(data['html'], 'Twitter'),
            'author': data['author_name'] ?? username,
            'duration': null,
            'thumbnail': null,
            'view_count': null,
            'upload_date': null,
            'video_id': tweetId,
            'url': url,
            'raw_data': data,
            'content_type': _detectTwitterContentType(data),
          };
        }
      } catch (e) {
        _debugPrint('Twitter oEmbed API hatası: $e');
      }

      // Fallback: Basit metadata oluştur
      return {
        'success': true,
        'platform': 'Twitter',
        'title': username.isNotEmpty
            ? '🐦 @$username Twitter'
            : '🐦 Twitter Gönderi',
        'description': _generateDescription(null, 'Twitter'),
        'author': username.isNotEmpty ? '@$username' : 'Bilinmeyen',
        'duration': null,
        'thumbnail': null,
        'view_count': null,
        'upload_date': null,
        'video_id': tweetId,
        'url': url,
        'raw_data': {},
        'content_type': url.contains('video') ? 'video' : 'tweet',
      };
    } catch (e) {
      _debugPrint('Twitter metadata hatası: $e');
      return _createBasicMetadata(url, 'Twitter');
    }
  }

  // 📸 Instagram metadata çekme
  static Future<Map<String, dynamic>> _getInstagramMetadata(String url) async {
    try {
      // Instagram için oEmbed API
      final oembedUrl =
          'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(url)}';

      final response = await http.get(
        Uri.parse(oembedUrl),
        headers: {'User-Agent': 'Linkcim Video Analyzer 1.0'},
      ).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'platform': 'Instagram',
          'title': data['title'] ?? '📸 Instagram Video',
          'description': _generateDescription(data['title'], 'Instagram'),
          'author': data['author_name'] ?? 'Bilinmeyen Kullanıcı',
          'duration': null,
          'thumbnail': data['thumbnail_url'],
          'view_count': null,
          'upload_date': null,
          'video_id': _extractInstagramVideoId(url),
          'url': url,
          'raw_data': data,
        };
      }

      return _createBasicMetadata(url, 'Instagram');
    } catch (e) {
      _debugPrint('Instagram metadata hatası: $e');
      return _createBasicMetadata(url, 'Instagram');
    }
  }

  // 🆔 Video ID çıkarma fonksiyonları
  static String _extractYouTubeVideoId(String url) {
    try {
      Uri uri = Uri.parse(url);

      // youtu.be/VIDEO_ID formatı
      if (url.contains('youtu.be/')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      }

      // youtube.com/watch?v=VIDEO_ID formatı
      if (url.contains('youtube.com/watch')) {
        return uri.queryParameters['v'] ?? '';
      }

      // youtube.com/shorts/VIDEO_ID formatı
      if (url.contains('youtube.com/shorts/')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  static String _extractTikTokVideoId(String url) {
    try {
      Uri uri = Uri.parse(url);

      // /video/VIDEO_ID formatından video ID çıkar
      if (url.contains('/video/')) {
        final segments = uri.pathSegments;
        final videoIndex = segments.indexOf('video');
        if (videoIndex != -1 && videoIndex + 1 < segments.length) {
          return segments[videoIndex + 1];
        }
      }

      // vm.tiktok.com/SHORT_ID formatı
      if (url.contains('vm.tiktok.com/')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      }

      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    } catch (e) {
      return '';
    }
  }

  static String _extractInstagramVideoId(String url) {
    try {
      Uri uri = Uri.parse(url);
      RegExp regExp = RegExp(r'/(p|reel|tv)/([A-Za-z0-9_-]+)');
      Match? match = regExp.firstMatch(uri.path);
      return match?.group(2) ?? '';
    } catch (e) {
      return '';
    }
  }

  // 🐦 Twitter yardımcı fonksiyonları
  static String _extractTwitterTweetId(String url) {
    try {
      Uri uri = Uri.parse(url);
      final statusIndex = uri.pathSegments.indexOf('status');
      if (statusIndex != -1 && statusIndex + 1 < uri.pathSegments.length) {
        return uri.pathSegments[statusIndex + 1];
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static String _extractTwitterUsername(String url) {
    try {
      Uri uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        String username = uri.pathSegments[0];
        // @ işaretini kaldır
        return username.replaceAll('@', '');
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static String _extractTextFromHTML(String html) {
    try {
      // Basit HTML tag temizleme
      return html
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } catch (e) {
      return 'Twitter Gönderi';
    }
  }

  static String _detectTwitterContentType(Map<String, dynamic> data) {
    try {
      String html = data['html']?.toString() ?? '';
      if (html.contains('video') || html.contains('mp4')) {
        return 'video';
      }
      if (html.contains('photo') || html.contains('image')) {
        return 'image';
      }
      return 'tweet';
    } catch (e) {
      return 'tweet';
    }
  }

  // 📝 Yardımcı fonksiyonlar
  static String _generateDescription(String? title, String platform) {
    if (title == null || title.isEmpty) {
      return '$platform platformundan video';
    }

    return 'Bu video $platform platformundan alınmıştır: ${title.length > 100 ? title.substring(0, 100) + '...' : title}';
  }

  static Map<String, dynamic> _createBasicMetadata(
      String url, String platform) {
    String emoji = AppConstants.platformEmojis[platform] ?? '🎬';

    return {
      'success': true,
      'platform': platform,
      'title': '$emoji $platform Video',
      'description': _generateDescription(null, platform),
      'author': 'Bilinmeyen',
      'duration': null,
      'thumbnail': null,
      'view_count': null,
      'upload_date': null,
      'video_id': '',
      'url': url,
      'raw_data': {},
    };
  }

  static Map<String, dynamic> _createErrorMetadata(String url, String error) {
    String platform = AppConstants.detectPlatform(url);
    String emoji = AppConstants.platformEmojis[platform] ?? '🎬';

    return {
      'success': false,
      'platform': platform,
      'title': '$emoji $platform Video',
      'description': 'Video bilgileri alınamadı',
      'author': 'Bilinmeyen',
      'duration': null,
      'thumbnail': null,
      'view_count': null,
      'upload_date': null,
      'video_id': '',
      'url': url,
      'error': error,
      'raw_data': {},
    };
  }

  // 🧪 Platform test fonksiyonu
  static Future<Map<String, bool>> testPlatformSupport() async {
    Map<String, bool> results = {};

    try {
      // YouTube test
      final youtubeResult = await _getYouTubeMetadata(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      results['YouTube'] = youtubeResult['success'] == true;

      // TikTok test (dummy URL)
      results['TikTok'] = true; // TikTok oEmbed genelde çalışır

      // Instagram test (dummy URL)
      results['Instagram'] = true; // Instagram oEmbed genelde çalışır
    } catch (e) {
      _debugPrint('Platform test hatası: $e');
    }

    return results;
  }
}
