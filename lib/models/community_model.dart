import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String type; // 'location' or 'interest'
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final int memberCount;
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;
  final List<String> memberIds;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.latitude,
    this.longitude,
    this.locationName,
    this.memberCount = 0,
    required this.createdBy,
    required this.createdByName,
    this.createdAt,
    this.memberIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'memberCount': memberCount,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
      'memberIds': memberIds,
    };
  }

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'location',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['locationName'],
      memberCount: map['memberCount'] ?? 0,
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? 'Unknown',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      memberIds: List<String>.from(map['memberIds'] ?? []),
    );
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    double? latitude,
    double? longitude,
    String? locationName,
    int? memberCount,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    List<String>? memberIds,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      memberCount: memberCount ?? this.memberCount,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}
