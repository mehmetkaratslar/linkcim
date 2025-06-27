// Dosya Konumu: lib/screens/add_video_screen.dart

import 'package:flutter/material.dart';
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
  bool isEditing = false;
  bool isAnalyzing = false;
  bool hasAnalyzed = false;
  Map<String, dynamic> aiSuggestions = {};

  final DatabaseService _dbService = DatabaseService();

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

  // 🤖 AI Analizi
  Future<void> _performAIAnalysis() async {
    if (_urlController.text.isEmpty) {
      _showError('Önce video linki girin');
      return;
    }

    if (!AppConstants.isValidVideoUrl(_urlController.text)) {
      _showError('Geçerli bir video linki girin');
      return;
    }

    setState(() {
      isAnalyzing = true;
    });

    try {
      // 1. Platform verilerini al
      final platform = AppConstants.detectPlatform(_urlController.text);
      final platformData =
          await VideoPlatformService.getVideoMetadata(_urlController.text);

      String analysisText = '';

      if (platformData['success'] == true) {
        analysisText = '''
Platform: $platform
Başlık: ${platformData['title'] ?? ''}
Açıklama: ${platformData['description'] ?? ''}
Yükleyen: ${platformData['author'] ?? ''}
''';
      } else {
        analysisText = 'Video URL: ${_urlController.text}\nPlatform: $platform';
      }

      // 2. AI analizi yap
      final aiResult = await AIService.analyzeVideo(
        title: analysisText,
      );

      if (aiResult['success'] == true) {
        setState(() {
          hasAnalyzed = true;
          aiSuggestions = {
            'title': aiResult['title'] ?? platformData['title'] ?? '',
            'description':
                aiResult['description'] ?? platformData['description'] ?? '',
            'category': aiResult['category'] ?? 'Genel',
            'tags': List<String>.from(aiResult['tags'] ?? []),
            'platform_data': platformData,
          };
        });

        _showSuccess('🤖 AI analizi tamamlandı! Önerileri uygulayabilirsiniz.');
      } else {
        // AI başarısız olsa bile platform verilerini kullan
        if (platformData['success'] == true) {
          setState(() {
            hasAnalyzed = true;
            aiSuggestions = {
              'title': platformData['title'] ?? '',
              'description': platformData['description'] ?? '',
              'category': 'Genel',
              'tags': <String>[],
              'platform_data': platformData,
            };
          });
          _showSuccess(
              '📊 Platform verileri alındı! Önerileri uygulayabilirsiniz.');
        } else {
          throw Exception(aiResult['error'] ?? 'AI analizi başarısız');
        }
      }
    } catch (e) {
      _showError('Analiz hatası: $e');
    } finally {
      setState(() {
        isAnalyzing = false;
      });
    }
  }

  // 🎯 AI Önerilerini Uygula
  void _applyAISuggestions() {
    if (aiSuggestions.isEmpty) return;

    setState(() {
      if (aiSuggestions['title'] != null &&
          aiSuggestions['title'].toString().isNotEmpty) {
        _titleController.text = aiSuggestions['title'];
      }
      if (aiSuggestions['description'] != null &&
          aiSuggestions['description'].toString().isNotEmpty) {
        _descriptionController.text = aiSuggestions['description'];
      }
      if (aiSuggestions['category'] != null &&
          aiSuggestions['category'].toString().isNotEmpty) {
        _categoryController.text = aiSuggestions['category'];
      }
      if (aiSuggestions['tags'] != null) {
        final suggestedTags = List<String>.from(aiSuggestions['tags']);
        tags = suggestedTags.take(10).toList(); // Maksimum 10 etiket
      }
    });

    _showSuccess('✨ AI önerileri uygulandı!');
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
          authorName: '',
          authorUsername: '',
          platform: AppConstants.detectPlatform(_urlController.text.trim()),
        );

        await _dbService.addVideo(video);
        _showSuccess('Video başarıyla kaydedildi');
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Kayıt hatası: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Video Düzenle' : 'Video Ekle',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Text(
                isEditing
                    ? '✏️ Video Bilgilerini Düzenle'
                    : '🎬 Yeni Video Ekle',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Video bilgilerini girin ve koleksiyonunuza ekleyin',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),

              // URL girişi
              _buildInputCard(
                child: TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Video Linki',
                    hintText:
                        'https://www.instagram.com/p/... veya https://youtu.be/...',
                    border: InputBorder.none,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.link, color: Colors.blue[600], size: 20),
                    ),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? Container(
                            margin: EdgeInsets.all(12),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(
                                  AppConstants.getPlatformColor(
                                      AppConstants.detectPlatform(
                                          _urlController.text))),
                              child: Text(
                                AppConstants.platformEmojis[
                                        AppConstants.detectPlatform(
                                            _urlController.text)] ??
                                    '🎬',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Video linki gerekli';
                    }
                    if (!AppConstants.isValidVideoUrl(value)) {
                      return 'Geçerli video linki giriniz';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
              ),

              SizedBox(height: 20),

              // AI Analiz Butonu
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    // AI Analiz butonu
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isAnalyzing ? null : _performAIAnalysis,
                          icon: isAnalyzing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(Icons.auto_awesome, size: 22),
                          label: Text(
                            isAnalyzing
                                ? 'Analiz Ediliyor...'
                                : '🤖 AI Analizi',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.purple.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // AI Önerilerini Uygula butonu (sadece analiz yapıldıysa göster)
                    if (hasAnalyzed && aiSuggestions.isNotEmpty) ...[
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _applyAISuggestions,
                            icon: Icon(Icons.auto_fix_high, size: 20),
                            label: Text(
                              'Uygula',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.green.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // AI Önerileri Kartı (sadece analiz yapıldıysa göster)
              if (hasAnalyzed && aiSuggestions.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[50]!, Colors.blue[50]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purple[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.psychology,
                                color: Colors.purple[700], size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '🤖 AI Önerileri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Hazır',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Önerilen başlık
                      if (aiSuggestions['title'] != null &&
                          aiSuggestions['title'].toString().isNotEmpty) ...[
                        _buildSuggestionRow(
                            'Başlık', aiSuggestions['title'], Icons.title),
                        SizedBox(height: 8),
                      ],

                      // Önerilen kategori
                      if (aiSuggestions['category'] != null &&
                          aiSuggestions['category'].toString().isNotEmpty) ...[
                        _buildSuggestionRow('Kategori',
                            aiSuggestions['category'], Icons.category),
                        SizedBox(height: 8),
                      ],

                      // Önerilen etiketler
                      if (aiSuggestions['tags'] != null &&
                          (aiSuggestions['tags'] as List).isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.tag,
                                size: 16, color: Colors.purple[600]),
                            SizedBox(width: 8),
                            Text(
                              'Etiketler:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.purple[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: (aiSuggestions['tags'] as List)
                              .take(5)
                              .map((tag) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple[300]!),
                              ),
                              child: Text(
                                tag.toString(),
                                style: TextStyle(
                                  color: Colors.purple[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Başlık girişi
              _buildInputCard(
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Video Başlığı',
                    hintText: 'Video başlığını girin',
                    border: InputBorder.none,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.title,
                          color: Colors.purple[600], size: 20),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Başlık gerekli';
                    }
                    return null;
                  },
                  maxLength: 150,
                ),
              ),

              SizedBox(height: 20),

              // Açıklama girişi
              _buildInputCard(
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Video Açıklaması',
                    hintText: 'Video hakkında açıklama yazın (isteğe bağlı)',
                    border: InputBorder.none,
                    prefixIcon: Container(
                      margin: EdgeInsets.all(12),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.description,
                          color: Colors.green[600], size: 20),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLength: 500,
                ),
              ),

              SizedBox(height: 20),

              // Kategori girişi
              _buildInputCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        hintText: 'Video kategorisini seçin',
                        border: InputBorder.none,
                        prefixIcon: Container(
                          margin: EdgeInsets.all(12),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.category,
                              color: Colors.orange[600], size: 20),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kategori gerekli';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.defaultCategories.map((category) {
                        final isSelected = _categoryController.text == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _categoryController.text = category;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.orange[100]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange[300]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.orange[700]
                                    : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Etiket girişi
              _buildInputCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              labelText: 'Etiket Ekle',
                              hintText: 'Etiket yazın ve Enter\'a basın',
                              border: InputBorder.none,
                              prefixIcon: Container(
                                margin: EdgeInsets.all(12),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.tag,
                                    color: Colors.teal[600], size: 20),
                              ),
                              suffixText: '${tags.length}/10',
                            ),
                            onFieldSubmitted: (_) => _addTag(),
                            enabled: tags.length < 10,
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.teal[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: tags.length < 10 ? _addTag : null,
                            icon: Icon(Icons.add, color: Colors.teal[700]),
                          ),
                        ),
                      ],
                    ),
                    if (tags.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Etiketler (${tags.length}/10):',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.teal[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: TextStyle(
                                    color: Colors.teal[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeTag(tag),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.teal[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Kaydet butonu
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue[200]!,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isEditing ? Icons.update : Icons.save,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        isEditing ? 'Güncelle' : 'Kaydet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
      child: child,
    );
  }

  Widget _buildSuggestionRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.purple[600]),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
            fontSize: 12,
          ),
        ),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.purple[600],
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
