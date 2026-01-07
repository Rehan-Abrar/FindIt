import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/community_model.dart';
import '../../models/post_model.dart';
import '../post/post_detail_screen.dart';
import 'create_community_post_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;
  
  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  late CommunityModel _community;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _checkMembership();
  }

  void _checkMembership() {
    if (_currentUserId != null) {
      setState(() {
        _isMember = _community.memberIds.contains(_currentUserId);
      });
    }
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
            
            // Community Info Card
            _buildCommunityInfoCard(),
            
            // Recent Posts Label
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DBDA8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF5DBDA8),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Recent Posts:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5DBDA8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Posts List
            Expanded(
              child: _buildPostsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isMember
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCommunityPostScreen(
                      community: _community,
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFF5DBDA8),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
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
                size: 28,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Search button
          Container(
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
          
          const SizedBox(width: 8),
          
          // Profile button
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF5DBDA8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityInfoCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('communities').doc(_community.id).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          data['id'] = snapshot.data!.id; // Preserve the document ID
          _community = CommunityModel.fromMap(data);
          _isMember = _currentUserId != null && 
              _community.memberIds.contains(_currentUserId);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
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
              // Name and Join button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _community.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _toggleMembership,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMember 
                          ? Colors.grey[200] 
                          : const Color(0xFF5DBDA8),
                      foregroundColor: _isMember 
                          ? Colors.black87 
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isMember ? 'Joined' : 'Join',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                '"${_community.description}"',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Member count and type
              Row(
                children: [
                  Icon(Icons.people, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatMemberCount(_community.memberCount)} members',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    _community.type == 'location' 
                        ? Icons.location_on 
                        : Icons.interests,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _community.type == 'location' 
                        ? 'Location-based' 
                        : 'Interest-based',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('posts')
          .where('communityId', isEqualTo: _community.id)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error loading community posts: ${snapshot.error}');
          return Center(
            child: Text('Error loading posts: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (_isMember) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final posts = snapshot.data!.docs
            .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(posts[index]);
          },
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and post type
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: post.userPhotoUrl != null
                        ? NetworkImage(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null
                        ? Icon(Icons.image, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // User name and location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Item ${post.type} in ${post.locationName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 3 dots menu
                  const Icon(Icons.more_vert, color: Colors.grey),
                ],
              ),
            ),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            // Image if available
            if (post.images.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(post.images.first),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}k';
    }
    return count.toString();
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    }
    return 'Just now';
  }

  Future<void> _toggleMembership() async {
    if (_currentUserId == null) {
      _showSnackBar('Please log in to join communities');
      return;
    }

    try {
      final docRef = _firestore.collection('communities').doc(_community.id);
      
      if (_isMember) {
        await docRef.update({
          'memberIds': FieldValue.arrayRemove([_currentUserId]),
          'memberCount': FieldValue.increment(-1),
        });
        _showSnackBar('Left ${_community.name}');
      } else {
        await docRef.update({
          'memberIds': FieldValue.arrayUnion([_currentUserId]),
          'memberCount': FieldValue.increment(1),
        });
        _showSnackBar('Joined ${_community.name}');
      }
    } catch (e) {
      debugPrint('Error toggling membership: $e');
      _showSnackBar('Error updating membership');
    }
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
}
