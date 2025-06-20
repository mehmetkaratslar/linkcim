// Dosya Konumu: lib/widgets/share_menu.dart

import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/share_service.dart';

class ShareMenu extends StatelessWidget {
  final SavedVideo video;

  const ShareMenu({Key? key, required this.video}) : super(key: key);

  static Future<void> show(BuildContext context, SavedVideo video) async {
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShareMenu(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 20),

          // Başlık
          Text(
            'Video Paylaş',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          // Video bilgisi
          Text(
            video.title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24),

          // Paylaşma seçenekleri
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1,
            children: [
              _buildShareOption(
                context,
                icon: Icons.link,
                title: 'Sadece Link',
                color: Colors.blue,
                onTap: () => _shareOnlyLink(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.description,
                title: 'Detaylı',
                color: Colors.green,
                onTap: () => _shareDetailed(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.copy,
                title: 'Link Kopyala',
                color: Colors.orange,
                onTap: () => _copyLink(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.content_copy,
                title: 'Detay Kopyala',
                color: Colors.purple,
                onTap: () => _copyDetails(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.email,
                title: 'Email',
                color: Colors.red,
                onTap: () => _shareViaEmail(context),
              ),
              _buildShareOption(
                context,
                icon: Icons.chat,
                title: 'WhatsApp',
                color: Colors.green[700]!,
                onTap: () => _shareToWhatsApp(context),
              ),
            ],
          ),

          SizedBox(height: 20),

          // İptal butonu
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'İptal',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShareOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _shareOnlyLink(BuildContext context) async {
    try {
      await ShareService.shareOnlyLink(video.videoUrl);
      Navigator.of(context).pop();
      _showSuccess(context, 'Link paylaşıldı');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _shareDetailed(BuildContext context) async {
    try {
      await ShareService.shareVideoDetails(video);
      Navigator.of(context).pop();
      _showSuccess(context, 'Video detaylı olarak paylaşıldı');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _copyLink(BuildContext context) async {
    try {
      await ShareService.copyLinkToClipboard(video.videoUrl);
      Navigator.of(context).pop();
      _showSuccess(context, 'Link panoya kopyalandı');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _copyDetails(BuildContext context) async {
    try {
      await ShareService.copyVideoDetailsToClipboard(video);
      Navigator.of(context).pop();
      _showSuccess(context, 'Video detayları panoya kopyalandı');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _shareViaEmail(BuildContext context) async {
    try {
      await ShareService.shareViaEmail(video);
      Navigator.of(context).pop();
      _showSuccess(context, 'Email uygulaması açıldı');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _shareToWhatsApp(BuildContext context) async {
    try {
      await ShareService.shareToWhatsApp(video);
      Navigator.of(context).pop();
      _showSuccess(context, 'WhatsApp\'a paylaşıldı');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
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
          await ShareService.shareVideoLink(video);
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