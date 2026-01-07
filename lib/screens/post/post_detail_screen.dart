import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';

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
  late PostModel _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _commentController.dispose();
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
                    // Back Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5DBDA8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
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
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF5DBDA8).withOpacity(0.2),
                      backgroundImage: _post.userPhotoUrl != null
                          ? NetworkImage(_post.userPhotoUrl!)
                          : null,
                      child: _post.userPhotoUrl == null
                          ? Text(
                              _post.userName.isNotEmpty
                                  ? _post.userName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: Color(0xFF5DBDA8),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
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
                      onTap: () {},
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
                  final comment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildCommentItem(comment);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
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
                    Text(
                      comment['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
              IconButton(
                icon: const Icon(Icons.thumb_up_outlined, size: 18),
                onPressed: () {},
                color: Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.thumb_down_outlined, size: 18),
                onPressed: () {},
                color: Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                onPressed: () {},
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
    if (_currentUserId == null) return;
    
    final postRef = _firestore.collection('posts').doc(_post.postId);
    
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
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_currentUserId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    String userName = 'Anonymous';

    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userName = userDoc.data()?['displayName'] ?? user.displayName ?? 'Anonymous';
      } else {
        userName = user.displayName ?? 'Anonymous';
      }
    }

    await _firestore
        .collection('posts')
        .doc(_post.postId)
        .collection('comments')
        .add({
      'userId': _currentUserId,
      'userName': userName,
      'text': _commentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update comment count
    await _firestore.collection('posts').doc(_post.postId).update({
      'comments': FieldValue.increment(1),
    });

    _commentController.clear();
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5DBDA8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_rounded),
              _buildNavItem(icon: Icons.location_on),
              _buildCenterAddButton(),
              _buildNavItem(icon: Icons.groups_rounded),
              _buildNavItem(icon: Icons.person_outline),
            ],
          ),
        ),
      ),
    );
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
