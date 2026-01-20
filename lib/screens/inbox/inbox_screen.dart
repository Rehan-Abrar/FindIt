import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import 'chat_screen.dart';
import '../search/search_screen.dart';
import '../../widgets/common/app_back_button.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final FirestoreService _fs = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header matching app style (back circle + search/send capsules)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppBackButton(),
                  const Text('Inbox', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5DBDA8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Body: list of users you can message
            Expanded(
              child: _currentUserId == null
                  ? const Center(child: Text('Please sign in to view messages'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)));
                        }
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                        final users = (snapshot.data?.docs ?? [])
                            .where((d) => (d.data() as Map<String, dynamic>)['uid'] != _currentUserId)
                            .toList();

                        if (users.isEmpty) {
                          return const Center(child: Text('No conversations yet'));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final doc = users[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final userId = data['uid'] as String? ?? doc.id;
                            final name = data['displayName'] ?? 'User';
                            final location = data['locationName'] ?? 'Unknown Area';
                            final photo = data['photoUrl'] as String?;

                            return GestureDetector(
                              onTap: () async {
                                if (_currentUserId == null) return;
                                final chatId = await _fs.createChat(senderId: _currentUserId!, receiverId: userId);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserId: userId, otherUserName: name, otherUserPhoto: photo)),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(left: 28),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2EA686),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 32),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 6),
                                                  if (data['isOnline'] == true)
                                                    const Text('Online', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                                                  else
                                                    Text(
                                                      _formatLastSeen(data['lastSeen']),
                                                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 6,
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.white,
                                        backgroundImage: photo != null ? NetworkImage(photo) : null,
                                        child: photo == null ? Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF2EA686))) : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(dynamic lastSeenVal) {
    if (lastSeenVal == null) return 'Last seen: --';
    try {
      DateTime lastSeen;
      if (lastSeenVal is Timestamp) {
        lastSeen = lastSeenVal.toDate();
      } else if (lastSeenVal is String) {
        lastSeen = DateTime.parse(lastSeenVal);
      } else {
        return 'Last seen: --';
      }

      final now = DateTime.now();
      final difference = now.difference(lastSeen);

      if (difference.inSeconds < 60) return 'Last seen: Just now';
      if (difference.inMinutes < 60) return 'Last seen: ${difference.inMinutes}m ago';
      if (difference.inHours < 24) return 'Last seen: ${difference.inHours}h ago';
      if (difference.inDays < 7) return 'Last seen: ${difference.inDays}d ago';
      return 'Last seen: ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    } catch (e) {
      return 'Last seen: --';
    }
  }
}
