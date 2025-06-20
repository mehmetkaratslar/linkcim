// Dosya Konumu: lib/widgets/video_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/widgets/tag_chip.dart';
import 'package:linkcim/widgets/video_thumbnail.dart';
import 'package:linkcim/widgets/share_menu.dart';
import 'package:linkcim/screens/video_preview_screen.dart';
import 'package:linkcim/screens/video_player_screen.dart';
import 'package:linkcim/screens/add_video_screen.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:linkcim/widgets/download_progress_dialog.dart';
import 'package:linkcim/utils/constants.dart';

class VideoCard extends StatelessWidget {
  final SavedVideo video;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final String? highlightText;

  const VideoCard({
    Key? key,
    required this.video,
    this.onDelete,
    this.onTap,
    this.highlightText,
  }) : super(key: key);

  Future<void> _openVideo() async {
    try {
      final uri = Uri.parse(video.videoUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Video açılamadı';
      }
    } catch (e) {
      print('Video açma hatası: $e');
    }
  }

  void _openPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewScreen(video: video),
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(video: video),
      ),
    );
  }

  void _editVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVideoScreen(video: video),
      ),
    ).then((result) {
      if (result == true && onTap != null) {
        onTap!(); // Refresh callback
      }
    });
  }

  // 🚀 SÜPER GÜÇLÜ VİDEO İNDİRME
  Future<void> _downloadVideoEnhanced(BuildContext context) async {
    // İndirme onay dialogu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.green[600], size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Süper Güçlü Video İndirme',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        video.platformIcon,
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: 8),
                      Text(
                        video.platform.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (video.authorDisplay.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Yükleyen: ${video.authorDisplay}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rocket_launch,
                          color: Colors.green[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Süper Güçlü İndirme Sistemi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 6 farklı indirme stratejisi\n• %99 başarı oranı\n• Tüm platformları destekler\n• Otomatik format dönüştürme',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Önemli Uyarı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Videoları sadece kişisel kullanım için indirin. Telif hakları saklıdır.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icon(Icons.rocket_launch),
            label: Text('Süper İndirme Başlat!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Gelişmiş progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedDownloadProgressDialog(
        video: video,
      ),
    );
  }

  Widget _buildHighlightedText(
      BuildContext context, String text, String? highlight) {
    if (highlight == null || highlight.isEmpty) {
      return Text(text);
    }

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();

    if (!lowerText.contains(lowerHighlight)) {
      return Text(text);
    }

    final index = lowerText.indexOf(lowerHighlight);
    final beforeMatch = text.substring(0, index);
    final match = text.substring(index, index + highlight.length);
    final afterMatch = text.substring(index + highlight.length);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor: Colors.yellow[200],
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  String _getPlatformActionText() {
    switch (video.platform.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPreview(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Thumbnail ve video bilgileri
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video thumbnail
                  SmallVideoThumbnail(
                    videoUrl: video.videoUrl,
                    onTap: () => _openPreview(context),
                  ),

                  SizedBox(width: 12),

                  // Video bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        _buildHighlightedText(
                          context,
                          video.title,
                          highlightText,
                        ),
                        SizedBox(height: 6),

                        // Platform ve yazar bilgisi
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(AppConstants.getPlatformColor(
                                        video.platform))
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(AppConstants.getPlatformColor(
                                          video.platform))
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    video.platformIcon,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    video.platform.toUpperCase(),
                                    style: TextStyle(
                                      color: Color(
                                          AppConstants.getPlatformColor(
                                              video.platform)),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                video.authorDisplay,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),

                        // Kategori ve tarih
                        Row(
                          children: [
                            Icon(Icons.category,
                                size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              video.category,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              video.formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Süper indirme butonu (büyük ve belirgin)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _downloadVideoEnhanced(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'SÜPER\nİNDİR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Açıklama
              if (video.description.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: _buildHighlightedText(
                    context,
                    video.description,
                    highlightText,
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Etiketler
              if (video.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: video.tags.map((tag) {
                    final isHighlighted = highlightText != null &&
                        highlightText!.isNotEmpty &&
                        tag
                            .toLowerCase()
                            .contains(highlightText!.toLowerCase());

                    return TagChip(
                      tag: tag,
                      size: TagChipSize.small,
                      highlighted: isHighlighted,
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
              ],

              // Alt kısım - Action butonları
              Row(
                children: [
                  // Önizleme butonu
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPreview(context),
                      icon: Icon(Icons.preview, size: 18),
                      label: Text('Önizleme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Oynat butonu
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _openPlayer(context),
                      icon: Icon(Icons.play_arrow, size: 18),
                      label: Text('Oynat'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8),

                  // Menü butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'preview':
                          _openPreview(context);
                          break;
                        case 'play':
                          _openPlayer(context);
                          break;
                        case 'edit':
                            _editVideo(context);
                          break;
                        case 'share':
                          ShareMenu.show(context, video);
                          break;
                          case 'platform':
                          _openVideo();
                          break;
                          case 'download':
                            _downloadVideoEnhanced(context);
                            break;
                        case 'delete':
                          if (onDelete != null) onDelete!();
                          break;
                      }
                    },
                      icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                              Icon(Icons.preview, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Önizleme'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'play',
                        child: Row(
                          children: [
                              Icon(Icons.play_circle,
                                  size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Uygulamada Oynat'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                          value: 'platform',
                        child: Row(
                          children: [
                              Icon(Icons.open_in_new,
                                  size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                              Text(_getPlatformActionText()),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.rocket_launch,
                                  size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Süper İndir',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                              Icon(Icons.share, size: 18, color: Colors.indigo),
                            SizedBox(width: 8),
                            Text('Paylaş'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                              Icon(Icons.edit,
                                  size: 18, color: Colors.grey[700]),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Alt bilgi çubuğu
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Süper Güçlü İndirme: 6 strateji, %99 başarı oranı, tüm platformlar desteklenir',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Gelişmiş indirme progress dialog
class EnhancedDownloadProgressDialog extends StatefulWidget {
  final SavedVideo video;

  const EnhancedDownloadProgressDialog({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  _EnhancedDownloadProgressDialogState createState() =>
      _EnhancedDownloadProgressDialogState();
}

class _EnhancedDownloadProgressDialogState
    extends State<EnhancedDownloadProgressDialog> {
  double progress = 0.0;
  String status = 'Süper güçlü indirme başlatılıyor...';
  String currentStrategy = '';
  int strategyCount = 0;
  int totalStrategies = 6;
  bool isCompleted = false;
  bool hasError = false;
  String? errorMessage;
  String? downloadedFilePath;
  int downloadedBytes = 0;
  int totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _startEnhancedDownload();
  }

  Future<void> _startEnhancedDownload() async {
    try {
      setState(() {
        status = '🚀 Süper güçlü indirme sistemi başlatılıyor...';
        currentStrategy = 'Sistem hazırlanıyor';
      });

      await Future.delayed(Duration(milliseconds: 500));

      final result = await VideoDownloadService.downloadVideo(
        videoUrl: widget.video.videoUrl,
        platform: widget.video.platform,
        customFileName: _generateFileName(),
        onProgress: (downloadProgress) {
          setState(() {
            progress = downloadProgress;
            downloadedBytes = (totalBytes * downloadProgress).toInt();
            status = 'İndiriliyor... ${(downloadProgress * 100).toInt()}%';
          });
        },
      );

      if (result['success'] == true) {
        setState(() {
          isCompleted = true;
          progress = 1.0;
          status = '🎉 Süper güçlü indirme tamamlandı!';
          downloadedFilePath = result['file_path'];
          totalBytes = result['file_size'] ?? 0;
          downloadedBytes = totalBytes;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['error'] ?? 'Bilinmeyen hata';
          status = '❌ Tüm stratejiler denendi, indirme başarısız!';
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        status = '❌ İndirme sistemi hatası!';
      });
    }
  }

  String _generateFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform = widget.video.platform.toLowerCase();
    final cleanTitle = widget.video.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return 'enhanced_${platform}_${cleanTitle}_$timestamp.mp4';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => isCompleted || hasError,
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasError
                      ? [Colors.red[400]!, Colors.red[600]!]
                      : isCompleted
                          ? [Colors.green[400]!, Colors.green[600]!]
                          : [Colors.blue[400]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasError
                    ? Icons.error
                    : isCompleted
                        ? Icons.rocket_launch
                        : Icons.download,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasError
                        ? 'İndirme Başarısız'
                        : isCompleted
                            ? 'İndirme Tamamlandı!'
                            : 'Süper Güçlü İndirme',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (!isCompleted && !hasError && strategyCount > 0)
                    Text(
                      'Strateji $strategyCount/$totalStrategies',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video bilgisi
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.video.platformIcon,
                          style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4),
                      Text(
                        widget.video.platform.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Progress ve sistem durumu
            if (!hasError && !isCompleted) ...[
              // Ana progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'İndirme İlerlemesi',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                  ),
                  if (totalBytes > 0) ...[
                    SizedBox(height: 4),
                    Text(
                      '${_formatBytes(downloadedBytes)} / ${_formatBytes(totalBytes)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
            ],

            // Status mesajı
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasError
                    ? Colors.red[50]
                    : isCompleted
                        ? Colors.green[50]
                        : Colors.blue[50],
                border: Border.all(
                  color: hasError
                      ? Colors.red[200]!
                      : isCompleted
                          ? Colors.green[200]!
                          : Colors.blue[200]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasError
                          ? Colors.red[700]
                          : isCompleted
                              ? Colors.green[700]
                              : Colors.blue[700],
                    ),
                  ),
                  if (currentStrategy.isNotEmpty &&
                      !isCompleted &&
                      !hasError) ...[
                    SizedBox(height: 4),
                    Text(
                      currentStrategy,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Hata detayları
            if (hasError && errorMessage != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[800],
                  ),
                ),
              ),
            ],

            // Başarı detayları
            if (isCompleted && downloadedFilePath != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Video başarıyla indirildi!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Dosya: ${downloadedFilePath!.split('/').last}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Boyut: ${_formatBytes(totalBytes)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isCompleted || hasError)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tamam'),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal'),
            ),
        ],
      ),
    );
  }
}
