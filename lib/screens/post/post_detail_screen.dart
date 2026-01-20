import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../inbox/chat_screen.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_back_button.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late PostModel _post;
  String? _replyToCommentId;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: AppBackButton(),
                    ),

                    // Post Content
                    _buildPostContent(),

                    const SizedBox(height: 16),

                    // Comments Section
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('posts').doc(_post.postId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _post = PostModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
        }

        final bool isLiked = _currentUserId != null && _post.likedBy.contains(_currentUserId);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    UserAvatar(
                      userId: _post.userId,
                      initialPhotoUrl: _post.userPhotoUrl,
                      displayName: _post.userName,
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Item ${_post.type} at ${_post.locationName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _getTimeAgo(_post.createdAt),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Post Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _post.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Post Image
              if (_post.images.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _post.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 50,
                  ),
                ),

              const SizedBox(height: 12),

              // Interaction Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _buildInteractionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      count: _post.likes,
                      color: isLiked ? Colors.red : const Color(0xFF5DBDA8),
                      onTap: () => _toggleLike(),
                    ),
                    const SizedBox(width: 16),
                    _buildInteractionButton(
                      icon: Icons.chat_bubble_outline,
                      count: _post.comments,
                      color: const Color(0xFF5DBDA8),
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildInteractionButton(
                      icon: Icons.send_outlined,
                      count: _post.shares,
                      color: const Color(0xFF5DBDA8),
                      onTap: () => _sharePost(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Comment Input
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addComment,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5DBDA8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Comments List
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('posts')
                .doc(_post.postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  return _buildCommentItem(doc);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot commentDoc) {
    final comment = commentDoc.data() as Map<String, dynamic>? ?? {};
    final String commentId = commentDoc.id;
    final List likedBy = List.from(comment['likedBy'] ?? []);
    final List dislikedBy = List.from(comment['dislikedBy'] ?? []);
    final int likesCount = comment['likes'] ?? likedBy.length;
    final int dislikesCount = comment['dislikes'] ?? dislikedBy.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF5DBDA8).withOpacity(0.2),
            child: Text(
              (comment['userName'] ?? 'A')[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF5DBDA8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment['userName'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCommentTimeAgo(comment['createdAt']),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Like/Dislike buttons for comments
          Row(
            children: [
              // Like
              IconButton(
                icon: Icon(
                  likedBy.contains(_currentUserId) ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 18,
                  color: likedBy.contains(_currentUserId) ? Colors.blue : Colors.grey,
                ),
                onPressed: () => _toggleCommentLike(commentId),
              ),
              Text(likesCount.toString()),
              // Dislike
              IconButton(
                icon: Icon(
                  dislikedBy.contains(_currentUserId) ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: 18,
                  color: dislikedBy.contains(_currentUserId) ? Colors.red : Colors.grey,
                ),
                onPressed: () => _toggleCommentDislike(commentId),
              ),
              Text(dislikesCount.toString()),
              // Reply
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                onPressed: () => _startReplyToComment(commentId, comment['userName'] ?? 'User'),
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _getCommentTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Just now';
    }
    
    return _getTimeAgo(dateTime);
  }

  Future<void> _toggleLike() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts')),
      );
      return;
    }
    
    if (_post.postId.isEmpty) {
      debugPrint('Error: Post ID is empty');
      return;
    }
    
    final postRef = _firestore.collection('posts').doc(_post.postId);
    
    try {
      if (_post.likedBy.contains(_currentUserId)) {
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([_currentUserId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([_currentUserId]),
        });
      }
    } catch (e) {
      debugPrint('Failed to toggle like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sharePost() async {
    final shareText = 'Check out this ${_post.type} item on FindIt: ${_post.title}\n\n${_post.description}\n\nLocation: ${_post.locationName}';
    
    try {
      await Share.share(shareText);
      
      // Increment share count in Firestore
      if (_post.postId.isNotEmpty) {
        await _firestore.collection('posts').doc(_post.postId).update({
          'shares': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Failed to share post: $e');
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to add a comment')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      String userName = 'Anonymous';

      if (user != null) {
        // Try getting name from local user object first to be faster
        userName = user.displayName ?? 'Anonymous';
      }

      final commentData = {
        'userId': _currentUserId ?? '',
        'userName': userName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': <String>[],
        'dislikes': 0,
        'dislikedBy': <String>[],
      };
      
      final replyTo = _replyToCommentId;
      if (replyTo != null) {
        commentData['replyTo'] = replyTo;
      }

      // Use a batch to perform both writes atomically
      final batch = _firestore.batch();
      
      // 1. Add the comment
      final commentRef = _firestore
          .collection('posts')
          .doc(_post.postId)
          .collection('comments')
          .doc();
      
      batch.set(commentRef, commentData);

      // 2. Update post comment count
      final postRef = _firestore.collection('posts').doc(_post.postId);
      batch.update(postRef, {
        'comments': FieldValue.increment(1),
      });

      await batch.commit();

      if (mounted) {
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
        });
        _commentFocusNode.unfocus();
      }
    } catch (e) {
      debugPrint('Failed to add comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like comments')),
      );
      return;
    }

    final commentRef = _firestore
        .collection('posts')
        .doc(_post.postId)
        .collection('comments')
        .doc(commentId);

    try {
      final snap = await commentRef.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List likedBy = List.from(data['likedBy'] ?? []);
      final List dislikedBy = List.from(data['dislikedBy'] ?? []);

      if (likedBy.contains(_currentUserId)) {
        await commentRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([_currentUserId])
        });
      } else {
        final Map<String, Object> update = {
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([_currentUserId])
        };
        if (dislikedBy.contains(_currentUserId)) {
          update['dislikes'] = FieldValue.increment(-1);
          update['dislikedBy'] = FieldValue.arrayRemove([_currentUserId]);
        }
        await commentRef.update(update);
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update like')));
    }
  }

  Future<void> _toggleCommentDislike(String commentId) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to dislike comments')),
      );
      return;
    }

    final commentRef = _firestore
        .collection('posts')
        .doc(_post.postId)
        .collection('comments')
        .doc(commentId);

    try {
      final snap = await commentRef.get();
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List likedBy = List.from(data['likedBy'] ?? []);
      final List dislikedBy = List.from(data['dislikedBy'] ?? []);

      if (dislikedBy.contains(_currentUserId)) {
        await commentRef.update({
          'dislikes': FieldValue.increment(-1),
          'dislikedBy': FieldValue.arrayRemove([_currentUserId])
        });
      } else {
        final Map<String, Object> update = {
          'dislikes': FieldValue.increment(1),
          'dislikedBy': FieldValue.arrayUnion([_currentUserId])
        };
        if (likedBy.contains(_currentUserId)) {
          update['likes'] = FieldValue.increment(-1);
          update['likedBy'] = FieldValue.arrayRemove([_currentUserId]);
        }
        await commentRef.update(update);
      }
    } catch (e) {
      debugPrint('Error toggling comment dislike: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update dislike')));
    }
  }

  void _startReplyToComment(String commentId, String userName) {
    _replyToCommentId = commentId;
    _commentController.text = '@$userName ';
    _commentFocusNode.requestFocus();
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _contactOwner,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5DBDA8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Message Owner',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _contactOwner() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to message the owner')),
      );
      return;
    }
    
    if (_post.userId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself')),
      );
      return;
    }

    try {
      final chatId = await FirestoreService().createChat(
        senderId: _currentUserId!,
        receiverId: _post.userId,
        relatedPostId: _post.postId,
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: _post.userId,
              otherUserName: _post.userName,
              otherUserPhoto: _post.userPhotoUrl,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start chat')),
        );
      }
    }
  }

  Widget _buildNavItem({required IconData icon}) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
