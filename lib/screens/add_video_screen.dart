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

  // Yeni özellikler için
  File? selectedVideoFile;
  File? extractedAudioFile;
  File? videoThumbnail;
  String analysisProgress = '';
  bool hasTranscript = false;
  bool hasVisualAnalysis = false;

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

  // 📹 Video dosyası seçme
  Future<void> _pickVideoFile() async {
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

        // Video thumbnail oluştur
        await _generateThumbnail();

        _showSuccess('📹 Video dosyası seçildi: ${result.files.single.name}');
      }
    } catch (e) {
      _showError('Video seçme hatası: $e');
    }
  }

  // 🖼️ Video thumbnail oluşturma
  Future<void> _generateThumbnail() async {
    if (selectedVideoFile == null) return;

    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: selectedVideoFile!.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );

      if (thumbnail != null) {
        setState(() {
          videoThumbnail = File(thumbnail);
        });
      }
    } catch (e) {
      print('Thumbnail oluşturma hatası: $e');
    }
  }

  // 🌐 Platform bilgisi ile gelişmiş analiz
  Future<void> _advancedAIAnalysisWithPlatform() async {
    if (_titleController.text.isEmpty &&
        selectedVideoFile == null &&
        _urlController.text.isEmpty) {
      _showError('Analiz için başlık girin, video seçin veya URL girin');
      return;
    }

    setState(() {
      isAnalyzing = true;
      analysisProgress = 'Platform analizi başlatılıyor...';
      hasTranscript = false;
      hasVisualAnalysis = false;
    });

    try {
      String? platformInfo;
      String? videoTitle = _titleController.text;

      // 1. URL'den platform metadata'sı çek
      if (_urlController.text.isNotEmpty &&
          AppConstants.isValidVideoUrl(_urlController.text)) {
        setState(() => analysisProgress = '🌐 Video bilgileri çekiliyor...');

        final metadata =
            await VideoPlatformService.getVideoMetadata(_urlController.text);
        if (metadata['success'] == true) {
          videoTitle = metadata['title'] ?? videoTitle;
          platformInfo = '''
Platform: ${metadata['platform']}
Başlık: ${metadata['title']}
Yükleyen: ${metadata['author']}
Açıklama: ${metadata['description']}''';

          print('✅ Platform metadata alındı: ${metadata['platform']}');

          // Başlığı otomatik güncelle
          if (_titleController.text.isEmpty && metadata['title'] != null) {
            setState(() {
              _titleController.text = metadata['title'];
            });
          }
        }
      }

      // 2. Standart video analizi
      await _advancedAIAnalysis(
          customTitle: videoTitle, platformInfo: platformInfo);
    } catch (e) {
      _showError('Platform analizi hatası: $e');
      setState(() {
        isAnalyzing = false;
        analysisProgress = '';
      });
    }
  }

  // 🎵 Gelişmiş AI Analizi - Tüm özellikleri kullanan
  Future<void> _advancedAIAnalysis(
      {String? customTitle, String? platformInfo}) async {
    if (_titleController.text.isEmpty && selectedVideoFile == null) {
      _showError('Analiz için başlık girin veya video dosyası seçin');
      return;
    }

    setState(() {
      isAnalyzing = true;
      analysisProgress = 'Analiz başlatılıyor...';
      hasTranscript = false;
      hasVisualAnalysis = false;
    });

    try {
      File? audioFile;
      File? imageFile;

      // 1. Video varsa ses çıkar
      if (selectedVideoFile != null) {
        setState(() => analysisProgress = '🎵 Video sesini çıkarıyor...');
        audioFile = await _extractAudioFromVideo();
      }

      // 2. Thumbnail varsa görsel analiz için hazırla
      if (videoThumbnail != null) {
        setState(() => analysisProgress = '👁️ Görseli analiz ediyor...');
        imageFile = videoThumbnail;
      }

      // 3. Gelişmiş AI analizi çalıştır
      setState(
          () => analysisProgress = '🧠 AI ile gelişmiş analiz yapılıyor...');

      String analysisTitle = customTitle ?? _titleController.text;
      if (platformInfo != null) {
        analysisTitle = '$analysisTitle\n\nPlatform Bilgileri:\n$platformInfo';
      }

      final result = await AIService.analyzeVideo(
        title: analysisTitle.isNotEmpty ? analysisTitle : null,
        audioFile: audioFile,
        imageFile: imageFile,
      );

      if (result['success'] == true) {
        setState(() {
          _descriptionController.text = result['description'] ?? '';
          _categoryController.text = result['category'] ?? '';
          tags = List<String>.from(result['tags'] ?? []);
          hasTranscript = result['has_transcript'] == true;
          hasVisualAnalysis = result['has_visual'] == true;
        });

        String successMessage = '✨ Gelişmiş AI analizi tamamlandı';
        if (hasTranscript) successMessage += ' (Ses analizi ✓)';
        if (hasVisualAnalysis) successMessage += ' (Görsel analizi ✓)';

        _showSuccess(successMessage);
      } else {
        _showError(
            'Analiz yapılamadı: ${result['error'] ?? 'Bilinmeyen hata'}');
      }

      // Geçici dosyaları temizle
      if (audioFile != null && await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      _showError('Gelişmiş analiz hatası: $e');
    } finally {
      setState(() {
        isAnalyzing = false;
        analysisProgress = '';
      });
    }
  }

  // 🎤 Video'dan ses çıkarma (FFmpeg kullanarak)
  Future<File?> _extractAudioFromVideo() async {
    if (selectedVideoFile == null) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/extracted_audio.mp3';

      // Bu örnekte basit bir ses çıkarma işlemi simüle ediyoruz
      // Gerçek uygulamada ffmpeg_kit_flutter kullanılmalı

      // Placeholder: Gerçek implementasyon için ffmpeg gerekli
      // final command = '-i ${selectedVideoFile!.path} -vn -acodec mp3 $audioPath';
      // await FFmpegKit.execute(command);

      // Şimdilik null dönelim, ses analizi olmadan çalışsın
      return null;
    } catch (e) {
      print('Ses çıkarma hatası: $e');
      return null;
    }
  }

  // 📝 Basit AI Analizi (eski versiyon)
  Future<void> _analyzeWithAI() async {
    if (_titleController.text.isEmpty) {
      _showError('Analiz için önce başlık giriniz');
      return;
    }

    setState(() => isAnalyzing = true);

    try {
      final result = await AIService.advancedVideoAnalysis(
        title: _titleController.text,
      );

      if (result['success']) {
        setState(() {
          _descriptionController.text = result['description'];
          _categoryController.text = result['category'];
          tags = List<String>.from(result['tags']);
        });

        if (result['source'] == 'gpt-4o-advanced') {
          _showSuccess('✨ AI analizi tamamlandı');
        } else if (result['source'] == 'simple') {
          _showSuccess('📝 Basit analiz tamamlandı');
        } else {
          _showSuccess('📝 Analiz tamamlandı');
        }
      } else {
        _showError(
            'Analiz yapılamadı: ${result['error'] ?? 'Bilinmeyen hata'}');
      }
    } catch (e) {
      _showError('Analiz hatası: $e');
    } finally {
      setState(() => isAnalyzing = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !tags.contains(tag)) {
      setState(() {
        tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => tags.remove(tag));
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

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) return;

    // URL validasyon - Multi Platform
    if (!AppConstants.isValidVideoUrl(_urlController.text)) {
      _showError(
          'Gecerli bir video linki giriniz (Instagram, YouTube, TikTok)');
      return;
    }

    try {
      if (isEditing) {
        // Hive'da mevcut video objesini güncelle
        widget.video!.videoUrl = _urlController.text.trim();
        widget.video!.title = _titleController.text.trim();
        widget.video!.description = _descriptionController.text.trim();
        widget.video!.category = _categoryController.text.trim();
        widget.video!.tags = tags;
        await _dbService.updateVideo(widget.video!);
        _showSuccess('Video guncellendi');
      } else {
        // Platform bilgilerini al
        final platformData = await VideoPlatformService.getVideoMetadata(
            _urlController.text.trim());

        final video = SavedVideo.create(
          videoUrl: _urlController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          tags: tags,
          authorName: platformData['author_name'] ?? '',
          authorUsername: platformData['author_username'] ?? '',
          platform: AppConstants.detectPlatform(_urlController.text.trim()),
          thumbnailUrl: platformData['thumbnail_url'] ?? '',
        );
        await _dbService.addVideo(video);
        _showSuccess('Video kaydedildi');
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showError('Kayit hatasi: $e');
    }
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
        title: Text(isEditing ? 'Video Duzenle' : 'Yeni Video Ekle'),
        actions: [
          TextButton(
            onPressed: _saveVideo,
            child: Text(
              'KAYDET',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // URL girisi - Multi Platform
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Video Linki * (Instagram, YouTube, TikTok)',
                hintText:
                    'https://www.instagram.com/p/... veya https://youtu.be/... veya https://tiktok.com/@...',
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
                  return 'Video linki gerekli';
                }
                if (!AppConstants.isValidVideoUrl(value)) {
                  return 'Gecerli video linki giriniz (Instagram, YouTube, TikTok)';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  // URL'den otomatik baslik cikar
                  if (value.isNotEmpty && _titleController.text.isEmpty) {
                    _titleController.text =
                        AppConstants.extractTitleFromUrl(value);
                  }
                });
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
                    : IconButton(
                        icon: Icon(Icons.auto_awesome),
                        onPressed: _advancedAIAnalysis,
                        tooltip: 'AI ile Analiz Et',
                      ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Başlık gerekli';
                }
                return null;
              },
            ),

            SizedBox(height: 8),

            // AI analiz butonu
            ElevatedButton.icon(
              onPressed: isAnalyzing ? null : _advancedAIAnalysis,
              icon: isAnalyzing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.auto_awesome),
              label:
                  Text(isAnalyzing ? 'Analiz Ediliyor...' : 'AI ile Analiz Et'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[100],
                foregroundColor: Colors.purple[800],
              ),
            ),

            // 📱 Gelişmiş özellikler bölümü
            if (analysisProgress.isNotEmpty) ...[
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
              SizedBox(height: 16),
            ],

            // 📹 Video dosyası seçme bölümü
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Gelişmiş AI Analizi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video dosyası yükleyerek ses ve görsel analizi yapabilirsiniz',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isAnalyzing ? null : _pickVideoFile,
                            icon: Icon(Icons.video_file),
                            label: Text('Video Seç'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[100],
                              foregroundColor: Colors.orange[800],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isAnalyzing
                                ? null
                                : _advancedAIAnalysisWithPlatform,
                            icon: Icon(Icons.auto_awesome),
                            label: Text('Akıllı Analiz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[100],
                              foregroundColor: Colors.purple[800],
                            ),
                          ),
                        ),
                      ],
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
                        height: 100,
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
                    if (hasTranscript || hasVisualAnalysis) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (hasTranscript) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic,
                                      size: 12, color: Colors.blue[800]),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ses Analizi',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.blue[800]),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          if (hasVisualAnalysis) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility,
                                      size: 12, color: Colors.purple[800]),
                                  SizedBox(width: 4),
                                  Text(
                                    'Görsel Analizi',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.purple[800]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),

            SizedBox(height: 16),

            // Kategori girisi
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
                  backgroundColor: Colors.blue[50],
                );
              }).toList(),
            ),

            SizedBox(height: 16),

            // Etiket girisi
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: 'Etiket Ekle',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    onFieldSubmitted: (_) => _addTag(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  child: Text('Ekle'),
                ),
              ],
            ),

            SizedBox(height: 8),

            // Popüler etiket önerileri
            if (tags.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popüler Etiketler:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.popularTags.map((tag) {
                      return ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          if (!tags.contains(tag)) {
                            setState(() => tags.add(tag));
                          }
                        },
                        backgroundColor: Colors.green[50],
                      );
                    }).toList(),
                  ),
                ],
              ),

            SizedBox(height: 16),

            // Eklenen etiketler
            if (tags.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Etiketler:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
