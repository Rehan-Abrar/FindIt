import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../main/main_screen.dart';
import '../post/edit_post_screen.dart';
import 'settings_screen.dart';
import 'report_user_screen.dart';
import '../../services/profile_update_service.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_back_button.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional - if null, shows current user's profile
  
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedFilter = 0; // 0 = All, 1 = Lost, 2 = Found
  
  String _userName = 'Anonymous';
  String _userEmail = '';
  String? _userPhotoUrl;
  DateTime? _memberSince;

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  
  bool get _isOwnProfile {
    final currentUid = _currentUser?.uid;
    if (currentUid == null) return false;
    if (widget.userId == null) return true;
    return widget.userId == currentUid;
  }

  String get _profileUserId => widget.userId ?? _currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    
    // Check if we already have updates in the service
    final latestPhoto = ProfileUpdateService().photoUrlNotifier.value;
    final latestName = ProfileUpdateService().displayNameNotifier.value;
    
    if (latestPhoto != null) _userPhotoUrl = latestPhoto;
    if (latestName != null) _userName = latestName;

    _loadUserData();
    
    // Listen for global profile updates (only if this is our own profile)
    if (_isOwnProfile) {
      ProfileUpdateService().photoUrlNotifier.addListener(_onPhotoUpdate);
      ProfileUpdateService().displayNameNotifier.addListener(_onNameUpdate);
    }
  }

  void _onPhotoUpdate() {
    if (mounted && _isOwnProfile) {
      setState(() {
        _userPhotoUrl = ProfileUpdateService().photoUrlNotifier.value;
      });
    }
  }

  void _onNameUpdate() {
    if (mounted && _isOwnProfile) {
      setState(() {
        _userName = ProfileUpdateService().displayNameNotifier.value ?? 'Anonymous';
      });
    }
  }

  @override
  void dispose() {
    ProfileUpdateService().photoUrlNotifier.removeListener(_onPhotoUpdate);
    ProfileUpdateService().displayNameNotifier.removeListener(_onNameUpdate);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_profileUserId.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_profileUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          // Only update name/photo from DB if this isn't our own profile OR we don't have a fresh session update
          if (!_isOwnProfile || ProfileUpdateService().displayNameNotifier.value == null) {
            _userName = userData?['displayName'] ?? 'Anonymous';
          }
          _userEmail = userData?['email'] ?? '';
          if (!_isOwnProfile || ProfileUpdateService().photoUrlNotifier.value == null) {
            _userPhotoUrl = userData?['photoUrl'];
          }
          
          if (userData?['createdAt'] != null) {
            final created = userData!['createdAt'];
            if (created is Timestamp) {
              _memberSince = created.toDate();
            } else if (created is String) {
              _memberSince = DateTime.tryParse(created);
            }
          }
        });
      } else if (_isOwnProfile && _currentUser != null) {
        setState(() {
          if (ProfileUpdateService().displayNameNotifier.value == null) {
            _userName = _currentUser!.displayName ?? 'Anonymous';
          }
          _userEmail = _currentUser!.email ?? '';
          if (ProfileUpdateService().photoUrlNotifier.value == null) {
            _userPhotoUrl = _currentUser!.photoURL;
          }
          _memberSince = _currentUser!.metadata.creationTime;
        });
      }
    } catch (e) {
      if (_isOwnProfile && _currentUser != null) {
        setState(() {
          if (ProfileUpdateService().displayNameNotifier.value == null) {
            _userName = _currentUser!.displayName ?? _currentUser!.email?.split('@')[0] ?? 'Anonymous';
          }
          _userEmail = _currentUser!.email ?? '';
          if (ProfileUpdateService().photoUrlNotifier.value == null) {
            _userPhotoUrl = _currentUser!.photoURL;
          }
          _memberSince = _currentUser!.metadata.creationTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with back button and menu
              _buildHeader(),
              
              // Profile Info
              _buildProfileInfo(),
              
              const SizedBox(height: 20),
              
              // Stats
              _buildStats(),
              
              const SizedBox(height: 20),
              
              // Filter Tabs
              _buildFilterTabs(),
              
              const SizedBox(height: 16),
              
              // User Posts List
              _buildUserPosts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.userId != null)
            AppBackButton(
              onTap: () {
                if (_isOwnProfile) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                } else {
                  Navigator.pop(context);
                }
              },
            )
          else 
            const SizedBox(width: 48), // Spacer to maintain alignment
          
          if (_isOwnProfile)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              child: const Icon(
                Icons.menu,
                color: Colors.black87,
                size: 28,
              ),
            )
          else
            // Three dot menu for reporting user etc
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'report') {
                  // Report user
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportUserScreen()),
                  );
                } else if (value == 'block') {
                   // Block
                   final fs = FirestoreService();
                   if (_currentUser?.uid != null) {
                     await fs.blockUser(_currentUser!.uid, _profileUserId);
                     if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked')));
                     if (context.mounted) Navigator.pop(context);
                   }
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Report User', 'Block User'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice.toLowerCase().split(' ')[0], 
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        // Profile Picture
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF5DBDA8).withOpacity(0.3),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: UserAvatar(
            userId: _profileUserId,
            initialPhotoUrl: _userPhotoUrl,
            displayName: _userName,
            radius: 56,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Name
        Text(
          _userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Email
        Text(
          _userEmail,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Member Since
        Text(
          'Member since ${_formatMemberSince(_memberSince)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5DBDA8),
          ),
        ),
      ],
    );
  }

  String _formatMemberSince(DateTime? date) {
    if (date == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _profileUserId)
          .snapshots(),
      builder: (context, snapshot) {
        int postsCount = 0;
        int returnedCount = 0;
        
        if (snapshot.hasData) {
          postsCount = snapshot.data!.docs.length;
          returnedCount = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'returned')
              .length;
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatItem(postsCount.toString(), 'Posts', const Color(0xFF5DBDA8)),
            const SizedBox(width: 40),
            _buildStatItem(returnedCount.toString(), 'Returned', Colors.black87),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF5DBDA8),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildFilterTab('All', 0),
          _buildFilterTab('Lost', 1),
          _buildFilterTab('Found', 2),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF5DBDA8) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserPosts() {
    if (_profileUserId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
        ),
      );
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _profileUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          );
        }

        var posts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['postId'] = doc.id;
          return PostModel.fromMap(data);
        }).toList();
        
        posts.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

        if (_selectedFilter == 1) {
          posts = posts.where((post) => post.type == 'lost').toList();
        } else if (_selectedFilter == 2) {
          posts = posts.where((post) => post.type == 'found').toList();
        }

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'No posts found for this category',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostItem(posts[index]);
          },
        );
      },
    );
  }

  Widget _buildPostItem(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
        children: [
          Row(
            children: [
              // Post Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: post.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
              
              const SizedBox(width: 12),
              
              // Post Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Text(
                            post.type == 'lost' ? 'Lost' : 'Found',
                            style: TextStyle(
                              color: post.type == 'lost' ? Colors.red : const Color(0xFF5DBDA8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.label_outline, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          post.category.isNotEmpty ? post.category : 'General',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _getTimeAgo(post.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: post.status == 'active' ? const Color(0xFF5DBDA8) : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.status == 'active' ? 'Active' : 'Returned',
                              style: TextStyle(
                                color: post.status == 'active' ? const Color(0xFF5DBDA8) : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_isOwnProfile && post.userId == _currentUser?.uid) ...[
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPostScreen(post: post),
                        ),
                      ).then((result) {
                        if (result == true) {
                          setState(() {}); // Refresh the list
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DBDA8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _markAsReturned(post),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black87),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Mark Returned', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markAsReturned(PostModel post) async {
    // SECURITY: strictly check ownership before proceeding
    if (_currentUser == null || post.userId != _currentUser!.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unauthorized')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Returned'),
        content: const Text('Are you sure you want to mark this item as returned?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5DBDA8),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('posts').doc(post.postId).update({
        'status': 'returned',
      });
      setState(() {});
    }
  }
}
