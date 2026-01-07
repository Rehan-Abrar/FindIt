import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post_model.dart';
import '../../models/community_model.dart';
import '../post/post_detail_screen.dart';
import '../community/community_detail_screen.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  late TabController _tabController;
  
  String _searchQuery = '';
  List<String> _searchHistory = [];
  bool _isSearching = false;
  
  // Post filters
  String _postTypeFilter = 'All'; // All, Lost, Found
  String _postSourceFilter = 'All'; // All, Global, Community
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query); // Remove if exists
    _searchHistory.insert(0, query); // Add to front
    
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10); // Keep only 10
    }
    
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
    
    _saveToSearchHistory(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with search bar
            _buildHeader(),
            
            // Tabs
            _buildTabs(),
            
            // Content
            Expanded(
              child: _isSearching && _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildSearchHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
          
          const SizedBox(width: 12),
          
          // Search field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF5DBDA8),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Search Anything...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _isSearching = false;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF5DBDA8),
        indicatorWeight: 3,
        labelColor: const Color(0xFF5DBDA8),
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Community'),
          Tab(text: 'People'),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for posts, communities, or people',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Color(0xFF5DBDA8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () async {
                    _searchHistory.removeAt(index);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('search_history', _searchHistory);
                    setState(() {});
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Filters (only for Posts tab)
        if (_tabController.index == 0) _buildPostFilters(),
        
        // Results
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsResults(),
              _buildCommunitiesResults(),
              _buildPeopleResults(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Type filter
          Expanded(
            child: _buildFilterChip(
              label: _postTypeFilter,
              options: ['All', 'Lost', 'Found'],
              onSelected: (value) {
                setState(() => _postTypeFilter = value);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Source filter
          Expanded(
            child: _buildFilterChip(
              label: _postSourceFilter,
              options: ['All', 'Global', 'Community'],
              onSelected: (value) {
                setState(() => _postSourceFilter = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(
                value: option,
                child: Text(option),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5DBDA8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF5DBDA8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5DBDA8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF5DBDA8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('posts').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No posts found');
        }

        var posts = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Ensure postId is set from document ID if missing
              if (data['postId'] == null || (data['postId'] as String).isEmpty) {
                data['postId'] = doc.id;
              }
              return PostModel.fromMap(data);
            })
            .where((post) {
              // Search in title and description
              final searchLower = _searchQuery.toLowerCase();
              final matchesSearch = post.title.toLowerCase().contains(searchLower) ||
                  post.description.toLowerCase().contains(searchLower);
              
              if (!matchesSearch) return false;

              // Type filter
              if (_postTypeFilter != 'All') {
                if (post.type.toLowerCase() != _postTypeFilter.toLowerCase()) {
                  return false;
                }
              }

              // Source filter
              if (_postSourceFilter == 'Global' && post.communityId != null) {
                return false;
              }
              if (_postSourceFilter == 'Community' && post.communityId == null) {
                return false;
              }

              return true;
            })
            .toList();

        if (posts.isEmpty) {
          return _buildEmptyState('No posts match your search');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
        );
      },
    );
  }

  Widget _buildCommunitiesResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('communities').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No communities found');
        }

        var communities = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return CommunityModel.fromMap(data);
            })
            .where((community) {
              final searchLower = _searchQuery.toLowerCase();
              return community.name.toLowerCase().contains(searchLower) ||
                  community.description.toLowerCase().contains(searchLower);
            })
            .toList();

        if (communities.isEmpty) {
          return _buildEmptyState('No communities match your search');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          itemBuilder: (context, index) => _buildCommunityCard(communities[index]),
        );
      },
    );
  }

  Widget _buildPeopleResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No people found');
        }

        var users = snapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (doc.id == _currentUserId) return false; // Exclude self
              
              final searchLower = _searchQuery.toLowerCase();
              final displayName = (data['displayName'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              
              return displayName.contains(searchLower) || email.contains(searchLower);
            })
            .toList();

        if (users.isEmpty) {
          return _buildEmptyState('No people match your search');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            return _buildUserCard(users[index].id, userData);
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
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Image or icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF5DBDA8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: post.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          color: Color(0xFF5DBDA8),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      color: Color(0xFF5DBDA8),
                      size: 30,
                    ),
            ),
            
            const SizedBox(width: 12),
            
            // Post info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: post.type.toLowerCase() == 'lost'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: post.type.toLowerCase() == 'lost'
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                      if (post.communityId != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.groups,
                          size: 14,
                          color: Color(0xFF5DBDA8),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(CommunityModel community) {
    final isMember = _currentUserId != null &&
        community.memberIds.contains(_currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(community: community),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF5DBDA8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                community.type == 'location'
                    ? Icons.location_on
                    : Icons.interests,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Community info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${community.memberCount} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Join status
            if (isMember)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Joined',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF5DBDA8),
              child: Text(
                (userData['displayName'] ?? 'U').toString()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['displayName'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData['email'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
