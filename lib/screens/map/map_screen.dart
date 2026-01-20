import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../models/post_model.dart';
import '../../widgets/navigation/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../post/post_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Default to Lahore, Pakistan
  LatLng _currentCenter = const LatLng(31.5204, 74.3587);
  double _currentZoom = 13.0;
  
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  
  List<PostModel> _postsInView = [];
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  
  // Map bounds for filtering
  LatLngBounds? _currentBounds;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _startPostsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions are permanently denied');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _currentCenter = _userLocation!;
        _isLoadingLocation = false;
      });

      _mapController.move(_currentCenter, _currentZoom);
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _startPostsStream() {
    _postsSubscription = _firestore
        .collection('posts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      _filterPostsByBounds(snapshot.docs);
    });
  }

  void _filterPostsByBounds(List<QueryDocumentSnapshot> docs) {
    if (_currentBounds == null) return;

    final filtered = <PostModel>[];
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as GeoPoint?;
      
      if (location != null) {
        final postLatLng = LatLng(location.latitude, location.longitude);
        
        if (_currentBounds!.contains(postLatLng)) {
          final postData = Map<String, dynamic>.from(data);
          postData['postId'] = doc.id;
          filtered.add(PostModel.fromMap(postData));
        }
      }
    }

    setState(() {
      _postsInView = filtered;
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);

    try {
      // Using Nominatim API for geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FindIt App'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          
          setState(() {
            _currentCenter = LatLng(lat, lon);
          });
          
          _mapController.move(_currentCenter, 14.0);
        } else {
          _showSnackBar('Location not found');
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      _showSnackBar('Error searching location');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _onMapMove(LatLng? center, double? zoom) {
    if (center != null) _currentCenter = center;
    if (zoom != null) _currentZoom = zoom;
    
    // Get bounds from map controller
    _currentBounds = _mapController.camera.visibleBounds;
    
    // Re-filter posts when map moves
    _firestore
        .collection('posts')
        .where('status', isEqualTo: 'active')
        .get()
        .then((snapshot) {
      _filterPostsByBounds(snapshot.docs);
    });
  }

  void _showPostDetails(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Post type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: post.type == 'lost' 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.type.toUpperCase(),
                  style: TextStyle(
                    color: post.type == 'lost' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    post.locationName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description preview
              Text(
                post.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF5DBDA8),
                    backgroundImage: post.userPhotoUrl != null
                        ? NetworkImage(post.userPhotoUrl!)
                        : null,
                    child: post.userPhotoUrl == null
                        ? Text(
                            post.userName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // View Post Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DBDA8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Post',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                _onMapMove(position.center, position.zoom);
              },
            ),
            children: [
              // OpenStreetMap Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.findit.app',
              ),
              
              // Post Markers
              MarkerLayer(
                markers: _postsInView.map((post) {
                  final location = post.location;
                  if (location == null) return null;
                  
                  return Marker(
                    point: LatLng(location.latitude, location.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showPostDetails(post),
                      child: Container(
                        decoration: BoxDecoration(
                          color: post.type == 'lost' ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
              
              // User Location Marker
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Header with Search
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5DBDA8),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // No back button needed as it's a main tab
                    
                    // Search Field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search Location...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: _searchLocation,
                        ),
                      ),
                    ),
                    
                    // Close/Search button
                    GestureDetector(
                      onTap: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchController.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: _isSearching
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Center on user location button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _isLoadingLocation
                  ? null
                  : () {
                      if (_userLocation != null) {
                        _mapController.move(_userLocation!, 15.0);
                      } else {
                        _getUserLocation();
                      }
                    },
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF5DBDA8),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Color(0xFF5DBDA8),
                    ),
            ),
          ),
          
          // Posts Panel at Bottom (above nav bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // Space for bottom nav bar
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Posts count badge
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5DBDA8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_postsInView.length} Available Posts',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Posts list
                if (_postsInView.isNotEmpty)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _postsInView.length,
                      itemBuilder: (context, index) {
                        final post = _postsInView[index];
                        return _buildPostCard(post);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return GestureDetector(
      onTap: () => _showPostDetails(post),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF5DBDA8),
              backgroundImage: post.userPhotoUrl != null
                  ? NetworkImage(post.userPhotoUrl!)
                  : null,
              child: post.userPhotoUrl == null
                  ? Text(
                      post.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Post info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    post.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Item ${post.type} in ${post.locationName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatTimeAgo(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
