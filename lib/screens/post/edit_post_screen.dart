import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../map/location_picker_screen.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;
  
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  bool isLostItem = true;
  bool _isLoading = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;
  
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing post data
    isLostItem = widget.post.type == 'lost';
    _titleController.text = widget.post.title;
    _descriptionController.text = widget.post.description;
    _categoryController.text = widget.post.category;
    _locationController.text = widget.post.locationName;
    _selectedDate = widget.post.date;
    if (_selectedDate != null) {
      _dateController.text = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    }
    if (widget.post.location != null) {
      _latitude = widget.post.location!.latitude;
      _longitude = widget.post.location!.longitude;
    }
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              _buildBackButton(),
              
              const SizedBox(height: 24),
              
              // Title
              const Center(
                child: Text(
                  'Edit Post',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5DBDA8),
                  ),
                ),
              ),
              
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
              
              const SizedBox(height: 24),
              
              // Update Button
              _buildUpdateButton(),
              
              const SizedBox(height: 16),
              
              // Delete Button
              _buildDeleteButton(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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
            GestureDetector(
              onTap: () => setState(() => isLostItem = true),
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
            GestureDetector(
              onTap: () => setState(() => isLostItem = false),
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
      initialDate: _selectedDate ?? DateTime.now(),
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

  Widget _buildUpdateButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _updatePost,
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
                'Update Post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isLoading ? null : _confirmDelete,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Delete Post',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePost() async {
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

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      
      await firestore.collection('posts').doc(widget.post.postId).update({
        'type': isLostItem ? 'lost' : 'found',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim().isNotEmpty 
            ? _categoryController.text.trim() 
            : 'General',
        'location': _latitude != null && _longitude != null 
            ? GeoPoint(_latitude!, _longitude!) 
            : widget.post.location,
        'locationName': _locationController.text.trim(),
        'date': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
      });

      if (mounted) {
        _showSnackBar('Post updated successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error updating post: $e');
      _showSnackBar('Error updating post');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.postId)
          .delete();

      if (mounted) {
        _showSnackBar('Post deleted successfully!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      _showSnackBar('Error deleting post');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
}
