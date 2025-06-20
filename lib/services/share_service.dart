// Dosya Konumu: lib/services/share_service.dart

import 'package:share_plus/share_plus.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:flutter/services.dart';

class ShareService {
  // Video linkini paylaş
  static Future<void> shareVideoLink(SavedVideo video) async {
    try {
      final shareText = _buildShareText(video);

      await Share.share(
        shareText,
        subject: video.title,
      );
    } catch (e) {
      print('Paylaşma hatası: $e');
      throw 'Paylaşma işlemi başarısız: $e';
    }
  }

  // Video bilgilerini detaylı paylaş
  static Future<void> shareVideoDetails(SavedVideo video) async {
    try {
      final detailedText = _buildDetailedShareText(video);

      await Share.share(
        detailedText,
        subject: 'Linkci\'den Video Paylaşımı: ${video.title}',
      );
    } catch (e) {
      print('Detaylı paylaşma hatası: $e');
      throw 'Paylaşma işlemi başarısız: $e';
    }
  }

  // Sadece linki paylaş
  static Future<void> shareOnlyLink(String url) async {
    try {
      await Share.share(url);
    } catch (e) {
      print('Link paylaşma hatası: $e');
      throw 'Link paylaşma başarısız: $e';
    }
  }

  // Linki panoya kopyala
  static Future<void> copyLinkToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
    } catch (e) {
      print('Kopyalama hatası: $e');
      throw 'Kopyalama işlemi başarısız: $e';
    }
  }

  // Video bilgilerini panoya kopyala
  static Future<void> copyVideoDetailsToClipboard(SavedVideo video) async {
    try {
      final detailedText = _buildDetailedShareText(video);
      await Clipboard.setData(ClipboardData(text: detailedText));
    } catch (e) {
      print('Video detay kopyalama hatası: $e');
      throw 'Kopyalama işlemi başarısız: $e';
    }
  }

  // Birden fazla video linkini paylaş
  static Future<void> shareMultipleVideos(List<SavedVideo> videos) async {
    try {
      if (videos.isEmpty) {
        throw 'Paylaşılacak video bulunamadı';
      }

      final shareText = _buildMultipleVideosShareText(videos);

      await Share.share(
        shareText,
        subject: 'Linkci\'den ${videos.length} Video Paylaşımı',
      );
    } catch (e) {
      print('Çoklu paylaşma hatası: $e');
      throw 'Paylaşma işlemi başarısız: $e';
    }
  }

  // Kategori bazlı paylaşım
  static Future<void> shareVideosByCategory(String category, List<SavedVideo> videos) async {
    try {
      final categoryVideos = videos.where((v) => v.category == category).toList();

      if (categoryVideos.isEmpty) {
        throw '$category kategorisinde video bulunamadı';
      }

      final shareText = _buildCategoryShareText(category, categoryVideos);

      await Share.share(
        shareText,
        subject: 'Linkci - $category Kategorisi (${categoryVideos.length} video)',
      );
    } catch (e) {
      print('Kategori paylaşma hatası: $e');
      throw 'Kategori paylaşma başarısız: $e';
    }
  }

  // Basit paylaşım metni oluştur
  static String _buildShareText(SavedVideo video) {
    return '''
🎬 ${video.title}

📱 Instagram Linki:
${video.videoUrl}

📝 Açıklama: ${video.description.isNotEmpty ? video.description : 'Açıklama yok'}

🏷️ Kategori: ${video.category}

${video.tags.isNotEmpty ? '🔖 Etiketler: ${video.tags.join(', ')}' : ''}

📅 Kayıt Tarihi: ${video.formattedDate}

---
Linkci uygulaması ile paylaşıldı 📱
''';
  }

  // Detaylı paylaşım metni oluştur
  static String _buildDetailedShareText(SavedVideo video) {
    return '''
🎬 ${video.title}

📱 Instagram Linki:
${video.videoUrl}

📝 Açıklama:
${video.description.isNotEmpty ? video.description : 'Açıklama mevcut değil'}

📊 Video Bilgileri:
• Kategori: ${video.category}
• Etiketler: ${video.tags.isNotEmpty ? video.tags.join(', ') : 'Etiket yok'}
• Kayıt Tarihi: ${video.formattedDate}
• Video Key: ${video.key}

🔗 Kısa Link: ${video.videoUrl.length > 50 ? video.videoUrl.substring(0, 50) + '...' : video.videoUrl}

---
Bu video Linkci uygulaması ile organize edilmiş ve paylaşılmıştır 📱
Instagram videolarınızı kaydedin, kategorize edin, kolayca bulun!
''';
  }

  // Birden fazla video için paylaşım metni
  static String _buildMultipleVideosShareText(List<SavedVideo> videos) {
    final buffer = StringBuffer();

    buffer.writeln('🎬 Video Koleksiyonu (${videos.length} video)');
    buffer.writeln('');

    for (int i = 0; i < videos.length; i++) {
      final video = videos[i];
      buffer.writeln('${i + 1}. ${video.title}');
      buffer.writeln('   🔗 ${video.videoUrl}');
      buffer.writeln('   📁 ${video.category}');
      if (video.tags.isNotEmpty) {
        buffer.writeln('   🏷️ ${video.tags.take(3).join(', ')}${video.tags.length > 3 ? '...' : ''}');
      }
      buffer.writeln('');
    }

    buffer.writeln('---');
    buffer.writeln('Linkci uygulaması ile organize edilmiş koleksiyon 📱');

    return buffer.toString();
  }

  // Kategori bazlı paylaşım metni
  static String _buildCategoryShareText(String category, List<SavedVideo> videos) {
    final buffer = StringBuffer();

    buffer.writeln('📁 $category Kategorisi');
    buffer.writeln('${videos.length} video bulundu');
    buffer.writeln('');

    for (int i = 0; i < videos.length && i < 10; i++) { // Maksimum 10 video
      final video = videos[i];
      buffer.writeln('${i + 1}. ${video.title}');
      buffer.writeln('   🔗 ${video.videoUrl}');
      if (video.description.isNotEmpty && video.description.length <= 50) {
        buffer.writeln('   📝 ${video.description}');
      }
      buffer.writeln('');
    }

    if (videos.length > 10) {
      buffer.writeln('... ve ${videos.length - 10} video daha');
      buffer.writeln('');
    }

    buffer.writeln('---');
    buffer.writeln('Linkci uygulaması ile kategorize edilmiş videolar 📱');

    return buffer.toString();
  }

  // WhatsApp'a özel paylaşım
  static Future<void> shareToWhatsApp(SavedVideo video) async {
    try {
      final text = _buildShareText(video);
      await Share.share(text, subject: video.title);
    } catch (e) {
      throw 'WhatsApp paylaşma başarısız: $e';
    }
  }

  // Email'e özel paylaşım
  static Future<void> shareViaEmail(SavedVideo video) async {
    try {
      final subject = 'Video Paylaşımı: ${video.title}';
      final body = _buildDetailedShareText(video);

      await Share.share(
        body,
        subject: subject,
      );
    } catch (e) {
      throw 'Email paylaşma başarısız: $e';
    }
  }
}