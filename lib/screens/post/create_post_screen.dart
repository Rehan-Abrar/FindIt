import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../map/location_picker_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  bool isLostItem = true; // true = Lost Item, false = Found Item
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;
  
  // Location coordinates
  double? _latitude;
  double? _longitude;
  
  final List<String> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    _buildBackButton(),
                    
                    const SizedBox(height: 24),
                    
                    // Lost/Found Toggle
                    _buildToggleButtons(),
                    
                    const SizedBox(height: 24),
                    
                    // Title Field
                    _buildTextField(
                      controller: _titleController,
                      hintText: 'Title...',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description Field
                    _buildTextField(
                      controller: _descriptionController,
                      hintText: 'Description...',
                      maxLines: 5,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Field
                    _buildTextField(
                      controller: _categoryController,
                      hintText: 'Category...',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date and Location Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _dateController,
                            hintText: 'Date...',
                            onTap: _selectDate,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLocationField(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Add Image Button
                    _buildAddImageButton(),
                    
                    const SizedBox(height: 24),
                    
                    // Post Button
                    _buildPostButton(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
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
          size: 32,
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5DBDA8),
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lost Item Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isLostItem = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isLostItem ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lost Item',
                  style: TextStyle(
                    color: isLostItem ? const Color(0xFF5DBDA8) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            // Found Item Button
            GestureDetector(
              onTap: () {
                setState(() {
                  isLostItem = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: !isLostItem ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Found Item',
                  style: TextStyle(
                    color: !isLostItem ? const Color(0xFF5DBDA8) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5DBDA8),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5DBDA8),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: _openLocationPicker,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF5DBDA8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  _locationController.text.isNotEmpty 
                      ? _locationController.text 
                      : 'Location...',
                  style: TextStyle(
                    color: _locationController.text.isNotEmpty 
                        ? Colors.black 
                        : Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.location_on,
                color: _latitude != null ? const Color(0xFF5DBDA8) : Colors.grey[400],
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['locationName'] ?? '';
      });
    }
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement image picker
        _showImagePickerDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5DBDA8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Add Image',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF5DBDA8)),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement camera capture
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5DBDA8)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement gallery picker
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostButton() {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitPost,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5DBDA8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 2,
          ),
          child: _isLoading 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }

  Future<void> _submitPost() async {
    // Validate fields
    if (_titleController.text.isEmpty) {
      _showSnackBar('Please enter a title');
      return;
    }
    
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('Please enter a description');
      return;
    }
    
    if (_locationController.text.isEmpty) {
      _showSnackBar('Please enter a location');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Current user: ${user?.uid}');
    debugPrint('User email: ${user?.email}');
    
    if (user == null) {
      _showSnackBar('Please login to create a post');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get user data for the post
      String userName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
      String? userPhotoUrl = user.photoURL;
      
      try {
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['displayName'] ?? userName;
          userPhotoUrl = userData?['photoUrl'] ?? userPhotoUrl;
        }
      } catch (e) {
        debugPrint('Could not fetch user data: $e');
      }
      
      final postRef = firestore.collection('posts').doc();
      debugPrint('Creating post with ID: ${postRef.id}');
      
      final postData = <String, dynamic>{
        'postId': postRef.id,
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'type': isLostItem ? 'lost' : 'found',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'General',
        'images': <String>[],
        'location': _latitude != null && _longitude != null 
            ? GeoPoint(_latitude!, _longitude!) 
            : null,
        'locationName': _locationController.text.trim(),
        'status': 'active',
        'date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'likedBy': <String>[],
      };
      
      debugPrint('Post data: $postData');
      
      await postRef.set(postData);
      
      debugPrint('Post created successfully!');
      
      if (mounted) {
        _showSnackBar('Post created successfully!');
        Navigator.pop(context, true);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error Code: ${e.code}');
      debugPrint('Firebase Error Message: ${e.message}');
      debugPrint('Firebase Error Plugin: ${e.plugin}');
      _showSnackBar('Firebase Error: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error creating post: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Widget _buildBottomNavBar() {
    return const AppBottomNavBar(currentIndex: 2);
  }
}
