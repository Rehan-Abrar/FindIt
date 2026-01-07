import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  
  const LocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  // Default to Lahore, Pakistan
  LatLng _selectedLocation = const LatLng(31.5204, 74.3587);
  String _locationName = '';
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  bool _isLoadingUserLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _getAddressFromCoordinates(_selectedLocation);
    } else {
      _getUserLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingUserLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingUserLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingUserLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingUserLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingUserLocation = false;
      });

      _mapController.move(_selectedLocation, 15.0);
      _getAddressFromCoordinates(_selectedLocation);
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoadingUserLocation = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);

    try {
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
          final displayName = data[0]['display_name'] ?? '';
          
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _locationName = _shortenAddress(displayName);
          });
          
          _mapController.move(_selectedLocation, 15.0);
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

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() => _isLoadingAddress = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json',
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FindIt App'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] ?? '';
        
        setState(() {
          _locationName = _shortenAddress(displayName);
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  String _shortenAddress(String fullAddress) {
    // Split by comma and take first 2-3 parts
    final parts = fullAddress.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      return '${parts[0]}, ${parts[1]}, ${parts[2]}';
    } else if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return fullAddress;
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _getAddressFromCoordinates(point);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'locationName': _locationName,
    });
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
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.findit.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    
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
                    
                    // Search/Loading indicator
                    GestureDetector(
                      onTap: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchLocation(_searchController.text);
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
                                Icons.search,
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
          
          // My Location Button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _isLoadingUserLocation ? null : _getUserLocation,
              child: _isLoadingUserLocation
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
          
          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Instruction
                  const Text(
                    'Tap on the map to select location',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Selected Location
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DBDA8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5DBDA8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF5DBDA8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingAddress
                              ? const Text(
                                  'Loading address...',
                                  style: TextStyle(color: Colors.grey),
                                )
                              : Text(
                                  _locationName.isNotEmpty 
                                      ? _locationName 
                                      : 'Select a location',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _locationName.isNotEmpty ? _confirmLocation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DBDA8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
