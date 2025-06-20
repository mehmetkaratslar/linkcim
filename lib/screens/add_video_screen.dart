// Dosya Konumu: lib/screens/add_video_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:linkcim/models/saved_video.dart';
import 'package:linkcim/services/database_service.dart';
import 'package:linkcim/services/ai_service.dart';
import 'package:linkcim/services/video_platform_service.dart';
import 'package:linkcim/services/video_download_service.dart';
import 'package:linkcim/utils/constants.dart';
import 'package:linkcim/widgets/tag_chip.dart';

class AddVideoScreen extends StatefulWidget {
  final SavedVideo? video;

  AddVideoScreen({this.video});

  @override
  _AddVideoScreenState createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();

  List<String> tags = [];
  bool isAnalyzing = false;
  bool isEditing = false;
  bool autoDownloadEnabled = false;

  // Gelişmiş özellikler
  File? selectedVideoFile;
  File? extractedAudioFile;
  File? videoThumbnail;
  String analysisProgress = '';
  Map<String, dynamic> platformData = {};
  Map<String, dynamic> userInfo = {};
  Map<String, dynamic> analysisResult = {};

  // AI Analiz durumu
  bool hasTranscript = false;
  bool hasVisualAnalysis = false;
  bool hasPlatformData = false;
  bool hasUserInfo = false;
  double analysisConfidence = 0.0;

  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    if (widget.video != null) {
      isEditing = true;
      _populateFields();
    }
  }

  void _populateFields() {
    final video = widget.video!;
    _urlController.text = video.videoUrl;
    _titleController.text = video.title;
    _descriptionController.text = video.description;
    _categoryController.text = video.category;
    tags = List.from(video.tags);
  }

  // 🌐 Kapsamlı Platform ve AI Analizi
  Future<void> _performComprehensiveAnalysis() async {
    if (_urlController.text.isEmpty &&
        _titleController.text.isEmpty &&
        selectedVideoFile == null) {
      _showError(
          'Analiz için URL girin, başlık yazın veya video dosyası seçin');
      return;
    }

    setState(() {
      isAnalyzing = true;
      analysisProgress = 'Kapsamlı analiz başlatılıyor...';
      hasTranscript = false;
      hasVisualAnalysis = false;
      hasPlatformData = false;
      hasUserInfo = false;
      analysisConfidence = 0.0;
    });

    try {
      String videoUrl = _urlController.text.trim();
      String platform = '';

      // 1. Platform Analizi
      if (videoUrl.isNotEmpty && AppConstants.isValidVideoUrl(videoUrl)) {
        setState(() => analysisProgress = '🌐 Platform bilgileri alınıyor...');

        platform = AppConstants.detectPlatform(videoUrl);
        platformData = await VideoPlatformService.getVideoMetadata(videoUrl);

        if (platformData['success'] == true) {
          setState(() {
            hasPlatformData = true;

            // Platform verilerini form alanlarına doldur
            if (_titleController.text.isEmpty &&
                platformData['title'] != null) {
              _titleController.text = platformData['title'];
            }

            if (_descriptionController.text.isEmpty &&
                platformData['description'] != null) {
              _descriptionController.text = platformData['description'];
            }

            // Kullanıcı bilgileri
            if (platformData['author'] != null ||
                platformData['author_name'] != null) {
              userInfo = {
                'author_name':
                    platformData['author_name'] ?? platformData['author'] ?? '',
                'username': platformData['author_username'] ?? '',
                'content_creator_type':
                    platformData['content_creator_type'] ?? '',
                'estimated_follower_range':
                    platformData['estimated_follower_range'] ?? '',
              };
              hasUserInfo = userInfo.isNotEmpty;
            }
          });

          _debugPrint('✅ Platform metadata alındı: $platform');
        }
      }

      // 2. Video Dosyası İşleme
      if (selectedVideoFile != null) {
        setState(() => analysisProgress = '🎬 Video dosyası işleniyor...');
        await _processVideoFile();
      }

      // 3. Gelişmiş AI Analizi
      setState(() => analysisProgress = '🧠 Gelişmiş AI analizi yapılıyor...');

      String analysisTitle = _titleController.text;
      if (platformData.isNotEmpty) {
        analysisTitle += '\n\nPlatform Bilgileri:\n';
        analysisTitle += 'Platform: ${platformData['platform'] ?? platform}\n';
        if (platformData['author'] != null) {
          analysisTitle += 'Yükleyen: ${platformData['author']}\n';
        }
        if (platformData['description'] != null) {
          analysisTitle += 'Açıklama: ${platformData['description']}\n';
        }
      }

      final aiResult = await AIService.analyzeVideo(
        title: analysisTitle.isNotEmpty ? analysisTitle : null,
        audioFile: extractedAudioFile,
        imageFile: videoThumbnail,
      );

      if (aiResult['success'] == true) {
        setState(() {
          analysisResult = aiResult;

          // AI sonuçlarını form alanlarına doldur
          if (_titleController.text.isEmpty ||
              _titleController.text == platformData['title']) {
            _titleController.text = aiResult['title'] ?? _titleController.text;
          }

          if (_descriptionController.text.isEmpty ||
              _descriptionController.text == platformData['description']) {
            _descriptionController.text =
                aiResult['description'] ?? _descriptionController.text;
          }

          if (_categoryController.text.isEmpty) {
            _categoryController.text = aiResult['category'] ?? 'Genel';
          }

          if (tags.isEmpty) {
            tags = List<String>.from(aiResult['tags'] ?? []);
          }

          // Analiz durumları
          hasTranscript = aiResult['has_transcript'] == true;
          hasVisualAnalysis = aiResult['has_visual'] == true;
          analysisConfidence = _parseConfidence(aiResult['confidence']);
        });

        // Başarı mesajı
        String successMessage = '✨ Kapsamlı AI analizi tamamlandı';
        if (hasTranscript) successMessage += ' (Ses ✓)';
        if (hasVisualAnalysis) successMessage += ' (Görsel ✓)';
        if (hasPlatformData) successMessage += ' (Platform ✓)';
        if (hasUserInfo) successMessage += ' (Kullanıcı ✓)';

        _showSuccess(successMessage);
      } else {
        _showError(
            'AI analizi başarısız: ${aiResult['error'] ?? 'Bilinmeyen hata'}');
      }

      // 4. Otomatik İndirme (İsteğe bağlı)
      if (autoDownloadEnabled &&
          videoUrl.isNotEmpty &&
          AppConstants.isValidVideoUrl(videoUrl)) {
        setState(() => analysisProgress = '📥 Video otomatik indiriliyor...');
        await _performAutoDownload(videoUrl, platform);
      }
    } catch (e) {
      _showError('Kapsamlı analiz hatası: $e');
    } finally {
      setState(() {
        isAnalyzing = false;
        analysisProgress = '';
      });
    }
  }

  // 📱 Video Dosyası Seçme ve İşleme
  Future<void> _pickAndProcessVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          selectedVideoFile = File(result.files.single.path!);
          _titleController.text = result.files.single.name.split('.').first;
        });

        await _processVideoFile();
        _showSuccess('📹 Video dosyası başarıyla seçildi ve işlendi');
      }
    } catch (e) {
      _showError('Video seçme hatası: $e');
    }
  }

  // 🎬 Video Dosyası İşleme
  Future<void> _processVideoFile() async {
    if (selectedVideoFile == null) return;

    try {
      // Video thumbnail oluştur
      await _generateThumbnail();

      // Ses çıkarma (isteğe bağlı - ffmpeg gerekir)
      // await _extractAudioFromVideo();
    } catch (e) {
      _debugPrint('Video işleme hatası: $e');
    }
  }

  // 🖼️ Video Thumbnail Oluşturma
  Future<void> _generateThumbnail() async {
    if (selectedVideoFile == null) return;

    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: selectedVideoFile!.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 85,
      );

      if (thumbnail != null) {
        setState(() {
          videoThumbnail = File(thumbnail);
        });
        _debugPrint('✅ Video thumbnail oluşturuldu');
      }
    } catch (e) {
      _debugPrint('Thumbnail oluşturma hatası: $e');
    }
  }

  // 📥 Otomatik Video İndirme
  Future<void> _performAutoDownload(String videoUrl, String platform) async {
    try {
      final downloadResult = await VideoDownloadService.downloadVideo(
        videoUrl: videoUrl,
        platform: platform,
        customFileName: _generateDownloadFileName(),
        onProgress: (progress) {
          setState(() {
            analysisProgress = '📥 İndiriliyor... ${(progress * 100).toInt()}%';
          });
        },
      );

      if (downloadResult['success'] == true) {
        _showSuccess(
            '🎉 Video başarıyla indirildi: ${downloadResult['file_name']}');
      } else {
        _debugPrint('Otomatik indirme başarısız: ${downloadResult['error']}');
      }
    } catch (e) {
      _debugPrint('Otomatik indirme hatası: $e');
    }
  }

  String _generateDownloadFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final platform =
        AppConstants.detectPlatform(_urlController.text).toLowerCase();
    final cleanTitle = _titleController.text
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    return '${platform}_${cleanTitle.isNotEmpty ? cleanTitle : 'video'}_$timestamp.mp4';
  }

  // 🏷️ Etiket Yönetimi
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !tags.contains(tag) && tags.length < 10) {
      setState(() {
        tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => tags.remove(tag));
  }

  // 🎯 AI Önerilerini Uygula
  void _applyAISuggestions() {
    if (analysisResult.isNotEmpty) {
      setState(() {
        if (analysisResult['title'] != null) {
          _titleController.text = analysisResult['title'];
        }
        if (analysisResult['description'] != null) {
          _descriptionController.text = analysisResult['description'];
        }
        if (analysisResult['category'] != null) {
          _categoryController.text = analysisResult['category'];
        }
        if (analysisResult['tags'] != null) {
          tags = List<String>.from(analysisResult['tags']);
        }
      });
      _showSuccess('AI önerileri uygulandı');
    }
  }

  // 💾 Video Kaydetme
  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_urlController.text.isNotEmpty &&
        !AppConstants.isValidVideoUrl(_urlController.text)) {
      _showError(
          'Geçerli bir video linki giriniz (Instagram, YouTube, TikTok, Twitter)');
      return;
    }

    try {
      if (isEditing) {
        // Güncelleme
        widget.video!.videoUrl = _urlController.text.trim();
        widget.video!.title = _titleController.text.trim();
        widget.video!.description = _descriptionController.text.trim();
        widget.video!.category = _categoryController.text.trim();
        widget.video!.tags = tags;

        // Kullanıcı bilgilerini güncelle
        if (userInfo.isNotEmpty) {
          widget.video!.authorName =
              userInfo['author_name'] ?? widget.video!.authorName;
          widget.video!.authorUsername =
              userInfo['username'] ?? widget.video!.authorUsername;
        }

        await _dbService.updateVideo(widget.video!);
        _showSuccess('Video güncellendi');
      } else {
        // Yeni video ekleme
        final video = SavedVideo.create(
          videoUrl: _urlController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          tags: tags,
          authorName: userInfo['author_name'] ?? platformData['author'] ?? '',
          authorUsername: userInfo['username'] ?? '',
          platform: AppConstants.detectPlatform(_urlController.text.trim()),
          thumbnailUrl: platformData['thumbnail'] ?? '',
        );

        await _dbService.addVideo(video);
        _showSuccess('Video başarıyla kaydedildi');
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Kayıt hatası: $e');
    }
  }

  // 🛠️ Yardımcı Fonksiyonlar
  double _parseConfidence(dynamic confidence) {
    if (confidence == null) return 0.0;
    if (confidence is double) return confidence;
    if (confidence is String) {
      switch (confidence.toLowerCase()) {
        case 'high':
          return 0.9;
        case 'medium':
          return 0.6;
        case 'low':
          return 0.3;
        default:
          return 0.0;
      }
    }
    return 0.0;
  }

  void _debugPrint(String message) {
    if (AppConstants.debugMode) {
      print('[Enhanced Add Video] $message');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
        ),
        title: Text(isEditing ? 'Video Düzenle' : 'Yeni Video Ekle'),
        actions: [
          if (analysisResult.isNotEmpty)
            IconButton(
              icon: Icon(Icons.auto_fix_high),
              onPressed: _applyAISuggestions,
              tooltip: 'AI Önerilerini Uygula',
            ),
          TextButton(
            onPressed: _saveVideo,
            child: Text(
              'KAYDET',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // URL girişi
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Video Linki (Instagram, YouTube, TikTok, Twitter)',
                hintText:
                    'https://www.instagram.com/p/... veya https://youtu.be/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                suffixIcon: _urlController.text.isNotEmpty
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(AppConstants.getPlatformColor(
                            AppConstants.detectPlatform(_urlController.text))),
                        child: Text(
                          AppConstants.platformEmojis[
                                  AppConstants.detectPlatform(
                                      _urlController.text)] ??
                              '🎬',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  if (selectedVideoFile == null) {
                    return 'Video linki veya dosya gerekli';
                  }
                  return null;
                }
                if (!AppConstants.isValidVideoUrl(value)) {
                  return 'Geçerli video linki giriniz';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {});
              },
            ),

            SizedBox(height: 16),

            // Başlık girişi
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Video Başlığı *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                suffixIcon: isAnalyzing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Başlık gerekli';
                }
                return null;
              },
              maxLength: 150,
            ),

            SizedBox(height: 8),

            // Ana analiz butonu
            ElevatedButton.icon(
              onPressed: isAnalyzing ? null : _performComprehensiveAnalysis,
              icon: isAnalyzing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.auto_awesome),
              label: Text(isAnalyzing
                  ? 'Analiz Ediliyor...'
                  : '🚀 Kapsamlı AI Analizi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 8),

            // Otomatik indirme seçeneği
            Row(
              children: [
                Switch(
                  value: autoDownloadEnabled,
                  onChanged: (value) {
                    setState(() {
                      autoDownloadEnabled = value;
                    });
                  },
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analiz sırasında videoyu otomatik indir',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

            // Analiz durumu
            if (analysisProgress.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text(analysisProgress)),
                  ],
                ),
              ),
            ],

            // Analiz sonuçları özeti
            if (!isAnalyzing &&
                (hasPlatformData ||
                    hasTranscript ||
                    hasVisualAnalysis ||
                    hasUserInfo)) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.green[700]),
                        SizedBox(width: 8),
                        Text(
                          'Analiz Sonuçları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasPlatformData)
                          _buildAnalysisChip('Platform Verisi', Colors.blue),
                        if (hasTranscript)
                          _buildAnalysisChip('Ses Analizi', Colors.orange),
                        if (hasVisualAnalysis)
                          _buildAnalysisChip('Görsel Analizi', Colors.purple),
                        if (hasUserInfo)
                          _buildAnalysisChip('Kullanıcı Bilgisi', Colors.green),
                        if (analysisConfidence > 0)
                          _buildAnalysisChip(
                              'Güven: ${(analysisConfidence * 100).toInt()}%',
                              analysisConfidence > 0.7
                                  ? Colors.green
                                  : analysisConfidence > 0.4
                                      ? Colors.orange
                                      : Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Gelişmiş video işleme bölümü
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎬 Video Dosyası İşleme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video dosyası yükleyerek daha detaylı analiz yapabilirsiniz',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isAnalyzing ? null : _pickAndProcessVideoFile,
                      icon: Icon(Icons.video_file),
                      label: Text('Video Dosyası Seç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[100],
                        foregroundColor: Colors.indigo[800],
                      ),
                    ),
                    if (selectedVideoFile != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Video: ${selectedVideoFile!.path.split('/').last}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (videoThumbnail != null) ...[
                      SizedBox(height: 8),
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            videoThumbnail!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Açıklama girişi
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Video Açıklaması',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLength: 1000,
            ),

            SizedBox(height: 16),

            // Kategori girişi
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Kategori *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kategori gerekli';
                }
                return null;
              },
            ),

            SizedBox(height: 8),

            // Kategori önerileri
            Wrap(
              spacing: 8,
              children: AppConstants.defaultCategories.map((category) {
                return ActionChip(
                  label: Text(category),
                  onPressed: () {
                    _categoryController.text = category;
                  },
                  backgroundColor: _categoryController.text == category
                      ? Colors.blue[100]
                      : Colors.grey[100],
                );
              }).toList(),
            ),

            SizedBox(height: 16),

            // Etiket girişi
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: 'Etiket Ekle',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                      suffixText: '${tags.length}/10',
                    ),
                    onFieldSubmitted: (_) => _addTag(),
                    enabled: tags.length < 10,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: tags.length < 10 ? _addTag : null,
                  child: Text('Ekle'),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Popüler etiket önerileri
            if (tags.isEmpty) ...[
              Text(
                'Popüler Etiketler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: AppConstants.popularTags.map((tag) {
                  return ActionChip(
                    label: Text(tag),
                    onPressed: () {
                      if (!tags.contains(tag) && tags.length < 10) {
                        setState(() => tags.add(tag));
                      }
                    },
                    backgroundColor: Colors.green[50],
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],

            // Eklenen etiketler
            if (tags.isNotEmpty) ...[
              Text(
                'Etiketler (${tags.length}/10):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return TagChip(
                    tag: tag,
                    onDeleted: () => _removeTag(tag),
                    showDelete: true,
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],

            // Platform ve kullanıcı bilgileri
            if (platformData.isNotEmpty || userInfo.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Platform ve Kullanıcı Bilgileri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      if (platformData.isNotEmpty) ...[
                        _buildInfoRow('Platform:',
                            platformData['platform'] ?? 'Bilinmiyor'),
                        if (platformData['author'] != null)
                          _buildInfoRow('Yükleyen:', platformData['author']),
                        if (platformData['duration'] != null)
                          _buildInfoRow(
                              'Süre:', '${platformData['duration']} saniye'),
                      ],
                      if (userInfo.isNotEmpty) ...[
                        if (platformData.isNotEmpty) Divider(),
                        if (userInfo['author_name'] != null)
                          _buildInfoRow('Kanal/İsim:', userInfo['author_name']),
                        if (userInfo['username'] != null)
                          _buildInfoRow(
                              'Kullanıcı Adı:', '@${userInfo['username']}'),
                        if (userInfo['content_creator_type'] != null)
                          _buildInfoRow(
                              'İçerik Türü:', userInfo['content_creator_type']),
                        if (userInfo['estimated_follower_range'] != null)
                          _buildInfoRow('Takipçi Aralığı:',
                              userInfo['estimated_follower_range']),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // AI Analiz detayları
            if (analysisResult.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧠 AI Analiz Detayları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      SizedBox(height: 12),

                      if (analysisResult['content_type'] != null)
                        _buildInfoRow(
                            'İçerik Türü:', analysisResult['content_type']),
                      if (analysisResult['target_audience'] != null)
                        _buildInfoRow(
                            'Hedef Kitle:', analysisResult['target_audience']),
                      if (analysisResult['main_topic'] != null)
                        _buildInfoRow(
                            'Ana Konu:', analysisResult['main_topic']),
                      if (analysisResult['language'] != null)
                        _buildInfoRow('Dil:', analysisResult['language']),
                      if (analysisResult['mood'] != null)
                        _buildInfoRow('Atmosfer:', analysisResult['mood']),

                      // Puanlama sistemi
                      if (analysisResult['quality_score'] != null ||
                          analysisResult['engagement_potential'] != null ||
                          analysisResult['educational_value'] != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'AI Puanlaması (1-10):',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        if (analysisResult['quality_score'] != null)
                          _buildScoreBar(
                              'Kalite', analysisResult['quality_score']),
                        if (analysisResult['engagement_potential'] != null)
                          _buildScoreBar('Etkileşim Potansiyeli',
                              analysisResult['engagement_potential']),
                        if (analysisResult['educational_value'] != null)
                          _buildScoreBar('Eğitim Değeri',
                              analysisResult['educational_value']),
                        if (analysisResult['entertainment_value'] != null)
                          _buildScoreBar('Eğlence Değeri',
                              analysisResult['entertainment_value']),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),

            // Kaydet butonu (büyük)
            ElevatedButton(
              onPressed: _saveVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 24),
                  SizedBox(width: 8),
                  Text(
                    isEditing ? 'VİDEO GÜNCELLE' : 'VİDEO KAYDET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Yardımcı widget'lar
  Widget _buildAnalysisChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, dynamic score) {
    double scoreValue = 0.0;
    if (score is num) {
      scoreValue = score.toDouble();
    } else if (score is String) {
      scoreValue = double.tryParse(score) ?? 0.0;
    }

    Color barColor = scoreValue >= 7
        ? Colors.green
        : scoreValue >= 5
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: scoreValue / 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${scoreValue.toStringAsFixed(1)}/10',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}
