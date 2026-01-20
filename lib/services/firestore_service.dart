import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String chatsCollection = 'chats';
  static const String reportsCollection = 'reports';
  static const String communitiesCollection = 'communities';

  // Create or update user profile
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection(usersCollection).doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Error creating user profile: $e');
    }
  }

  // Get user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(usersCollection).doc(uid).update(updates);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  // Presence logic: update user's online status and last seen timestamp
  Future<void> updateUserPresence(String uid, bool isOnline) async {
    // Basic safety check: don't attempt write if user is not fully authed
    if (uid.isEmpty) return;
    
    try {
      await _firestore.collection(usersCollection).doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw here to avoid debugger pauses during logout flows
      debugPrint('Presence update suppressed: $e');
    }
  }

  // Presence logic: listen to a user's presence in real-time
  Stream<DocumentSnapshot> getUserPresenceStream(String uid) {
    return _firestore.collection(usersCollection).doc(uid).snapshots();
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting user profile: $e');
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Error checking user existence: $e');
    }
  }

  // Search users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // ==================== POSTS ====================

  // Create a new post (lost/found item)
  Future<String> createPost({
    required String userId,
    required String type, // 'lost' or 'found'
    required String title,
    required String description,
    required String category,
    required List<String> images,
    required GeoPoint location,
    required String locationName,
  }) async {
    try {
      final postRef = _firestore.collection(postsCollection).doc();
      
      await postRef.set({
        'postId': postRef.id,
        'userId': userId,
        'type': type,
        'title': title,
        'description': description,
        'category': category,
        'images': images,
        'location': location,
        'locationName': locationName,
        'status': 'active',
        'date': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
      
      return postRef.id;
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  // Get all active posts (real-time stream)
  Stream<QuerySnapshot> getActivePosts() {
    return _firestore
        .collection(postsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get posts by type (lost/found)
  Stream<QuerySnapshot> getPostsByType(String type) {
    return _firestore
        .collection(postsCollection)
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get posts by user
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _firestore
        .collection(postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get single post by ID
  Future<DocumentSnapshot> getPostById(String postId) async {
    try {
      return await _firestore.collection(postsCollection).doc(postId).get();
    } catch (e) {
      throw Exception('Error getting post: $e');
    }
  }

  // Update post status
  Future<void> updatePostStatus(String postId, String status) async {
    try {
      await _firestore.collection(postsCollection).doc(postId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating post status: $e');
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(postsCollection).doc(postId).delete();
    } catch (e) {
      throw Exception('Error deleting post: $e');
    }
  }

  // ==================== CHATS ====================

  // Create a new chat
  Future<String> createChat({
    required String senderId,
    required String receiverId,
    String? relatedPostId,
  }) async {
    try {
      // Check if chat already exists between these users for the same post
      final existingChat = await _firestore
          .collection(chatsCollection)
          .where('participants', arrayContains: senderId)
          .get();

      for (var doc in existingChat.docs) {
        List participants = doc['participants'];
        if (participants.contains(receiverId) &&
            doc['relatedPostId'] == relatedPostId) {
          return doc.id; // Return existing chat ID
        }
      }

      // Create new chat
      final chatRef = _firestore.collection(chatsCollection).doc();
      
      await chatRef.set({
        'chatId': chatRef.id,
        'participants': [senderId, receiverId],
        'relatedPostId': relatedPostId,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      
      return chatRef.id;
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  // Get user's chats
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection(chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    String? imageUrl,
  }) async {
    try {
      // Add message to subcollection
      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text ?? '',
        'imageUrl': imageUrl,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update last message in chat
      await _firestore.collection(chatsCollection).doc(chatId).update({
        'lastMessage': text ?? '📷 Image',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Get chat messages
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt') 
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      // Fetch unread messages, then update only those not sent by current user.
      final messagesSnap = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      if (messagesSnap.docs.isEmpty) return;

      // Use batched writes (max 500 operations per batch).
      const int batchSize = 500;
      final docs = messagesSnap.docs;
      int i = 0;

      while (i < docs.length) {
        final batch = _firestore.batch();
        final end = (i + batchSize) > docs.length ? docs.length : i + batchSize;

        for (var j = i; j < end; j++) {
          final doc = docs[j];
          final senderId = (doc.data() as Map<String, dynamic>)['senderId'] as String?;
          if (senderId != null && senderId != currentUserId) {
            batch.update(doc.reference, {'isRead': true});
          }
        }

        await batch.commit();
        i = end;
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  // ==================== REPORTS ====================

  // Create a report
  Future<void> createReport({
    required String reporterId,
    String? reportedUserId,
    String? reportedPostId,
    required String reason,
    required String description,
  }) async {
    try {
      await _firestore.collection(reportsCollection).add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reportedPostId': reportedPostId,
        'reason': reason,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error creating report: $e');
    }
  }

  // ==================== SAVED POSTS ====================

  // Save a post for a user
  Future<void> savePost(String userId, String postId) async {
    try {
      final ref = _firestore.collection('saved_posts').doc();
      await ref.set({
        'savedId': ref.id,
        'userId': userId,
        'postId': postId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error saving post: $e');
    }
  }

  Future<void> removeSavedPost(String userId, String postId) async {
    try {
      final snap = await _firestore
          .collection('saved_posts')
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: postId)
          .get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error removing saved post: $e');
    }
  }

  Stream<QuerySnapshot> getSavedPosts(String userId) {
    return _firestore
        .collection('saved_posts')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  // ==================== ARCHIVE ====================

  Stream<QuerySnapshot> getUserArchivedPosts(String userId) {
    return _firestore
        .collection(postsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'archived')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== ENGAGED POSTS ====================

  Stream<QuerySnapshot> getEngagedPosts(String userId) {
    return _firestore
        .collection(postsCollection)
        .where('likedBy', arrayContains: userId)
        .snapshots();
  }

  // ==================== USER REPORTS ====================

  Stream<QuerySnapshot> getUserReports(String userId) {
    return _firestore
        .collection(reportsCollection)
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== BLOCKED USERS ====================

  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId])
      });
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId])
      });
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  Future<List<UserModel>> getBlockedUsers(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>?;
      final list = List<String>.from(data?['blockedUsers'] ?? []);
      final users = <UserModel>[];
      for (var uid in list) {
        final uDoc = await _firestore.collection(usersCollection).doc(uid).get();
        if (uDoc.exists) {
          users.add(UserModel.fromMap(uDoc.data() as Map<String, dynamic>));
        }
      }
      return users;
    } catch (e) {
      throw Exception('Error fetching blocked users: $e');
    }
  }

  // ==================== COMMUNITIES ====================

  // Create a community
  Future<String> createCommunity({
    required String name,
    required String description,
    required String createdBy,
    String? imageUrl,
    GeoPoint? location,
    String? locationName,
  }) async {
    try {
      final communityRef = _firestore.collection(communitiesCollection).doc();
      
      await communityRef.set({
        'communityId': communityRef.id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'locationName': locationName,
        'memberCount': 1,
        'members': [createdBy],
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return communityRef.id;
    } catch (e) {
      throw Exception('Error creating community: $e');
    }
  }

  // Get all communities
  Stream<QuerySnapshot> getCommunities() {
    return _firestore
        .collection(communitiesCollection)
        .orderBy('memberCount', descending: true)
        .snapshots();
  }

  // Join community
  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      await _firestore.collection(communitiesCollection).doc(communityId).update({
        'members': FieldValue.arrayUnion([userId]),
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Error joining community: $e');
    }
  }

  // Leave community
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      await _firestore.collection(communitiesCollection).doc(communityId).update({
        'members': FieldValue.arrayRemove([userId]),
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Error leaving community: $e');
    }
  }

  // Get user's communities
  Stream<QuerySnapshot> getUserCommunities(String userId) {
    return _firestore
        .collection(communitiesCollection)
        .where('members', arrayContains: userId)
        .snapshots();
  }
}
