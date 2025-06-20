// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_video.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedVideoAdapter extends TypeAdapter<SavedVideo> {
  @override
  final int typeId = 0;

  @override
  SavedVideo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedVideo()
      ..videoUrl = fields[0] as String
      ..title = fields[1] as String
      ..description = fields[2] as String
      ..category = fields[3] as String
      ..createdAt = fields[4] as DateTime
      ..tags = (fields[5] as List).cast<String>()
      ..authorName = fields[6] as String
      ..authorUsername = fields[7] as String
      ..platform = fields[8] as String
      ..thumbnailUrl = fields[9] as String;
  }

  @override
  void write(BinaryWriter writer, SavedVideo obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.videoUrl)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.authorName)
      ..writeByte(7)
      ..write(obj.authorUsername)
      ..writeByte(8)
      ..write(obj.platform)
      ..writeByte(9)
      ..write(obj.thumbnailUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedVideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
