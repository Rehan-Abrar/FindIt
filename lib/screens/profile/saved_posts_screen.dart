import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../post/post_detail_screen.dart';
import '../../widgets/common/app_header.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final _fs = FirestoreService();
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Saved Posts'),
            Expanded(
              child: _uid == null
                  ? const Center(child: Text('Please login to view saved posts'))
                  : StreamBuilder<QuerySnapshot>(
              stream: _fs.getSavedPosts(_uid!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No saved posts',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final saved = docs[index].data() as Map<String, dynamic>;
                    final postId = saved['postId'] as String?;

                    if (postId == null) return const SizedBox.shrink();

                    return FutureBuilder<DocumentSnapshot>(
                      future: _fs.getPostById(postId),
                      builder: (context, pSnap) {
                        if (pSnap.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8))),
                          );
                        }
                        
                        // Handle if post is deleted
                        if (!pSnap.hasData || !pSnap.data!.exists) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.grey),
                                const SizedBox(width: 12),
                                const Text('This post is no longer available', style: TextStyle(color: Colors.grey)),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () async {
                                    await _fs.removeSavedPost(_uid!, postId);
                                  },
                                ),
                              ],
                            ),
                          );
                        }

                        final post = PostModel.fromMap(pSnap.data!.data() as Map<String, dynamic>);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      image: post.images.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(post.images.first),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: post.images.isEmpty
                                        ? Icon(Icons.image, color: Colors.grey[400])
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                post.locationName,
                                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          post.type == 'lost' ? 'Lost Item' : 'Found Item',
                                          style: TextStyle(
                                            color: post.type == 'lost' ? Colors.red : const Color(0xFF5DBDA8),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.bookmark, color: Color(0xFF5DBDA8)),
                                    onPressed: () async {
                                      await _fs.removeSavedPost(_uid!, post.postId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Removed from saved items')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}
