import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class NewsPost {
  final int id;
  final DateTime createdAt;
  final String imgHeader;
  final String head;
  final String desc;

  NewsPost({
    required this.id,
    required this.createdAt,
    required this.imgHeader,
    required this.head,
    required this.desc,
  });

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    return NewsPost(
      id: json['id'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      imgHeader: json['img_header'] as String? ?? '',
      head: json['head'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toUtc().toIso8601String(),
      'img_header': imgHeader,
      'head': head,
      'desc': desc,
    };
  }
}

class SupabaseNewsService {
  final SupabaseClient _client = Supabase.instance.client;

  static const String tableName = 'news';
  static const String universityUpdatesTableName = 'univ_upd';
  static const String storageBucket = 'news-images';

  Future<List<NewsPost>> fetchUniversityUpdates() async {
    final response = await _client
        .from(universityUpdatesTableName)
        .select('created_at, img_header, head, desc')
        .order('created_at', ascending: false);

    final rows = response as List<dynamic>;

    return rows
        .map((row) => NewsPost.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadImage(String fileName, Uint8List bytes) async {
    final storagePath = 'news/$fileName';

    await _client.storage.from(storageBucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600'),
    );

    return _client.storage.from(storageBucket).getPublicUrl(storagePath);
  }

  Future<List<NewsPost>> fetchNews() async {
    final response = await _client.from(tableName).select();
    final rows = response as List<dynamic>;

    return rows
        .map((row) => NewsPost.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<NewsPost> createNews({
    required String imageUrl,
    required String header,
    required String description,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client.from(tableName).insert({
      'created_at': now,
      'img_header': imageUrl,
      'head': header,
      'desc': description,
    }).select();

    final rows = response as List<dynamic>;
    return NewsPost.fromJson(rows.first as Map<String, dynamic>);
  }
}
