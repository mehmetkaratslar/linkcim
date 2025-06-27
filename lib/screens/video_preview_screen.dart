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

  Color _getPlatformColor() {
    switch (widget.video.platform.toLowerCase()) {
      case 'instagram':
        return Colors.purple;
      case 'youtube':
        return Colors.red;
      case 'tiktok':
        return Colors.black;
      case 'twitter':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getVideoType() {
    final url = widget.video.videoUrl.toLowerCase();
    if (url.contains('/reel/')) return 'Instagram Reel';
    if (url.contains('/tv/')) return 'IGTV';
    if (url.contains('/p/')) return 'Instagram Post';
    if (url.contains('youtube.com')) return 'YouTube Video';
    if (url.contains('tiktok.com')) return 'TikTok Video';
    if (url.contains('twitter.com')) return 'Twitter Video';
    return 'Video';
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _downloadVideo() async {
    // Format seçim dialogu göster
    final selectedFormat = await _showFormatSelectionDialog();
    if (selectedFormat == null) return; // Kullanıcı iptal etti

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        video: widget.video,
        format: selectedFormat['format'],
        quality: selectedFormat['quality'],
      ),
    );
  }

  Future<Map<String, String>?> _showFormatSelectionDialog() async {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.video_settings, color: Colors.blue[600]),
            SizedBox(width: 8),
            Text('Format Seçin'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'İndirmek istediğiniz video formatını ve kalitesini seçin:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),

            // MP4 Video Seçenekleri
            _buildFormatOption(
              icon: Icons.video_file,
              title: 'MP4 Video - Yüksek Kalite',
              subtitle: '1080p veya mevcut en yüksek kalite',
              format: 'mp4',
              quality: 'high',
              color: Colors.green,
            ),

            _buildFormatOption(
              icon: Icons.video_file,
              title: 'MP4 Video - Orta Kalite',
              subtitle: '720p kalite, daha küçük dosya boyutu',
              format: 'mp4',
              quality: 'medium',
              color: Colors.blue,
            ),

            _buildFormatOption(
              icon: Icons.video_file,
              title: 'MP4 Video - Düşük Kalite',
              subtitle: '480p kalite, en küçük dosya boyutu',
              format: 'mp4',
              quality: 'low',
              color: Colors.orange,
            ),

            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),

            // MP3 Audio Seçeneği
            _buildFormatOption(
              icon: Icons.audio_file,
              title: 'MP3 Ses',
              subtitle: 'Sadece ses dosyası (192kbps)',
              format: 'mp3',
              quality: 'medium',
              color: Colors.purple,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String format,
    required String quality,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        onTap: () {
          Navigator.of(context).pop({
            'format': format,
            'quality': quality,
          });
        },
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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

            // Link Detayları Bölümü - Gelişmiş
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Link Detayları',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // İçerik
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Platform Bilgisi
                        _buildDetailRow(
                          'Platform',
                          _getPlatformName(),
                          Icons.public,
                          _getPlatformColor(),
                        ),

                        SizedBox(height: 12),

                        // Video Türü
                        _buildDetailRow(
                          'Video Türü',
                          _getVideoType(),
                          Icons.video_library,
                          Colors.purple,
                        ),

                        SizedBox(height: 12),

                        // URL Detayı
                        _buildDetailRow(
                          'URL Uzunluğu',
                          '${widget.video.videoUrl.length} karakter',
                          Icons.text_fields,
                          Colors.orange,
                        ),

                        SizedBox(height: 16),

                        // Tam URL
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tam URL:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 6),
                              SelectableText(
                                widget.video.videoUrl,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12),

                        // URL Kopyalama Butonu
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await ShareService.copyLinkToClipboard(
                                    widget.video.videoUrl);
                                _showSuccess('Link panoya kopyalandı! 📋');
                              } catch (e) {
                                _showError('Kopyalama başarısız');
                              }
                            },
                            icon: Icon(Icons.copy, size: 18),
                            label: Text('URL\'yi Kopyala'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
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
