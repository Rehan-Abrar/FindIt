import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/profile_update_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/app_header.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _displayController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fs = FirestoreService();
  bool _loading = true;
  bool _uploading = false;
  String? _currentPhotoUrl;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final model = await _fs.getUserProfile(user.uid);
      if (model != null) {
        setState(() {
          _displayController.text = model.displayName ?? '';
          _phoneController.text = model.phoneNumber ?? '';
          _currentPhotoUrl = model.photoUrl;
        });
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_selectedImageBytes == null) return;
    setState(() => _uploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final url = await CloudinaryService.uploadImage(
        bytes: _selectedImageBytes!,
        folder: 'profiles/${user.uid}',
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (url != null) {
        await _fs.updateUserProfile(user.uid, {'photoUrl': url});
        await user.updatePhotoURL(url);
        await user.reload();
        
        // Notify the rest of the app about the update with cache busting
        final timestampedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
        ProfileUpdateService().notifyPhotoUpdate(timestampedUrl);
        
        setState(() {
          _currentPhotoUrl = timestampedUrl;
          _selectedImageBytes = null;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final name = _displayController.text.trim();
      final phone = _phoneController.text.trim();
      
      await _fs.updateUserProfile(user.uid, {
        'displayName': name,
        'phoneNumber': phone,
      });

      // Notify the app about the name update
      ProfileUpdateService().notifyNameUpdate(name);

      if (name != user.displayName) {
        await user.updateDisplayName(name);
        await user.reload();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5DBDA8)))
          : SafeArea(
              child: Column(
                children: [
                  const AppHeader(title: 'Account Settings'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profile Picture Section
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFF5DBDA8).withOpacity(0.2),
                                  backgroundImage: _selectedImageBytes != null
                                      ? MemoryImage(_selectedImageBytes!)
                                      : (_currentPhotoUrl != null
                                          ? NetworkImage(_currentPhotoUrl!)
                                          : null) as ImageProvider?,
                                  child: _selectedImageBytes == null && _currentPhotoUrl == null
                                      ? const Icon(Icons.person, size: 60, color: Color(0xFF5DBDA8))
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5DBDA8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (_selectedImageBytes != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _uploading ? null : _uploadProfilePicture,
                                  icon: _uploading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.upload),
                                  label: Text(_uploading ? 'Uploading...' : 'Upload'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5DBDA8),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _selectedImageBytes = null);
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Display Name Field
                          TextField(
                            controller: _displayController,
                            decoration: InputDecoration(
                              labelText: 'Display name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF5DBDA8), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Number Field
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF5DBDA8), width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          
                          // Save Button
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

  @override
  void dispose() {
    _displayController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
