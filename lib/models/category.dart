import 'package:hive_flutter/hive_flutter.dart';

class Category {
  final String id;
  final String nameEn;
  final String nameTa;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameTa,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameTa': nameTa,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameTa: json['nameTa'] as String,
    );
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 2; // Using 2 as typeId (0 and 1 might be used or reserved)

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String,
      nameEn: fields[1] as String,
      nameTa: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameEn)
      ..writeByte(2)
      ..write(obj.nameTa);
  }
}
