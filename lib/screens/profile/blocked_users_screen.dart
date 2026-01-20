import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/app_header.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _fs = FirestoreService();
  String? _uid;
  List<UserModel> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _load();
  }

  Future<void> _load() async {
    if (_uid == null) return;
    setState(() => _loading = true);
    try {
      final users = await _fs.getBlockedUsers(_uid!);
      setState(() => _blocked = users);
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _unblock(String blockedUid) async {
    if (_uid == null) return;
    await _fs.unblockUser(_uid!, blockedUid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unblocked')));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Blocked Users'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)))
                  : _blocked.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blocked.length,
                  itemBuilder: (context, index) {
                    final u = _blocked[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                          child: u.photoUrl == null
                              ? Icon(Icons.person, color: Colors.grey[400])
                              : null,
                        ),
                        title: Text(
                          u.displayName ?? u.email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          u.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _unblock(u.uid),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5DBDA8),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFF5DBDA8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Unblock'),
                        ),
                      ),
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
