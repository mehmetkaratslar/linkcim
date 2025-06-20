// Dosya Konumu: lib/screens/video_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/widgets/video_thumbnail.dart';
import 'package:linkcim/widgets/share_menu.dart';
import 'package:linkcim/widgets/tag_chip.dart';
import 'package:linkcim/screens/video_player_screen.dart';
import 'package:linkcim/screens/add_video_screen.dart';
import 'package:linkcim/services/share_service.dart';
import 'package:linkcim/services/instagram_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:linkcim/widgets/download_progress_dialog.dart';

class VideoPreviewScreen extends StatefulWidget {
  final SavedVideo video;

  const VideoPreviewScreen({Key? key, required this.video}) : super(key: key);

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  Map<String, dynamic>? metaData;
  bool isLoadingMeta = true;

  @override
  void initState() {
    super.initState();
    _loadVideoMetadata();
  }

  Future<void> _loadVideoMetadata() async {
    try {
      final data =
          await InstagramService.getVideoMetadata(widget.video.videoUrl);
      setState(() {
        metaData = data;
        isLoadingMeta = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMeta = false;
      });
    }
  }

  Future<void> _openInPlatform() async {
    try {
      final uri = Uri.parse(widget.video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('${_getPlatformName()} açılamadı');
      }
    } catch (e) {
      _showError('Link açma hatası: $e');
    }
  }

  String _getPlatformName() {
    switch (widget.video.platform.toLowerCase()) {
      case 'instagram':
        return 'Instagram';
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'twitter':
        return 'Twitter';
      default:
        return 'Platform';
    }
  }

  String _getPlatformActionText() {
    switch (widget.video.platform.toLowerCase()) {
      case 'instagram':
        return 'Instagram\'da Aç';
      case 'youtube':
        return 'YouTube\'de Aç';
      case 'tiktok':
        return 'TikTok\'ta Aç';
      case 'twitter':
        return 'Twitter\'da Aç';
      default:
        return 'Platformda Aç';
    }
  }

  void _openVideoPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: widget.video),
      ),
    );
  }

  void _editVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVideoScreen(video: widget.video),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.of(context).pop(true); // Değişiklik oldu, geri dön
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _downloadVideo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        video: widget.video,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Önizleme'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editVideo,
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => ShareMenu.show(context, widget.video),
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail büyük görünüm
            LargeVideoThumbnail(
              videoUrl: widget.video.videoUrl,
              customThumbnailUrl: metaData?['thumbnail'],
              onTap: _openVideoPlayer,
            ),

            SizedBox(height: 16),

            // Video başlığı
            Text(
              widget.video.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            // Platform ve yazar bilgisi
            Row(
              children: [
                Text(
                  widget.video.platformIcon,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 4),
                Text(
                  widget.video.platform.toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.video.authorDisplay,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Meta bilgiler
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  widget.video.category,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  widget.video.formattedDate,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Video açıklaması
            if (widget.video.description.isNotEmpty) ...[
              Text(
                'Açıklama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.video.description,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Etiketler
            if (widget.video.tags.isNotEmpty) ...[
              Text(
                'Etiketler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.video.tags.map((tag) {
                  return TagChip(
                    tag: tag,
                    size: TagChipSize.medium,
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],

            // Instagram meta bilgileri
            if (metaData != null && metaData!['success'] == true) ...[
              Text(
                'Instagram Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (metaData!['author'] != null)
                      Text('Yazar: ${metaData!['author']}'),
                    if (metaData!['postType'] != null)
                      Text('Tip: ${metaData!['postType']}'),
                    if (metaData!['postId'] != null)
                      Text('Post ID: ${metaData!['postId']}'),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Loading indicator for meta data
            if (isLoadingMeta) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Instagram bilgileri yükleniyor...'),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openVideoPlayer,
                    icon: Icon(Icons.play_arrow),
                    label: Text('Uygulamada Oynat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openInPlatform,
                    icon: Icon(Icons.open_in_new),
                    label: Text(_getPlatformActionText()),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // İndirme butonu (büyük ve belirgin)
            Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _downloadVideo,
                icon: Icon(Icons.download, size: 28),
                label: Text(
                  'VİDEO İNDİR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.green.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 8),

            // Platform özel uyarı
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Video ${widget.video.platform.toLowerCase()} platformundan indirilecek. İndirme birkaç dakika sürebilir.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Paylaşma butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ShareService.copyLinkToClipboard(
                            widget.video.videoUrl);
                        _showSuccess('Link kopyalandı');
                      } catch (e) {
                        _showError('Kopyalama başarısız');
                      }
                    },
                    icon: Icon(Icons.copy),
                    label: Text('Link Kopyala'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ShareMenu.show(context, widget.video),
                    icon: Icon(Icons.share),
                    label: Text('Paylaş'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Video URL gösterimi
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  SelectableText(
                    widget.video.videoUrl,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
