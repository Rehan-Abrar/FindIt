import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String type; // 'lost' or 'found'
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final GeoPoint? location;
  final String locationName;
  final String status;
  final DateTime? date;
  final DateTime? createdAt;
  final int likes;
  final int comments;
  final int shares;
  final List<String> likedBy;
  final String? communityId; // null for global posts, set for community posts
  final String? communityName;

  PostModel({
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.images,
    this.location,
    required this.locationName,
    required this.status,
    this.date,
    this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.likedBy = const [],
    this.communityId,
    this.communityName,
  });

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type,
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'location': location,
      'locationName': locationName,
      'status': status,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'likedBy': likedBy,
      'communityId': communityId,
      'communityName': communityName,
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userPhotoUrl: map['userPhotoUrl'],
      type: map['type'] ?? 'lost',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      location: map['location'],
      locationName: map['locationName'] ?? '',
      status: map['status'] ?? 'active',
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : null,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      shares: map['shares'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      communityId: map['communityId'],
      communityName: map['communityName'],
    );
  }

  PostModel copyWith({
    String? postId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? type,
    String? title,
    String? description,
    String? category,
    List<String>? images,
    GeoPoint? location,
    String? locationName,
    String? status,
    DateTime? date,
    DateTime? createdAt,
    int? likes,
    int? comments,
    int? shares,
    List<String>? likedBy,
    String? communityId,
    String? communityName,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      status: status ?? this.status,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      likedBy: likedBy ?? this.likedBy,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
    );
  }
}
