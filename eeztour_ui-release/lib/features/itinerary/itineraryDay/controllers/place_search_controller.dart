import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../common/config.dart';

class PlaceSuggestion {
  final String placeId;
  final String name;
  final String address;
  final String? rating;

  PlaceSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
    this.rating,
  });
}

class PlaceSearchController extends ChangeNotifier {
  final String apiKey; // Google Maps API key


  List<PlaceSuggestion> _nearbyPlaces = [];
  List<PlaceSuggestion> _localPlaces = [];
  List<PlaceSuggestion> _searchSuggestions = [];
  bool _isLoading = false;
  String? _selectedPlaceId;
  String? _selectedPlaceName;
  String? _error;
  String? _lastSearchLocation;
  String? _lastSearchType;
  String? _lastLocalType;
  DateTime? _lastGlobalRefresh;
  DateTime? _lastLocalRefresh;
  static const Duration _cacheTimeout = Duration(minutes: 5); // Cache timeout

  // Getters
  List<PlaceSuggestion> get nearbyPlaces => _nearbyPlaces;
  List<PlaceSuggestion> get localPlaces => _localPlaces;
  List<PlaceSuggestion> get searchSuggestions => _searchSuggestions;
  bool get isLoading => _isLoading;
  String? get selectedPlaceId => _selectedPlaceId;
  String? get selectedPlaceName => _selectedPlaceName;
  String? get error => _error;
  String? get lastSearchLocation => _lastSearchLocation;
  String? get lastSearchType => _lastSearchType;

  PlaceSearchController({
    required this.apiKey,

  });


