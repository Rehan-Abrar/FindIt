import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/community_model.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';
import '../search/search_screen.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  
  bool _showMyCommunities = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: _showMyCommunities 
                  ? _buildMyCommunities()
                  : _buildRecommendedCommunities(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCommunityScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF5DBDA8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
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
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              
              const Spacer(),
              
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
              
              // Send/Message button
              Container(
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
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Toggle tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showMyCommunities = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showMyCommunities 
                            ? const Color(0xFF5DBDA8) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Recommended',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_showMyCommunities 
                              ? Colors.white 
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showMyCommunities = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showMyCommunities 
                            ? const Color(0xFF5DBDA8) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'My Communities',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showMyCommunities 
                              ? Colors.white 
                              : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCommunities() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communities')
          .orderBy('memberCount', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No communities yet', 'Be the first to create one!');
        }

        final communities = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Use Firestore document ID
              debugPrint('Community loaded: id=${doc.id}, name=${data['name']}');
              return CommunityModel.fromMap(data);
            })
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return _buildCommunityCard(communities[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildMyCommunities() {
    if (_currentUserId == null) {
      return _buildEmptyState('Not logged in', 'Please log in to see your communities');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('communities')
          .where('memberIds', arrayContains: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5DBDA8)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'No communities joined', 
            'Join communities to see them here',
          );
        }

        final communities = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Use Firestore document ID
              return CommunityModel.fromMap(data);
            })
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'My Communities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return _buildCommunityCard(communities[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildCommunityCard(CommunityModel community) {
    final bool isMember = _currentUserId != null && 
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
        margin: const EdgeInsets.only(bottom: 12),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMemberCount(community.memberCount)} Members',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            ElevatedButton(
              onPressed: () => _toggleMembership(community, isMember),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMember 
                    ? Colors.grey[200] 
                    : const Color(0xFF5DBDA8),
                foregroundColor: isMember 
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
                isMember ? 'Joined' : 'Join',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}k';
    }
    return count.toString();
  }

  Future<void> _toggleMembership(CommunityModel community, bool isMember) async {
    if (_currentUserId == null) {
      _showSnackBar('Please log in to join communities');
      return;
    }

    debugPrint('Toggle membership for community ID: "${community.id}"');
    
    if (community.id.isEmpty) {
      _showSnackBar('Error: Community ID is empty');
      return;
    }

    try {
      final docRef = _firestore.collection('communities').doc(community.id);
      
      if (isMember) {
        // Leave community
        await docRef.update({
          'memberIds': FieldValue.arrayRemove([_currentUserId]),
          'memberCount': FieldValue.increment(-1),
        });
        _showSnackBar('Left ${community.name}');
      } else {
        // Join community
        await docRef.update({
          'memberIds': FieldValue.arrayUnion([_currentUserId]),
          'memberCount': FieldValue.increment(1),
        });
        _showSnackBar('Joined ${community.name}');
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
