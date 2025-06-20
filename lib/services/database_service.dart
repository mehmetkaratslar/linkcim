// Dosya Konumu: lib/services/database_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:linkcim/models/saved_video.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Box<SavedVideo>? _videoBox;

  Future<void> initDB() async {
    // Hive'ı başlat
    await Hive.initFlutter();

    // Type adapter'ı kaydet
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SavedVideoAdapter());
    }

    // Box'ı aç
    _videoBox = await Hive.openBox<SavedVideo>('videos');

    print('✅ Hive veritabanı başarıyla başlatıldı');
  }

  Box<SavedVideo> get videoBox {
    if (_videoBox == null) {
      throw Exception('Veritabani baslatilmadi! initDB() metodunu cagirin.');
    }
    return _videoBox!;
  }

  // Video ekleme
  Future<void> addVideo(SavedVideo video) async {
    await videoBox.add(video);
  }

  // Tum videolari getirme (tarihine gore sirali)
  Future<List<SavedVideo>> getAllVideos() async {
    final videos = videoBox.values.toList();
    videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return videos;
  }

  // Video silme - Hive için video objesini doğrudan sil
  Future<void> deleteVideo(SavedVideo video) async {
    await video.delete();
  }

  // Video guncelleme
  Future<void> updateVideo(SavedVideo video) async {
    await video.save();
  }

  // Arama yapma
  Future<List<SavedVideo>> searchVideos(String query) async {
    if (query.isEmpty) return await getAllVideos();

    final allVideos = await getAllVideos();
    return allVideos.where((video) => video.matchesSearch(query)).toList();
  }

  // Kategoriye gore filtreleme
  Future<List<SavedVideo>> getVideosByCategory(String category) async {
    final allVideos = await getAllVideos();
    return allVideos.where((video) => video.category == category).toList();
  }

  // Etikete gore filtreleme
  Future<List<SavedVideo>> getVideosByTag(String tag) async {
    final allVideos = await getAllVideos();
    return allVideos.where((video) => video.tags.contains(tag)).toList();
  }

  // Benzersiz kategorileri getirme
  Future<List<String>> getAllCategories() async {
    final videos = await getAllVideos();
    final categories = videos.map((v) => v.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Benzersiz etiketleri getirme
  Future<List<String>> getAllTags() async {
    final videos = await getAllVideos();
    final allTags = <String>{};
    for (final video in videos) {
      allTags.addAll(video.tags);
    }
    final tagList = allTags.toList();
    tagList.sort();
    return tagList;
  }

  // Benzersiz platformları getirme
  Future<List<String>> getAllPlatforms() async {
    final videos = await getAllVideos();
    final platforms = videos
        .map((v) => v.platform)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    platforms.sort();
    return platforms;
  }

  // Benzersiz yazarları getirme
  Future<List<String>> getAllAuthors() async {
    final videos = await getAllVideos();
    final authors = <String>{};
    for (final video in videos) {
      if (video.authorName.isNotEmpty) {
        authors.add(video.authorName);
      }
      if (video.authorUsername.isNotEmpty &&
          video.authorUsername != video.authorName) {
        authors.add('@${video.authorUsername}');
      }
    }
    final authorList = authors.toList();
    authorList.sort();
    return authorList;
  }

  // Platforma göre filtreleme
  Future<List<SavedVideo>> getVideosByPlatform(String platform) async {
    final allVideos = await getAllVideos();
    return allVideos
        .where(
            (video) => video.platform.toLowerCase() == platform.toLowerCase())
        .toList();
  }

  // Yazara göre filtreleme
  Future<List<SavedVideo>> getVideosByAuthor(String author) async {
    final allVideos = await getAllVideos();
    final cleanAuthor = author.replaceAll('@', '');
    return allVideos
        .where((video) =>
            video.authorName
                .toLowerCase()
                .contains(cleanAuthor.toLowerCase()) ||
            video.authorUsername
                .toLowerCase()
                .contains(cleanAuthor.toLowerCase()))
        .toList();
  }

  // Video sayisini getirme
  Future<int> getVideoCount() async {
    return videoBox.length;
  }

  // Veritabanını kapat
  Future<void> close() async {
    await _videoBox?.close();
  }
}
