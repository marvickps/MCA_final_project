import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../common/config.dart';
import '../../itinerary_Menu/screens/itineraryMenu.dart';
import '../controllers/add_locationMap_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'itinerary_day_screen.dart';

class AddLocationShowMapPage extends StatefulWidget {
  const AddLocationShowMapPage({super.key});

  @override
  State<AddLocationShowMapPage> createState() => _AddLocationShowMapPageState();
}

class _AddLocationShowMapPageState extends State<AddLocationShowMapPage> {
  late String locationDay;
  late String placeId;
  late String placeName;
  late String ezType;
  late int dayId;

  late GoogleMapController _mapController;

  late ScrollController _scrollController;

  LatLng? _location;
  String _placeAddress = '';
  bool _isLoading = true;
  bool _isFetchingSimilarPlaces = true;
  List<Place> _similarPlaces = [];

  // Helper controller
  late AddLocationMapController _mapDataController;

  // Scrolling behavior properties
  bool _isSimilarPlacesVisible = false;
  double _similarPlacesSectionHeight = 0;
  final double _collapsedHeight = 0;
  final double _expandedHeight = 200;
  bool _isAddingToTrip = false;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize the controller with API key
    _mapDataController = AddLocationMapController(
      apiKey: dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    locationDay = args['location'];
    placeId = args['placeId'];
    placeName = args['placeName'];
    ezType = args['ezType'];
    dayId = args['dayId'];

    _fetchPlaceDetails();
  }

  Future<void> _fetchPlaceDetails() async {
    if (!mounted) return;
    setState(() {
        _isLoading = true;
      });


    final result = await _mapDataController.fetchPlaceDetails(placeId);

    if (result['success']) {
      setState(() {
        _location = result['location'] as LatLng;
        _placeAddress = result['address'] as String;
        _isLoading = false;
      });

      // After getting the location, fetch similar places
      _fetchSimilarPlaces();
    } else {
      setState(() {
        _isLoading = false;
        _isFetchingSimilarPlaces = false;
      });

      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading place details: ${result['error']}')),
      );
    }
  }

  Future<void> _fetchSimilarPlaces() async {
    if (_location == null) return;

    setState(() {
      _isFetchingSimilarPlaces = true;
    });

    final similarPlaces = await _mapDataController.fetchSimilarPlaces(
      _location!,
      ezType,
      placeId,
    );

    setState(() {
      _similarPlaces = similarPlaces;
      _isFetchingSimilarPlaces = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placeName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Google Map
          _location == null
              ? const Center(child: Text('Location not found'))
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _location!,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('selectedPlace'),
                position: _location!,
                infoWindow: InfoWindow(
                  title: placeName,
                  snippet: _placeAddress,
                ),
              ),
            },
          ),

          // Scrollable content at the bottom
          DraggableScrollableSheet(
            initialChildSize: 0.35, // Initial size of the sheet
            minChildSize: 0.15, // Minimum size when collapsed
            maxChildSize: 0.8, // Maximum size when expanded
            builder: (context, scrollController) {
              // Replace the current controller with the one from DraggableScrollableSheet
              _scrollController = scrollController;

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Main Place Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8716B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _mapDataController.getIconForType(ezType),
                                color: Colors.white,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  placeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 22,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _placeAddress,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isAddingToTrip ? null : () async {
                              setState(() {
                                _isAddingToTrip = true;
                              });
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              await userProvider.loadUser();
                              print({'itinerary_day_id': dayId,
                                'user_id': userProvider.userId!,
                                'place_id': placeId,
                                'type': ezType,});
                              if (userProvider.userId == null) {
                                throw Exception('User not authenticated');
                              }
                              final url = Uri.parse('$baseUrl/itinerary/add_itinerary_item');

                              final response = await http.post(
                                url,
                                headers: {'Content-Type': 'application/json',
                                  'Authorization': '${userProvider.tokenType} ${userProvider.accessToken}',},

                                body: jsonEncode({
                                  'itinerary_day_id': dayId,
                                  'user_id': userProvider.userId!,
                                  'place_id': placeId,
                                  'type': ezType,
                                }),
                              );


                              if (response.statusCode == 200 || response.statusCode == 201) {
                                int count = 0;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => itineraryDayScreen(
                                      dayId: dayId,
                                      locationDay: locationDay,
                                    ),
                                  ),
                                      (Route<dynamic> route) => count++ >= 3,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add item. Please try again. dayId: $dayId place: $placeId type:$ezType')),
                                );
                                setState(() {
                                  _isAddingToTrip = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: _isAddingToTrip
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                                : const Text(
                              'Add to Trip',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.red,
                              ),
                            ),
                          )



                        ],
                      ),
                    ),

                    // Similar Places Section - initially hidden, shown on scroll
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Similar Places',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Based on ${ezType.capitalize()}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 160, // Fixed height to prevent overflow
                            child: _isFetchingSimilarPlaces
                                ? const Center(
                              child: CircularProgressIndicator(),
                            )
                                : _similarPlaces.isEmpty
                                ? const Center(
                              child: Text('No similar places found'),
                            )
                                : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _similarPlaces.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemBuilder: (context, index) {
                                final place = _similarPlaces[index];
                                return _buildPlaceCard(place);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Additional space at the bottom for better scrolling
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return GestureDetector(
      onTap: () {
        // Navigate to the selected place
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddLocationShowMapPage(key: UniqueKey()),
            settings: RouteSettings(
              arguments: {
                'location': locationDay,
                'placeId': place.id,
                'placeName': place.name,
                'ezType': ezType,
                'dayId': dayId,
              },
            ),
          ),
        );
      },
      child: Container(
        width: 160, // Slightly reduced width
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
              child: Image.network(
                _mapDataController.getPhotoUrl(place.photoReference),
                height: 85, // Reduced height
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 85,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  place.rating > 0
                      ? Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        place.rating.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}