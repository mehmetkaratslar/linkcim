// Dosya Konumu: lib/models/saved_video.dart

import 'package:hive/hive.dart';

part 'saved_video.g.dart';

@HiveType(typeId: 0)
class SavedVideo extends HiveObject {
  @HiveField(0)
  late String videoUrl;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late String category;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late List<String> tags;

  @HiveField(6)
  late String authorName;

  @HiveField(7)
  late String authorUsername;

  @HiveField(8)
  late String platform;

  @HiveField(9)
  String thumbnailUrl = '';

  SavedVideo();

  SavedVideo.create({
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.authorName,
    required this.authorUsername,
    required this.platform,
    this.thumbnailUrl = '',
  }) : createdAt = DateTime.now();

  // JSON serialization metodları (gerekirse)
  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'platform': platform,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory SavedVideo.fromJson(Map<String, dynamic> json) {
    final video = SavedVideo();
    video.videoUrl = json['videoUrl'] ?? '';
    video.title = json['title'] ?? '';
    video.description = json['description'] ?? '';
    video.category = json['category'] ?? '';
    video.createdAt = DateTime.parse(
      json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
    video.tags = List<String>.from(json['tags'] ?? []);
    video.authorName = json['authorName'] ?? '';
    video.authorUsername = json['authorUsername'] ?? '';
    video.platform = json['platform'] ?? '';
    video.thumbnailUrl = json['thumbnailUrl'] ?? '';
    return video;
  }

  // Arama icin helper metodlar
  bool matchesSearch(String query) {
    String lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        description.toLowerCase().contains(lowerQuery) ||
        category.toLowerCase().contains(lowerQuery) ||
        authorName.toLowerCase().contains(lowerQuery) ||
        authorUsername.toLowerCase().contains(lowerQuery) ||
        platform.toLowerCase().contains(lowerQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get tagsAsString {
    return tags.join(', ');
  }

  // Platform özellikli getter'lar
  String get platformIcon {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return '📷';
      case 'youtube':
        return '📺';
      case 'tiktok':
        return '🎵';
      case 'twitter':
        return '🐦';
      default:
        return '🔗';
    }
  }

  String get authorDisplay {
    if (authorName.isNotEmpty && authorUsername.isNotEmpty) {
      return '$authorName (@$authorUsername)';
    } else if (authorName.isNotEmpty) {
      return authorName;
    } else if (authorUsername.isNotEmpty) {
      return '@$authorUsername';
    }
    return 'Bilinmeyen Kullanıcı';
  }

  @override
  String toString() {
    return 'SavedVideo(title: $title, author: $authorDisplay, platform: $platform, category: $category, createdAt: $createdAt)';
  }
}
