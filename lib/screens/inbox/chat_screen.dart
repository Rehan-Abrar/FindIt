import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/app_back_button.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatScreen({super.key, required this.chatId, required this.otherUserId, required this.otherUserName, this.otherUserPhoto});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _fs = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _fs.markMessagesAsRead(widget.chatId, _currentUserId!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Center(child: AppBackButton()),
        ),
        title: Row(
          children: [
            UserAvatar(
              userId: widget.otherUserId,
              initialPhotoUrl: widget.otherUserPhoto,
              displayName: widget.otherUserName,
              radius: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<DocumentSnapshot>(
                    stream: _fs.getUserPresenceStream(widget.otherUserId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text(
                          'Offline',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final bool isOnline = data['isOnline'] ?? false;
                      final dynamic lastSeenStr = data['lastSeen']; // Changed to dynamic to match logic

                      if (isOnline) {
                        return const Text(
                          'Online',
                          style: TextStyle(color: Color(0xFF5DBDA8), fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }

                      return Text(
                        _formatLastSeen(lastSeenStr),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fs.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final m = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = m['senderId'] == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF5DBDA8) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((m['text'] ?? '').isNotEmpty)
                              Text(m['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                            if (m['imageUrl'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(m['imageUrl'], width: 200, height: 140, fit: BoxFit.cover),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Type Your Text...'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attachment, color: Color(0xFF5DBDA8)),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic, color: Color(0xFF5DBDA8)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Color(0xFF5DBDA8), shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUserId == null) return;
    await _fs.sendMessage(chatId: widget.chatId, senderId: _currentUserId!, text: text);
    _controller.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(_scrollController.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }
}
