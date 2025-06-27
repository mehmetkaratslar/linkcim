// Dosya Konumu: lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:linkcim/services/database_service.dart';
import 'package:linkcim/services/ai_service.dart';
import 'package:linkcim/services/api_key_manager.dart';
import 'package:linkcim/screens/download_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _apiKeyController = TextEditingController();

  bool aiAnalysisEnabled = true;
  bool hasValidApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // API key durumunu yeni ApiKeyManager ile kontrol et
      final hasUserApiKey = await ApiKeyManager.hasUserApiKey();

      setState(() {
        aiAnalysisEnabled = prefs.getBool('ai_analysis_enabled') ?? true;
        hasValidApiKey = hasUserApiKey;
      });
    } catch (e) {
      print('Ayarlar yüklenirken hata: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ai_analysis_enabled', aiAnalysisEnabled);
      // API key artık ApiKeyManager ile yönetiliyor
    } catch (e) {
      print('Ayarlar kaydedilirken hata: $e');
    }
  }

  bool _validateApiKey(String key) {
    return key.isNotEmpty && key.startsWith('sk-') && key.length > 20;
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

  Future<void> _showApiKeyDialog() async {
    final currentUserKey = await ApiKeyManager.getUserApiKey();
    _apiKeyController.text = currentUserKey ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.key, color: Colors.blue),
            SizedBox(width: 8),
            Text('OpenAI API Anahtarı'),
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
                  Text(
                    '🎁 Ücretsiz Deneme',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Her kullanıcı 10 kez ücretsiz AI analizi yapabilir. Sonrasında kendi OpenAI API anahtarınızı girin.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Anahtarı (İsteğe Bağlı)',
                hintText: 'sk-proj-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                helperText:
                    'Sınırsız kullanım için kendi API anahtarınızı girin',
              ),
              obscureText: true,
              maxLines: 1,
            ),
            SizedBox(height: 8),
            Text(
              'API anahtarı "sk-" ile başlamalıdır. OpenAI hesabınızdan alabilirsiniz.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final key = _apiKeyController.text.trim();
              if (key.isEmpty) {
                Navigator.of(context).pop('REMOVE'); // API key'i kaldır
              } else if (_validateApiKey(key)) {
                Navigator.of(context).pop(key);
              } else {
                _showError('Geçersiz API anahtarı formatı');
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result == 'REMOVE') {
        await ApiKeyManager.removeUserApiKey();
        _showSuccess(
            'API anahtarı kaldırıldı. Ücretsiz kullanıma geri döndünüz.');
      } else {
        final success = await ApiKeyManager.setUserApiKey(result);
        if (success) {
          _showSuccess(
              'API anahtarı başarıyla kaydedildi. Artık sınırsız kullanabilirsiniz!');
        } else {
          _showError('API anahtarı kaydedilemedi');
        }
      }
      setState(() {
        hasValidApiKey = result != 'REMOVE';
      });
    }
  }

  Future<void> _removeApiKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('API Anahtarını Kaldır'),
          ],
        ),
        content: Text(
          'API anahtarınızı kaldırmak istediğinizden emin misiniz? '
          'Ücretsiz kullanım limitine geri döneceksiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Kaldır', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiKeyManager.removeUserApiKey();
      setState(() {
        hasValidApiKey = false;
      });
      _showSuccess(
          'API anahtarı kaldırıldı. Ücretsiz kullanıma geri döndünüz.');
    }
  }

  Future<void> _testApiKey() async {
    if (!hasValidApiKey) {
      _showError('Önce geçerli bir API anahtarı girin');
      return;
    }

    _showSuccess('API anahtarı test ediliyor...');

    try {
      // Test için basit bir başlık analizi yap
      final result = await AIService.advancedVideoAnalysis(
          title: 'Flutter ile mobil uygulama geliştirme');

      if (result['success'] == true) {
        if (result['source'] == 'gpt-4o-advanced') {
          _showSuccess('✅ API anahtarı çalışıyor! Gelişmiş AI analizi aktif.');
        } else {
          _showSuccess('✅ API bağlantısı var, basit analiz çalışıyor.');
        }
      } else {
        _showError('API anahtarı çalışmıyor veya bağlantı sorunu var');
      }
    } catch (e) {
      _showError('API test hatası: $e');
    }
  }

  Future<void> _showAboutDialog() async {
    showAboutDialog(
      context: context,
      applicationName: 'Linkci',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.video_library, size: 48),
      children: [
        Text('Akilli Video Kayit ve Kategorilendirme Uygulamasi'),
        SizedBox(height: 8),
        Text('Instagram videolarinizi organize edin ve kolayca bulun.'),
        SizedBox(height: 8),
        Text('Flutter ile gelistirilmistir.'),
      ],
    );
  }

  // İzin kontrol fonksiyonları
  Future<Map<String, bool>> _checkPermissions() async {
    if (!Platform.isAndroid) {
      return {'all': true}; // iOS için varsayılan olarak izinli
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      Map<String, bool> permissions = {};

      if (sdkInt >= 33) {
        // Android 13+ (API 33+)
        permissions['videos'] = await Permission.videos.status.isGranted;
        permissions['photos'] = await Permission.photos.status.isGranted;
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32)
        permissions['manageStorage'] =
            await Permission.manageExternalStorage.status.isGranted;
        permissions['storage'] = await Permission.storage.status.isGranted;
      } else {
        // Android 10 ve altı
        permissions['storage'] = await Permission.storage.status.isGranted;
      }

      permissions['all'] = permissions.values.every((granted) => granted);
      return permissions;
    } catch (e) {
      print('İzin kontrolü hatası: $e');
      return {'all': false};
    }
  }

  Future<void> _requestPermissions() async {
    if (!Platform.isAndroid) {
      _showSuccess('iOS cihazlarda otomatik izin verildi');
      return;
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      _showSuccess('İzinler isteniyor...');

      bool allGranted = false;

      if (sdkInt >= 33) {
        // Android 13+ (API 33+)
        final videoStatus = await Permission.videos.request();
        final photosStatus = await Permission.photos.request();
        allGranted = videoStatus.isGranted && photosStatus.isGranted;
      } else if (sdkInt >= 30) {
        // Android 11-12 (API 30-32)
        final manageStatus = await Permission.manageExternalStorage.request();
        final storageStatus = await Permission.storage.request();
        allGranted = manageStatus.isGranted || storageStatus.isGranted;
      } else {
        // Android 10 ve altı
        final storageStatus = await Permission.storage.request();
        allGranted = storageStatus.isGranted;
      }

      if (allGranted) {
        _showSuccess('✅ Tüm izinler verildi! Video indirme özelliği aktif.');
      } else {
        _showError(
            '❌ Bazı izinler reddedildi. Video indirme sınırlı olabilir.');
      }

      setState(() {}); // Durumu güncelle
    } catch (e) {
      _showError('İzin isteme hatası: $e');
    }
  }

  Future<void> _showPermissionInfo() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.storage, color: Colors.blue),
            SizedBox(width: 8),
            Text('Depolama İzinleri'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Linkcim uygulaması video indirme özelliği için aşağıdaki izinlere ihtiyaç duyar:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildPermissionInfo(
                '📁 Depolama Erişimi', 'Videoları cihazınıza indirmek için'),
            _buildPermissionInfo(
                '🎬 Video/Medya Erişimi', 'İndirilen videolara erişmek için'),
            _buildPermissionInfo(
                '🔒 Dosya Yönetimi', 'Video dosyalarını organize etmek için'),
            SizedBox(height: 16),
            Container(
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
                      'Verileriniz güvende, sadece video indirme için kullanılır.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionInfo(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 8),
          Expanded(child: Text(description, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tum Verileri Sil'),
        content: Text('Bu islem tum videolarinizi silecektir ve geri alinmaz. '
            'Devam etmek istediginizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sil',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      final videos = await _dbService.getAllVideos();
      for (final video in videos) {
        await _dbService.deleteVideo(video);
      }

      _showSuccess('Tum veriler silindi');
    } catch (e) {
      _showError('Veri silinirken hata olustu: $e');
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          // AI ayarlari
          _buildSection('Yapay Zeka Ayarları', [
            // API Kullanım Durumu
            FutureBuilder<Map<String, dynamic>>(
              future: ApiKeyManager.getUsageStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final stats = snapshot.data!;
                  final hasUserKey = stats['has_user_key'] ?? false;
                  final currentUsage = stats['current_usage'] ?? 0;
                  final remaining = stats['remaining_free'] ?? 0;
                  final canUseAI = stats['can_use_ai'] ?? false;

                  return Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasUserKey
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : canUseAI
                                ? [Colors.blue[400]!, Colors.blue[600]!]
                                : [Colors.orange[400]!, Colors.orange[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (hasUserKey
                                  ? Colors.green
                                  : canUseAI
                                      ? Colors.blue
                                      : Colors.orange)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasUserKey ? Icons.key : Icons.smart_toy,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Kullanım Durumu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          hasUserKey
                              ? '🔑 Kendi API anahtarınızı kullanıyorsunuz'
                              : canUseAI
                                  ? '🎁 Ücretsiz kullanım: $remaining hakkınız kaldı'
                                  : '⚠️ Ücretsiz kullanım hakkınız bitti',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!hasUserKey) ...[
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: currentUsage / 10,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$currentUsage/10 kullanım',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),

            ListTile(
              leading: Icon(
                Icons.smart_toy,
                color: aiAnalysisEnabled ? Colors.purple : Colors.grey,
              ),
              title: Text('AI Video Analizi'),
              subtitle: Text('Video içeriğini otomatik analiz et'),
              trailing: Switch(
                value: aiAnalysisEnabled,
                onChanged: (value) {
                  setState(() {
                    aiAnalysisEnabled = value;
                  });
                  _saveSettings();
                  _showSuccess(
                      value ? 'AI analizi açıldı' : 'AI analizi kapatıldı');
                },
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.key,
                color: hasValidApiKey ? Colors.green : Colors.blue,
              ),
              title: Text('OpenAI API Anahtarı'),
              subtitle: Text(
                hasValidApiKey
                    ? 'Kendi API anahtarınızı kullanıyorsunuz'
                    : 'Sınırsız kullanım için kendi API anahtarınızı girin',
              ),
              onTap: _showApiKeyDialog,
            ),

            if (hasValidApiKey) ...[
              ListTile(
                leading: Icon(Icons.science, color: Colors.blue),
                title: Text('API Anahtarını Test Et'),
                subtitle: Text('Bağlantıyı ve çalışmayı kontrol et'),
                onTap: _testApiKey,
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('API Anahtarını Kaldır'),
                subtitle: Text('Ücretsiz kullanıma geri dön'),
                onTap: _removeApiKey,
              ),
            ],
          ]),

          Divider(),

          // İzin yönetimi
          _buildSection('İzin Yönetimi', [
            FutureBuilder<Map<String, bool>>(
              future: _checkPermissions(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final permissions = snapshot.data!;
                  final allGranted = permissions['all'] ?? false;

                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.security,
                          color: allGranted ? Colors.green : Colors.orange,
                        ),
                        title: Text('Depolama İzinleri'),
                        subtitle: Text(
                          allGranted
                              ? '✅ Tüm izinler verildi'
                              : '⚠️ İzinler eksik - video indirme sınırlı',
                        ),
                        trailing: allGranted
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.warning, color: Colors.orange),
                        onTap: _showPermissionInfo,
                      ),
                      if (!allGranted)
                        ListTile(
                          leading: Icon(Icons.settings, color: Colors.blue),
                          title: Text('İzinleri Yönet'),
                          subtitle:
                              Text('Video indirme için gerekli izinleri ver'),
                          onTap: _requestPermissions,
                        ),
                      ListTile(
                        leading: Icon(Icons.open_in_new, color: Colors.grey),
                        title: Text('Sistem Ayarları'),
                        subtitle:
                            Text('Uygulama izinlerini manuel olarak düzenle'),
                        onTap: openAppSettings,
                      ),
                    ],
                  );
                } else {
                  return ListTile(
                    leading: CircularProgressIndicator(strokeWidth: 2),
                    title: Text('İzinler kontrol ediliyor...'),
                  );
                }
              },
            ),
          ]),

          Divider(),

          // Veri yonetimi
          _buildSection('Veri Yönetimi', [
            ListTile(
              leading: Icon(Icons.video_library, color: Colors.purple),
              title: Text('İndirilenler'),
              subtitle: Text('İndirilen videoları oynat ve paylaş'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DownloadHistoryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Tum Verileri Sil'),
              subtitle: Text('Dikkatli kullanin - geri alinamaz'),
              onTap: _confirmClearData,
            ),
          ]),

          Divider(),

          // Uygulama bilgileri
          _buildSection('Uygulama', [
            ListTile(
              leading: Icon(Icons.info, color: Colors.blue),
              title: Text('Hakkinda'),
              subtitle: Text('Uygulama bilgileri'),
              onTap: _showAboutDialog,
            ),
          ]),
        ],
      ),
    );
  }
}