  // Load nearby places based on location and type using a text search query
  Future<void> loadNearbyPlaces(String location, String placeType, {bool forceRefresh = false}) async {
    final now = DateTime.now();


    // Check if we need to reload (different location/type, forced, or cache expired)
    bool shouldRefresh = forceRefresh ||
        _lastSearchLocation != location ||
        _lastSearchType != placeType ||
        _nearbyPlaces.isEmpty ||
        (_lastGlobalRefresh != null && now.difference(_lastGlobalRefresh!) > _cacheTimeout);

    if (!shouldRefresh) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _lastSearchLocation = location;
    _lastSearchType = placeType;
    notifyListeners();

    try {
      // Create a query that includes both the place type and location
      final String query = '$placeType in $location';
      final queryEncoded = Uri.encodeComponent(query);

      // Use the text search API with the combined query
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?query=$queryEncoded'
              '&type=$placeType'
              '&key=$apiKey',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        List<PlaceSuggestion> places = [];

        for (var place in (data['results'] as List).take(10)) {
          places.add(
            PlaceSuggestion(
              placeId: place['place_id'],
              name: place['name'],
              address: place['vicinity'] ?? '',
              rating: place['rating']?.toString() ?? 'N/A',
            ),
          );
        }

        // Sort by rating (highest first)
        places.sort((a, b) {
          if (a.rating == 'N/A') return 1;
          if (b.rating == 'N/A') return -1;
          return double.parse(b.rating!).compareTo(double.parse(a.rating!));
        });

        _nearbyPlaces = places;
        _lastGlobalRefresh = now;
        debugPrint('Global places loaded: ${places.length} items');
      } else {
        _nearbyPlaces = [];
        _error = "No places found. Status: ${data['status']}";
      }
    } catch (e) {
      debugPrint('Error loading nearby places: $e');
      _nearbyPlaces = [];
      _error = "Error loading places: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load local places from your API
  Future<void> loadLocalPlaces(BuildContext context, String ezType, {bool forceRefresh = false}) async {
    final now = DateTime.now();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    // Check if we need to reload (different type, forced, or cache expired)
    bool shouldRefresh = forceRefresh ||
        _lastLocalType != ezType ||
        _localPlaces.isEmpty ||
        (_lastLocalRefresh != null && now.difference(_lastLocalRefresh!) > _cacheTimeout);

    if (!shouldRefresh) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _lastLocalType = ezType;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/itinerary/get_local_resource/${userProvider.userId}/$ezType'),
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final List<dynamic> data = json.decode(responseBody);

        List<PlaceSuggestion> places = [];

        for (var item in data) {
          String placeId = '';
          String name = '';
          String address = '';
          String? rating;

          if (ezType.toLowerCase() == 'hotel') {
            placeId = item['place_id'] ?? '';
            name = item['name'] ?? '';
            address = item['address'] ?? '';
            rating = item['google_rating']?.toString();
          } else if (ezType.toLowerCase() == 'restaurant') {
            placeId = item['place_id'] ?? '';
            name = item['name'] ?? '';
            address = item['address'] ?? '';
            rating = item['rating']?.toString();
          }

          places.add(
            PlaceSuggestion(
              placeId: placeId,
              name: name,
              address: address,
              rating: rating ?? 'N/A',
            ),
          );
        }

        // Sort by rating (highest first)
        places.sort((a, b) {
          if (a.rating == 'N/A') return 1;
          if (b.rating == 'N/A') return -1;
          return double.parse(b.rating!).compareTo(double.parse(a.rating!));
        });

        _localPlaces = places;
        _lastLocalRefresh = now;
        debugPrint('Local places loaded: ${places.length} items');
      } else {
        _localPlaces = [];
        _error = "Failed to load local places. Status: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint('Error loading local places: $e');
      _localPlaces = [];
      _error = "Error loading local places: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search for places based on user input
  Future<void> searchPlaces(String query, String location, String placeType) async {
    if (query.trim().isEmpty) {
      _searchSuggestions = List.from(_nearbyPlaces);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Construct search query with location context
      final String searchQuery = '$query $placeType';
      final queryEncoded = Uri.encodeComponent(searchQuery);

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
              '?query=$queryEncoded'
              '&key=$apiKey',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        List<PlaceSuggestion> places = [];

        for (var place in data['results'] as List) {
          places.add(
            PlaceSuggestion(
              placeId: place['place_id'],
              name: place['name'],
              address: place['formatted_address'] ?? place['vicinity'] ?? '',
              rating: place['rating']?.toString() ?? 'N/A',
            ),
          );
        }

        _searchSuggestions = places;
      } else {
        _searchSuggestions = [];
        _error = "No places found matching your search.";
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      _searchSuggestions = [];
      _error = "Error searching places: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search local places based on user input
  Future<void> searchLocalPlaces(String query, String ezType) async {
    if (query.trim().isEmpty) {
      _searchSuggestions = List.from(_localPlaces);
      notifyListeners();
      return;
    }

    // Filter local places by query
    final filteredPlaces = _localPlaces.where((place) {
      return place.name.toLowerCase().contains(query.toLowerCase()) ||
          place.address.toLowerCase().contains(query.toLowerCase());
    }).toList();

    _searchSuggestions = filteredPlaces;
    notifyListeners();
  }

  // Method to select a place
  void selectPlace(String placeId, String name) {
    _selectedPlaceId = placeId;
    _selectedPlaceName = name;
    _searchSuggestions = [];
    notifyListeners();
  }

  // Method to clear search results
  void clearSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }

  // Method to reset the controller
  void reset() {
    _nearbyPlaces = [];
    _localPlaces = [];
    _searchSuggestions = [];
    _selectedPlaceId = null;
    _selectedPlaceName = null;
    _lastSearchLocation = null;
    _lastSearchType = null;
    _lastLocalType = null;
    _lastGlobalRefresh = null;
    _lastLocalRefresh = null;
    _error = null;
    notifyListeners();
  }

  // Method to check if data is stale and needs refresh
  bool get isGlobalDataStale {
    if (_lastGlobalRefresh == null) return true;
    return DateTime.now().difference(_lastGlobalRefresh!) > _cacheTimeout;
  }

  bool get isLocalDataStale {
    if (_lastLocalRefresh == null) return true;
    return DateTime.now().difference(_lastLocalRefresh!) > _cacheTimeout;
  }

  // Method to get last refresh time for display
  String? get lastRefreshTime {
    final lastRefresh = _lastGlobalRefresh ?? _lastLocalRefresh;
    if (lastRefresh == null) return null;

    final difference = DateTime.now().difference(lastRefresh);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}