import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../post/post_detail_screen.dart';
import '../../widgets/common/app_header.dart';

class EngagedPostsScreen extends StatefulWidget {
  const EngagedPostsScreen({super.key});

  @override
  State<EngagedPostsScreen> createState() => _EngagedPostsScreenState();
}

class _EngagedPostsScreenState extends State<EngagedPostsScreen> {
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
            const AppHeader(title: 'Engaged Posts'),
            Expanded(
              child: _uid == null
                  ? const Center(child: Text('Please login to view engaged posts'))
                  : StreamBuilder<QuerySnapshot>(
              stream: _fs.getEngagedPosts(_uid!),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)));
                }
                
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No engaged posts',
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
                    final map = docs[index].data() as Map<String, dynamic>;
                    final post = PostModel.fromMap(map);
                    
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
                                width: 70,
                                height: 70,
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
                                    Text(
                                      'Posted by ${post.userName}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          post.type == 'lost' ? Icons.search : Icons.check_circle_outline,
                                          size: 14,
                                          color: post.type == 'lost' ? Colors.red : const Color(0xFF5DBDA8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          post.type == 'lost' ? 'Lost' : 'Found',
                                          style: TextStyle(
                                            color: post.type == 'lost' ? Colors.red : const Color(0xFF5DBDA8),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
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
}
