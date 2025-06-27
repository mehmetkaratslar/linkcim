// Dosya Konumu: lib/widgets/share_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:linkcim/models/saved_video.dart';

class ShareMenu extends StatelessWidget {
  final SavedVideo video;

  const ShareMenu({Key? key, required this.video}) : super(key: key);

  static Future<void> show(BuildContext context, SavedVideo video) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareMenu(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 16),

            // Başlık
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Paylaş',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    video.title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Paylaş seçenekleri
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Video linkini paylaş
                  _buildShareButton(
                    icon: Icons.share,
                    title: 'Video Linkini Paylaş',
                    subtitle: 'Telefonun paylaş menüsü ile',
                    onTap: () => _shareVideoLink(context),
                  ),

                  SizedBox(height: 10),

                  // Video detaylarını paylaş
                  _buildShareButton(
                    icon: Icons.description,
                    title: 'Detaylı Bilgi Paylaş',
                    subtitle: 'Başlık, açıklama ve etiketlerle',
                    onTap: () => _shareVideoDetails(context),
                  ),

                  SizedBox(height: 10),

                  // Link kopyala
                  _buildShareButton(
                    icon: Icons.copy,
                    title: 'Linki Kopyala',
                    subtitle: 'Panoya kopyala',
                    onTap: () => _copyLink(context),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // İptal butonu
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.blue[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _shareVideoLink(BuildContext context) async {
    try {
      await Share.share(
        video.videoUrl,
        subject: video.title,
      );
      Navigator.of(context).pop();
      _showSuccess(context, 'Video linki paylaşıldı');
    } catch (e) {
      _showError(context, 'Paylaşma hatası: $e');
    }
  }

  void _shareVideoDetails(BuildContext context) async {
    try {
      final shareText = '''
🎬 ${video.title}

📱 Link: ${video.videoUrl}

📝 Açıklama: ${video.description.isNotEmpty ? video.description : 'Açıklama yok'}

🏷️ Kategori: ${video.category}

${video.tags.isNotEmpty ? '🔖 Etiketler: ${video.tags.join(', ')}' : ''}

📅 Tarih: ${video.formattedDate}

---
Linkcim uygulaması ile paylaşıldı 📱
''';

      await Share.share(
        shareText,
        subject: 'Video: ${video.title}',
      );
      Navigator.of(context).pop();
      _showSuccess(context, 'Video detayları paylaşıldı');
    } catch (e) {
      _showError(context, 'Paylaşma hatası: $e');
    }
  }

  void _copyLink(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: video.videoUrl));
      Navigator.of(context).pop();
      _showSuccess(context, 'Link panoya kopyalandı');
    } catch (e) {
      _showError(context, 'Kopyalama hatası: $e');
    }
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Basit paylaşma butonu widget'ı
class ShareButton extends StatelessWidget {
  final SavedVideo video;
  final IconData? icon;
  final String? tooltip;

  const ShareButton({
    Key? key,
    required this.video,
    this.icon = Icons.share,
    this.tooltip = 'Paylaş',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => ShareMenu.show(context, video),
    );
  }
}

// Hızlı paylaşma widget'ı (sadece link)
class QuickShareButton extends StatelessWidget {
  final SavedVideo video;

  const QuickShareButton({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.ios_share),
      tooltip: 'Hızlı Paylaş',
      onPressed: () async {
        try {
          await Share.share(video.videoUrl, subject: video.title);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video paylaşıldı'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Paylaşma başarısız: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }
}
