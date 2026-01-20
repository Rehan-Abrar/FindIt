import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../config/cloudinary_config.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../main/main_screen.dart';
import '../map/location_picker_screen.dart';
import '../../widgets/common/app_back_button.dart';

enum UploadStatus { pending, uploading, success, failed }

class _PickedImage {
  Uint8List? bytes;
  String? path;
  bool isWeb;
  UploadStatus status;
  String? uploadedUrl;

  _PickedImage({this.bytes, this.path, this.isWeb = false, this.status = UploadStatus.pending, this.uploadedUrl});
}

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
  String? _selectedCategory;
  final List<Map<String, String>> _categories = [
    {'label': 'Electronics', 'examples': 'phones, laptops, headphones, cameras'},
    {'label': 'Documents / IDs', 'examples': 'passport, ID card, certificates'},
    {'label': 'Keys & Access items', 'examples': 'house keys, car keys, RFID cards'},
    {'label': 'Jewelry / Accessories', 'examples': 'watches, rings, handbags'},
    {'label': 'Clothing / Footwear', 'examples': 'valuable shoes, jackets, bags'},
    {'label': 'Pets', 'examples': 'dogs, cats, birds'},
    {'label': 'Miscellaneous', 'examples': 'instruments, collectibles'},
  ];
  
  // Location coordinates
  double? _latitude;
  double? _longitude;
  
  final List<_PickedImage> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

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
                    
                    // Category Field (Dropdown)
                    _buildCategoryDropdown(),
                    
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
                    _buildImagePreview(),
                    const SizedBox(height: 12),
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
    return AppBackButton(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      },
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

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5DBDA8),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          isDense: true,
          decoration: InputDecoration(
            hintText: 'Select category...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          ),
          items: _categories.map((c) {
            final label = c['label']!;
            return DropdownMenuItem<String>(
              value: label,
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategory = val;
              _categoryController.text = val ?? '';
            });
          },
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
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5DBDA8)),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImagesFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (kIsWeb) {
        // On web, ImagePicker shows the browser file picker (may allow camera on some browsers)
        final XFile? picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _selectedImages.add(_PickedImage(bytes: bytes, path: picked.name, isWeb: true));
          });
        }
      } else {
        final XFile? picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (picked != null) {
          setState(() {
            _selectedImages.add(_PickedImage(path: picked.path, isWeb: false));
          });
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Camera error: ${e.toString()}');
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      if (kIsWeb) {
        // On web, pickMultiImage is not reliably supported. Use single-image picker.
        final XFile? picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _selectedImages.add(_PickedImage(bytes: bytes, path: picked.name, isWeb: true));
          });
          _showSnackBar('Image added. Select "Add Image" again for more images.');
        }
      } else {
        final List<XFile>? picked = await _imagePicker.pickMultiImage(imageQuality: 80);
        if (picked != null && picked.isNotEmpty) {
          setState(() {
            for (final x in picked) {
              _selectedImages.add(_PickedImage(path: x.path, isWeb: false));
            }
          });
        }
      }
    } on Exception catch (e) {
      _showSnackBar('Gallery error: ${e.toString()}');
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImages.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final item = _selectedImages[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.isWeb
                        ? (item.bytes != null
                            ? Image.memory(item.bytes!, fit: BoxFit.cover)
                            : const SizedBox.shrink())
                        : Image.file(File(item.path ?? ''), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildUploadStatusIcon(item.status),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.uploading:
        return const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case UploadStatus.success:
        return Container(
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.8), shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: const Icon(Icons.check, size: 16, color: Colors.white),
        );
      case UploadStatus.failed:
        return Container(
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.9), shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: const Icon(Icons.error, size: 16, color: Colors.white),
        );
      case UploadStatus.pending:
      default:
        return Container(
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.6), shape: BoxShape.circle),
          padding: const EdgeInsets.all(4),
          child: const Icon(Icons.hourglass_empty, size: 16, color: Colors.white),
        );
    }
  }

  Future<String?> _uploadToCloudinary(_PickedImage img, String postId, int index) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
      request.fields['folder'] = 'posts/$postId';

      if (img.isWeb) {
        final bytes = img.bytes;
        if (bytes == null) return null;
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${postId}_$index.jpg',
        );
        request.files.add(multipartFile);
      } else {
        final file = File(img.path!);
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: '${postId}_$index.jpg',
        );
        request.files.add(multipartFile);
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
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

      // Upload selected images to Cloudinary (if any) and collect URLs
      final List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          final _PickedImage img = _selectedImages[i];
          try {
            setState(() {
              img.status = UploadStatus.uploading;
            });
            final url = await _uploadToCloudinary(img, postRef.id, i);
            if (url != null) {
              uploadedImageUrls.add(url);
              setState(() {
                img.status = UploadStatus.success;
                img.uploadedUrl = url;
              });
              _showSnackBar('Image ${i + 1} uploaded');
            } else {
              debugPrint('Cloudinary returned null URL for image $i');
              setState(() {
                img.status = UploadStatus.failed;
              });
              _showSnackBar('Failed to upload one or more images.');
            }
          } catch (e) {
            debugPrint('Image upload failed: $e');
            setState(() {
              img.status = UploadStatus.failed;
            });
            _showSnackBar('Failed to upload one or more images.');
          }
        }
      }

      final postData = <String, dynamic>{
        'postId': postRef.id,
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'type': isLostItem ? 'lost' : 'found',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'General',
        'images': uploadedImageUrls,
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
    return const SizedBox.shrink();
  }
}
