import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/post_model.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  bool _initialized = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database?> get database async {
    if (kIsWeb) return null; // SQFlite does not work on web
    if (_initialized && _database != null) return _database!;
    
    try {
      _database = await _initDatabase();
      _initialized = true;
      return _database!;
    } catch (e) {
      debugPrint('Database initialization failed: $e');
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'findit_cache.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      debugPrint('Error getting docs dir or opening db: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts(
        postId TEXT PRIMARY KEY,
        userId TEXT,
        type TEXT,
        title TEXT,
        description TEXT,
        category TEXT,
        images TEXT,
        locationName TEXT,
        latitude REAL,
        longitude REAL,
        status TEXT,
        likes INTEGER,
        likedBy TEXT,
        userName TEXT,
        userPhotoUrl TEXT,
        createdAt INTEGER
      )
    ''');
  }

  // Insert or Update Post
  Future<void> cachePost(PostModel post) async {
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      
      await db.insert(
        'posts',
        {
          'postId': post.postId,
          'userId': post.userId,
          'type': post.type,
          'title': post.title,
          'description': post.description,
          'category': post.category,
          'images': jsonEncode(post.images),
          'locationName': post.locationName,
          'latitude': post.location?.latitude,
          'longitude': post.location?.longitude,
          'status': post.status,
          'likes': post.likes,
          'likedBy': jsonEncode(post.likedBy),
          'userName': post.userName,
          'userPhotoUrl': post.userPhotoUrl,
          'createdAt': post.createdAt?.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error caching post: $e');
    }
  }

  Future<void> cachePosts(List<PostModel> posts) async {
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      
      final batch = db.batch();
      
      for (var post in posts) {
        batch.insert(
          'posts',
          {
            'postId': post.postId,
            'userId': post.userId,
            'type': post.type,
            'title': post.title,
            'description': post.description,
            'category': post.category,
            'images': jsonEncode(post.images),
            'locationName': post.locationName,
            'latitude': post.location?.latitude,
            'longitude': post.location?.longitude,
            'status': post.status,
            'likes': post.likes,
            'likedBy': jsonEncode(post.likedBy),
            'userName': post.userName,
            'userPhotoUrl': post.userPhotoUrl,
            'createdAt': post.createdAt?.millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error caching posts batch: $e');
    }
  }

  Future<List<PostModel>> getCachedPosts() async {
    if (kIsWeb) return [];
    try {
      final db = await database;
      if (db == null) return [];
      
      final List<Map<String, dynamic>> maps = await db.query('posts', orderBy: 'createdAt DESC');

      return List.generate(maps.length, (i) {
        final map = maps[i];
        return PostModel(
          postId: map['postId'],
          userId: map['userId'],
          type: map['type'],
          title: map['title'],
          description: map['description'],
          category: map['category'],
          images: List<String>.from(jsonDecode(map['images'])),
          location: (map['latitude'] != null && map['longitude'] != null)
              ? GeoPoint(map['latitude'], map['longitude'])
              : null,
          locationName: map['locationName'],
          status: map['status'],
          likes: map['likes'],
          likedBy: List<String>.from(jsonDecode(map['likedBy'])),
          userName: map['userName'] ?? 'Anonymous',
          userPhotoUrl: map['userPhotoUrl'],
          createdAt: map['createdAt'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
              : null,
        );
      });
    } catch (e) {
      debugPrint('Error fetching cached posts: $e');
      return [];
    }
  }

  Future<void> clearPosts() async {
    if (kIsWeb) return;
    try {
      final db = await database;
      if (db == null) return;
      await db.delete('posts');
    } catch (e) {
      debugPrint('Error clearing posts: $e');
    }
  }
}
