import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/app_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _fs = FirestoreService();
  bool _push = true;
  bool _email = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final user = await _fs.getUserProfile(uid);
      setState(() {
        final data = user?.toMap();
        if (data != null) {
          _push = (data['pushNotificationsEnabled'] ?? true) as bool;
          _email = (data['emailNotificationsEnabled'] ?? true) as bool;
        }
      });
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await _fs.updateUserProfile(uid, {
        'pushNotificationsEnabled': _push,
        'emailNotificationsEnabled': _email,
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save settings')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Notification Settings'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
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
                              children: [
                                SwitchListTile(
                                  title: const Text('Push notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: const Text('Receive push notifications for new messages and interactions'),
                                  value: _push,
                                  activeColor: const Color(0xFF5DBDA8),
                                  onChanged: (v) => setState(() => _push = v),
                                ),
                                Divider(height: 1, color: Colors.grey[100]),
                                SwitchListTile(
                                  title: const Text('Email notifications', style: TextStyle(fontWeight: FontWeight.w500)),
                                  subtitle: const Text('Receive email updates for important account activity'),
                                  value: _email,
                                  activeColor: const Color(0xFF5DBDA8),
                                  onChanged: (v) => setState(() => _email = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DBDA8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
