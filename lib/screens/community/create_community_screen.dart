import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/community_model.dart';
import '../map/location_picker_screen.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedType = 'location'; // 'location' or 'interest'
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
                  'Create Community',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5DBDA8),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Community Name
              _buildLabel('Community Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter community name...',
              ),
              
              const SizedBox(height: 20),
              
              // Description
              _buildLabel('Description'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Describe your community...',
                maxLines: 3,
              ),
              
              const SizedBox(height: 20),
              
              // Community Type
              _buildLabel('Community Type'),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              
              const SizedBox(height: 20),
              
              // Location (optional for interest-based)
              _buildLabel(_selectedType == 'location' 
                  ? 'Location (Required)' 
                  : 'Location (Optional)'),
              const SizedBox(height: 8),
              _buildLocationField(),
              
              const SizedBox(height: 32),
              
              // Create Button
              _buildCreateButton(),
            ],
          ),
        ),
      ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
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

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5DBDA8),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'location'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'location' 
                      ? Colors.white 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: _selectedType == 'location' 
                          ? const Color(0xFF5DBDA8) 
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Location',
                      style: TextStyle(
                        color: _selectedType == 'location' 
                            ? const Color(0xFF5DBDA8) 
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedType = 'interest'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'interest' 
                      ? Colors.white 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.interests,
                      size: 18,
                      color: _selectedType == 'interest' 
                          ? const Color(0xFF5DBDA8) 
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Interest',
                      style: TextStyle(
                        color: _selectedType == 'interest' 
                            ? const Color(0xFF5DBDA8) 
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                      : 'Select location on map...',
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
                color: _latitude != null 
                    ? const Color(0xFF5DBDA8) 
                    : Colors.grey[400],
                size: 24,
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

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createCommunity,
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
                'Create Community',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _createCommunity() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a community name');
      return;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar('Please enter a description');
      return;
    }
    
    if (_selectedType == 'location' && _latitude == null) {
      _showSnackBar('Please select a location for location-based community');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please log in to create a community');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get user name
      String userName = user.displayName ?? 'Unknown';
      try {
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['displayName'] ?? userName;
        }
      } catch (e) {
        debugPrint('Could not fetch user data: $e');
      }

      final docRef = firestore.collection('communities').doc();
      
      final community = CommunityModel(
        id: docRef.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationController.text.trim(),
        memberCount: 1, // Creator is first member
        createdBy: user.uid,
        createdByName: userName,
        memberIds: [user.uid], // Creator auto-joins
      );

      await docRef.set(community.toMap());

      if (mounted) {
        _showSnackBar('Community created successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating community: $e');
      _showSnackBar('Error creating community');
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
