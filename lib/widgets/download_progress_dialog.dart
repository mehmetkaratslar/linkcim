import 'package:flutter/material.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

class DownloadProgressDialog extends StatefulWidget {
  final SavedVideo video;
  final String? format;
  final String? quality;

  const DownloadProgressDialog({
    Key? key,
    required this.video,
    this.format = 'mp4',
    this.quality = 'medium',
  }) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double progress = 0.0;
  String status = 'İndirme başlatılıyor...';
  String stage = 'Hazırlanıyor';
  bool isCompleted = false;
  bool hasError = false;
  String? errorMessage;
  String? downloadedFilePath;
  String? speed;
  String? eta;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      setState(() {
        status =
            '${widget.video.platform.toUpperCase()} video URL\'si alınıyor...';
      });

      final result = await VideoDownloadService.downloadVideo(
        videoUrl: widget.video.videoUrl,
        platform: widget.video.platform,
        customFileName: _generateFileName(),
        format: widget.format ?? 'mp4',
        quality: widget.quality ?? 'medium',
        onProgress: (downloadProgress) {
          setState(() {
            progress = downloadProgress;

            // Progress durumuna göre stage ve status güncelle
            if (downloadProgress < 0.1) {
              stage = 'Başlatılıyor';
              status = 'Video bilgileri alınıyor...';
            } else if (downloadProgress < 0.3) {
              stage = 'Hazırlanıyor';
              status = 'İndirme hazırlanıyor...';
            } else if (downloadProgress < 0.9) {
              stage = 'İndiriliyor';
              status = 'İndiriliyor... ${(downloadProgress * 100).toInt()}%';
            } else if (downloadProgress < 1.0) {
              stage = 'Tamamlanıyor';
              status = 'Son işlemler yapılıyor...';
            } else {
              stage = 'Tamamlandı';
              status = 'İndirme tamamlandı!';
            }
          });
        },
      );

      if (result['success'] == true) {
        setState(() {
          isCompleted = true;
          progress = 1.0;
          status = 'İndirme tamamlandı!';
          downloadedFilePath = result['file_path'];
        });

        // İndirme geçmişine kaydet
        await _saveToDownloadHistory(result);
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['error'] ?? 'Bilinmeyen hata';
          status = 'İndirme başarısız!';
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        status = 'İndirme hatası!';
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
    final extension = widget.format ?? 'mp4';

    return '${platform}_${cleanTitle}_$timestamp.$extension';
  }

  Future<void> _saveToDownloadHistory(Map<String, dynamic> result) async {
    try {
      final filePath = result['file_path'] as String;
      var fileSize = result['file_size'] as int? ?? 0;
      final fileName = filePath.split('/').last;

      // Dosya boyutunu kontrol et
      if (fileSize == 0) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            fileSize = await file.length();
          }
        } catch (e) {
          print('Dosya boyutu okunamadı: $e');
        }
      }
      final downloadDate = DateTime.now();

      // Hive veritabanına kaydet
      final box = await Hive.openBox('downloadHistory');
      final currentHistory = box.get('downloads', defaultValue: <dynamic>[]);
      final historyList = <Map<String, dynamic>>[];

      // Mevcut verileri güvenli şekilde dönüştür
      if (currentHistory is List) {
        for (var item in currentHistory) {
          if (item is Map) {
            historyList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      // Yeni indirme kaydı
      final downloadRecord = {
        'file_name': fileName,
        'file_path': filePath,
        'file_size': fileSize,
        'download_date': downloadDate,
        'title': widget.video.title,
        'platform': widget.video.platform,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Listeye ekle (en yeniler başta)
      historyList.insert(0, downloadRecord);

      // Maksimum 100 kayıt tut
      if (historyList.length > 100) {
        historyList.removeRange(100, historyList.length);
      }

      // Veritabanına kaydet
      await box.put('downloads', historyList);

      print(
          '📝 İndirme geçmişine kaydedildi: $fileName (${historyList.length} toplam kayıt)');
    } catch (e) {
      print('❌ Geçmiş kaydetme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => isCompleted || hasError,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              hasError
                  ? Icons.error
                  : isCompleted
                      ? Icons.check_circle
                      : Icons.download,
              color: hasError
                  ? Colors.red
                  : isCompleted
                      ? Colors.green
                      : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasError
                    ? 'İndirme Hatası'
                    : isCompleted
                        ? 'İndirme Tamamlandı'
                        : 'Video İndiriliyor',
                style: TextStyle(fontSize: 16),
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
                      const SizedBox(width: 4),
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
                  const SizedBox(height: 4),
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

            const SizedBox(height: 16),

            // Progress bar ve detaylar (sadece indirme sırasında)
            if (!hasError && !isCompleted) ...[
              // Stage gösterimi
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      stage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Animasyonlu progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: MediaQuery.of(context).size.width * 0.7 * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Status mesajı - daha büyük ve belirgin
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: hasError
                      ? Colors.red[700]
                      : isCompleted
                          ? Colors.green[700]
                          : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Hata mesajı
            if (hasError && errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
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

            // Başarı mesajı
            if (isCompleted && downloadedFilePath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video başarıyla indirildi!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dosya: ${downloadedFilePath!.split('/').last}',
                      style: TextStyle(
                        fontSize: 11,
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
              child: const Text('Tamam'),
            )
          else
            TextButton(
              onPressed: () {
                // TODO: İndirmeyi iptal etme özelliği eklenebilir
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
        ],
      ),
    );
  }
}
