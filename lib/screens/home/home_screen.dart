import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/post_model.dart';
import 'package:share_plus/share_plus.dart';
import '../profile/profile_screen.dart';
import '../inbox/inbox_screen.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../post/post_detail_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/common/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final AuthService _authService = AuthService();
  List<PostModel> _posts = [];
  User? _currentUser;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _postsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    // Load cached posts first
    try {
      final cachedPosts = await _databaseService.getCachedPosts();
      if (mounted && cachedPosts.isNotEmpty) {
        setState(() {
          _posts = cachedPosts;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached posts: $e');
    }

    _setupRealtimeSync();
  }

  void _setupRealtimeSync() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });

    _postsSubscription = _firestore
        .collection('posts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) async {
      final posts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return PostModel.fromMap(data);
      }).toList();

      // Sort by date
      posts.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      if (mounted) {
        setState(() {
          _posts = posts;
        });
        // Cache new posts
        await _databaseService.cachePosts(posts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Main Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FindIt Logo
          const Text(
            'FindIt',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5DBDA8),
            ),
          ),
          
          Row(
            children: [
              // Search button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5DBDA8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Message/Send button -> Inbox
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InboxScreen()),
                  );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5DBDA8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)));
    }

    // Filter logic (assuming _selectedIndex is for filter tabs if they existed, but here we only have local list)
    // Actually HomeScreen doesn't seem to have filter tabs in the viewed code, it just showed a list.
    // Wait, previous code had `_selectedFilter` in `ProfileScreen` but `HomeScreen` in the view I just saw (Step 129) DOES NOT have filter tabs in `_buildContent`.
    // It just shows all active posts.
    
    // However, I see `_selectedIndex` initialized to 0 in State, but it's not used.
    
    // Let's just return the list.
    final posts = _posts;
    // Note: The previous StreamBuilder also filtered out community posts.
    // .where((post) => post.status == 'active' && post.communityId == null)
    
    final displayPosts = posts.where((post) => post.communityId == null).toList();

    if (displayPosts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayPosts.length,
      itemBuilder: (context, index) {
        return _buildPostCard(displayPosts[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to FindIt',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final bool isLiked = _currentUserId != null && post.likedBy.contains(_currentUserId);
    
    return GestureDetector(
      onTap: () => _openPostDetail(post),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  // Profile Picture (tap to open profile)
                  UserAvatar(
                    userId: post.userId,
                    initialPhotoUrl: post.userPhotoUrl,
                    displayName: post.userName,
                    radius: 22,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.userId)),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Name and Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.userId)),
                            );
                          },
                          child: Text(
                            post.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Item ${post.type} in ${post.locationName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _getTimeAgo(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // More Options
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showPostOptions(post);
                    },
                  ),
                ],
              ),
            ),
            
            // Post Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Post Image (if exists)
            if (post.images.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.images.first,
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
                height: 200,
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
                  // Like Button
                  GestureDetector(
                    onTap: () {
                      _toggleLike(post);
                    },
                    child: _buildInteractionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      count: post.likes,
                      color: isLiked ? Colors.red : const Color(0xFF5DBDA8),
                      onTap: () => _toggleLike(post),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Comment Button
                  _buildInteractionButton(
                    icon: Icons.chat_bubble_outline,
                    count: post.comments,
                    color: const Color(0xFF5DBDA8),
                    onTap: () => _openPostDetail(post),
                  ),
                  const SizedBox(width: 16),
                  // Share Button
                  _buildInteractionButton(
                    icon: Icons.send_outlined,
                    count: post.shares,
                    color: const Color(0xFF5DBDA8),
                    onTap: () async {
                      final title = post.title;
                      final desc = post.description;
                      final urls = post.images.join('\n');
                      final text = '$title\n\n$desc\n\n$urls';
                      try {
                        await Share.share(text);
                        // Optionally increment share count in Firestore
                        await _firestore.collection('posts').doc(post.postId).update({'shares': FieldValue.increment(1)});
                      } catch (e) {
                        _showSnackBar('Share failed');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

  Future<void> _toggleLike(PostModel post) async {
    if (_currentUserId == null) return;

    final postRef = _firestore.collection('posts').doc(post.postId);

    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(postRef);
        if (!snap.exists) return;

        final data = snap.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> likedByRaw = data['likedBy'] ?? [];
        final likedBy = likedByRaw.map((e) => e.toString()).toList();

        if (likedBy.contains(_currentUserId)) {
          // Unlike
          tx.update(postRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([_currentUserId]),
          });
        } else {
          // Like
          tx.update(postRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([_currentUserId]),
          });
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      _showSnackBar('Failed to update like');
    }
  }

  void _openPostDetail(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  void _showPostOptions(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Save Post
                    _buildOptionItem(
                      icon: Icons.bookmark_border,
                      iconColor: Colors.grey[700]!,
                      title: 'Save Post',
                      subtitle: 'Add this to your saved posts.',
                      onTap: () async {
                        Navigator.pop(context);
                        if (_currentUserId == null) {
                          _showSnackBar('Please login to save posts');
                          return;
                        }
                        try {
                          await FirestoreService().savePost(_currentUserId!, post.postId);
                          _showSnackBar('Post saved!');
                        } catch (e) {
                          _showSnackBar('Failed to save post');
                        }
                      },
                    ),
                    
                    // Open Profile
                    _buildOptionItem(
                      icon: Icons.person_outline,
                      iconColor: Colors.grey[700]!,
                      title: 'Open Profile',
                      subtitle: 'Open the profile of the author',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(userId: post.userId)),
                        );
                      },
                    ),
                    
                    // Turn On Notifications
                    _buildOptionItem(
                      icon: Icons.notifications_outlined,
                      iconColor: Colors.grey[700]!,
                title: 'Turn On Notifications',
                subtitle: 'Turn on Notifications for this post.',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Notifications enabled for this post');
                },
              ),
              
              // Copy Link
              _buildOptionItem(
                icon: Icons.link,
                iconColor: Colors.grey[700]!,
                title: 'Copy Link',
                subtitle: 'Copy the link of this post in your clipboard.',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Link copied to clipboard!');
                },
              ),
              
              const SizedBox(height: 8),
              Divider(color: Colors.grey[200], thickness: 1),
              const SizedBox(height: 8),
              
              // Report the post
              _buildOptionItem(
                icon: Icons.error_outline,
                iconColor: Colors.red,
                title: 'Report the post',
                subtitle: 'Something is fishy in the post? Report.',
                titleColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  if (_currentUserId == null) {
                    _showSnackBar('Please login to report');
                    return;
                  }
                  _showReportDialog(post, isUser: false);
                },
              ),
              
              // Report the user
              _buildOptionItem(
                icon: Icons.person_off_outlined,
                iconColor: Colors.red,
                title: 'Report the user',
                subtitle: 'User did something unusual? Report.',
                titleColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  if (_currentUserId == null) {
                    _showSnackBar('Please login to report');
                    return;
                  }
                  _showReportDialog(post, isUser: true);
                },
              ),
              
              // Delete Post (only for owner)
              if (_currentUserId != null && post.userId == _currentUserId) ...[
                const SizedBox(height: 8),
                Divider(color: Colors.grey[200], thickness: 1),
                const SizedBox(height: 8),
                _buildOptionItem(
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  title: 'Delete Post',
                  subtitle: 'Permanently delete this post.',
                  titleColor: Colors.red,
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await _showDeleteConfirmation();
                    if (confirm == true) {
                      await _firestore.collection('posts').doc(post.postId).delete();
                      _showSnackBar('Post deleted');
                    }
                  },
                ),
              ],
              
              const SizedBox(height: 16),
            ],
          ),
                ),
              );
            },
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF5DBDA8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(PostModel post, {required bool isUser}) {
    final reportType = isUser ? 'user' : 'post';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report ${isUser ? 'User' : 'Post'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you reporting this $reportType?'),
            const SizedBox(height: 16),
            _buildReportOption('Spam', post, isUser),
            _buildReportOption('Inappropriate content', post, isUser),
            _buildReportOption('Harassment', post, isUser),
            _buildReportOption('False information', post, isUser),
            _buildReportOption('Other', post, isUser),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(String reason, PostModel post, bool isUser) {
    return ListTile(
      title: Text(reason),
      onTap: () async {
        Navigator.pop(context);
        try {
          await _firestore.collection('reports').add({
            'reporterId': _currentUserId,
            'reportedUserId': isUser ? post.userId : null,
            'reportedPostId': !isUser ? post.postId : null,
            'reason': reason,
            'type': isUser ? 'user' : 'post',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          });
          _showSnackBar('Report submitted. Thank you for helping keep our community safe.');
        } catch (e) {
          _showSnackBar('Failed to submit report');
        }
      },
    );
  }
}
