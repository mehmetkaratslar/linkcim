// Dosya Konumu: lib/screens/download_history_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:linkcim/screens/local_video_player_screen.dart';

class DownloadHistoryScreen extends StatefulWidget {
  @override
  _DownloadHistoryScreenState createState() => _DownloadHistoryScreenState();
}

class _DownloadHistoryScreenState extends State<DownloadHistoryScreen> {
  List<Map<String, dynamic>> downloadHistory = [];
  bool isLoading = true;
  Map<String, String> thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadHistory();
  }

  Future<void> _loadDownloadHistory() async {
    try {
      final box = await Hive.openBox('downloadHistory');
      final history = box.get('downloads', defaultValue: <dynamic>[]);

      final historyList = <Map<String, dynamic>>[];

      // Mevcut verileri güvenli şekilde dönüştür
      if (history is List) {
        for (var item in history) {
          if (item is Map) {
            historyList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() {
        downloadHistory = historyList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Geçmiş yüklenirken hata: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      // Cache'de var mı kontrol et
      if (thumbnailCache.containsKey(videoPath)) {
        final cachedPath = thumbnailCache[videoPath]!;
        if (await File(cachedPath).exists()) {
          return cachedPath;
        }
      }

      // Video dosyası var mı kontrol et
      if (!await File(videoPath).exists()) {
        print('❌ Video dosyası bulunamadı: $videoPath');
        return null;
      }

      // Thumbnail oluştur
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 85,
        timeMs: 1000, // İlk saniyeden thumbnail al
      );

      if (thumbnailPath != null) {
        thumbnailCache[videoPath] = thumbnailPath;
        print('✅ Thumbnail oluşturuldu: $thumbnailPath');
        return thumbnailPath;
      }
    } catch (e) {
      print('❌ Thumbnail oluşturma hatası: $e');
    }
    return null;
  }

  Widget _buildVideoThumbnail(String videoPath) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: FutureBuilder<String?>(
          future: _generateThumbnail(videoPath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Loading durumu
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[300]!, Colors.grey[200]!],
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              // Gerçek thumbnail
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultThumbnail();
                    },
                  ),
                  // Play button overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  // MP4 badge
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MP4',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Hata durumu veya thumbnail oluşturulamadı
            return _buildDefaultThumbnail();
          },
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[100]!,
            Colors.blue[50]!,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.play_circle_filled,
            size: 35,
            color: Colors.blue[600],
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'MP4',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(String filePath, int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dosyayı Sil'),
        content: Text('Bu videoyu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final file = File(filePath);
                if (await file.exists()) {
                  await file.delete();
                }

                setState(() {
                  downloadHistory.removeAt(index);
                });

                final box = await Hive.openBox('downloadHistory');
                await box.put('downloads', downloadHistory);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Video silindi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showError('Silme hatası: $e');
              }
            },
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'İndirilen Videolar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
        actions: [
          if (downloadHistory.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${downloadHistory.length} video',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Videolar yükleniyor...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : downloadHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDownloadHistory,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: downloadHistory.length,
                    itemBuilder: (context, index) {
                      return _buildDownloadItem(downloadHistory[index], index);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Henüz İndirilen Video Yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Ana sayfadan video linklerini yapıştırarak\nvideoları cihazınıza indirebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(Map<String, dynamic> item, int index) {
    final fileName = item['file_name'] as String? ?? 'Bilinmeyen Dosya';
    final filePath = item['file_path'] as String? ?? '';
    final fileSize = item['file_size'] as int? ?? 0;
    final downloadDate = item['download_date'] as DateTime? ?? DateTime.now();
    final platform = _extractPlatformFromFileName(fileName);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Platform badge ve tarih
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getPlatformColor(platform),
                          _getPlatformColor(platform).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _getPlatformColor(platform).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPlatformIcon(platform),
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          platform,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _formatDate(downloadDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Video bilgileri
              Row(
                children: [
                  // Video thumbnail - gerçek video kapağı
                  _buildVideoThumbnail(filePath),

                  SizedBox(width: 16),

                  // Video detayları - daha güzel
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName.replaceAll('.mp4', '').replaceAll('_', ' '),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storage_rounded,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                _formatFileSize(fileSize),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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

              SizedBox(height: 20),

              // Alt kısım - Şık butonlar
              Row(
                children: [
                  // Oynatma butonu - ana buton
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: () => _playVideo(filePath, fileName),
                        icon: Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(
                          'Oynat',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.blue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10),

                  // Galeriye kaydet butonu
                  Expanded(
                    child: Container(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () => _saveToGallery(filePath, fileName),
                        child: Icon(Icons.save_alt_rounded, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.green.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10),

                  // Paylaşma butonu
                  Expanded(
                    child: Container(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () => _shareFile(filePath),
                        child: Icon(Icons.share_rounded, size: 20),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.orange.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 10),

                  // Menü butonu - daha şık
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'info':
                            _showFileInfo(item);
                            break;
                          case 'delete':
                            _deleteFile(filePath, index);
                            break;
                        }
                      },
                      icon: Icon(Icons.more_vert_rounded,
                          color: Colors.grey[700]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Text('Detaylar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Sil'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractPlatformFromFileName(String fileName) {
    if (fileName.contains('instagram') || fileName.contains('Instagram')) {
      return 'Instagram';
    } else if (fileName.contains('youtube') || fileName.contains('YouTube')) {
      return 'YouTube';
    } else if (fileName.contains('tiktok') || fileName.contains('TikTok')) {
      return 'TikTok';
    } else if (fileName.contains('twitter') || fileName.contains('Twitter')) {
      return 'Twitter';
    }
    return 'Diğer';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Colors.red;
      case 'instagram':
        return Colors.purple;
      case 'tiktok':
        return Colors.black;
      case 'twitter':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return Icons.play_circle;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return Icons.video_library;
    }
  }

  Future<void> _playVideo(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('Video dosyası bulunamadı: $filePath');
        return;
      }

      print('🎬 Uygulama içi video oynatıcı açılıyor: $filePath');

      // Uygulama içi video oynatıcıyı aç
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocalVideoPlayerScreen(
            videoPath: filePath,
            videoTitle: fileName.replaceAll('.mp4', ''),
          ),
        ),
      );
    } catch (e) {
      _showError('Video oynatma hatası: $e');
    }
  }

  Future<void> _saveToGallery(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('Video dosyası bulunamadı');
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Galeriye kaydediliyor...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Save to gallery
      await Gal.putVideo(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Video galeriye kaydedildi!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showError('Galeriye kaydetme hatası: $e');
      }
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _showError('Video dosyası bulunamadı');
        return;
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Linkcim uygulamasından indirilen video',
      );
    } catch (e) {
      _showError('Video paylaşılamadı: $e');
    }
  }

  void _showFileInfo(Map<String, dynamic> item) {
    final fileName = item['file_name'] as String;
    final filePath = item['file_path'] as String;
    final fileSize = item['file_size'] as int;
    final downloadDate = item['download_date'] as DateTime;
    final platform = _extractPlatformFromFileName(fileName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.info_outline, color: Colors.blue),
            ),
            SizedBox(width: 12),
            Text(
              'Video Detayları',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Dosya Adı:', fileName),
            _buildInfoRow('Platform:', platform),
            _buildInfoRow('Boyut:', _formatFileSize(fileSize)),
            _buildInfoRow('İndirilme Tarihi:', _formatDate(downloadDate)),
            _buildInfoRow('Dosya Yolu:', filePath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue[50],
              foregroundColor: Colors.blue[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
