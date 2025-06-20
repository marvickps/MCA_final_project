import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import 'package:http/http.dart' as http;

class HotelSearchController extends ChangeNotifier {
  final String apiKey; // Your Google Maps API key

  List<HotelSuggestion> _topRatedHotels = [];
  List<HotelSuggestion> _searchSuggestions = [];
  bool _isLoading = false;
  String? _selectedHotelId;
  String? _selectedHotelName;
  String? _error;
  String? _lastSearchCity;

  // Getters
  List<HotelSuggestion> get topHotels => _topRatedHotels;
  List<HotelSuggestion> get searchSuggestions => _searchSuggestions;
  bool get isLoading => _isLoading;
  String? get selectedHotelId => _selectedHotelId;
  String? get selectedHotelName => _selectedHotelName;
  String? get error => _error;
  String? get lastSearchCity => _lastSearchCity;

  HotelSearchController({required this.apiKey});

  // Load top 5 rated hotels for initial display
  Future<void> loadTopHotelsForCity(String cityName, {bool forceRefresh = false}) async {
    // Check if we need to reload (different city or forced)
    if (!forceRefresh && _lastSearchCity == cityName && _topRatedHotels.isNotEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _lastSearchCity = cityName;
    notifyListeners();

    try {
      final String query = 'top rated hotels in $cityName';
      final queryEncoded = Uri.encodeComponent(query);

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$queryEncoded'
          '&type=lodging'
          '&key=$apiKey',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        List<HotelSuggestion> hotels = [];

        for (var place in (data['results'] as List).take(5)) {
          hotels.add(
            HotelSuggestion(
              placeId: place['place_id'],
              name: place['name'],
              address: place['formatted_address'] ?? '',
              rating: place['rating']?.toString() ?? 'N/A',
              priceLevel: place['price_level']?.toString(),
            ),
          );
        }

        // Sort by rating (highest first)
        hotels.sort((a, b) {
          if (a.rating == 'N/A') return 1;
          if (b.rating == 'N/A') return -1;
          return double.parse(b.rating).compareTo(double.parse(a.rating));
        });

        _topRatedHotels = hotels;
      } else {
        _topRatedHotels = [];
        _error = "No hotels found. Status: ${data['status']}";
      }
    } catch (e) {
      debugPrint('Error loading top hotels: $e');
      _topRatedHotels = [];
      _error = "Error loading hotels: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search for hotels based on user input
  Future<void> searchHotels(String query, String cityName) async {
    if (query.trim().isEmpty) {
      _searchSuggestions = List.from(_topRatedHotels);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Construct search query with city context
      final String searchQuery = '$query hotels in $cityName';
      final queryEncoded = Uri.encodeComponent(searchQuery);

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$queryEncoded'
          '&type=lodging'
          '&key=$apiKey',
        ),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        List<HotelSuggestion> hotels = [];

        for (var place in data['results'] as List) {
          hotels.add(
            HotelSuggestion(
              placeId: place['place_id'],
              name: place['name'],
              address: place['formatted_address'] ?? '',
              rating: place['rating']?.toString() ?? 'N/A',
              priceLevel: place['price_level']?.toString(),
            ),
          );
        }

        _searchSuggestions = hotels;
      } else {
        _searchSuggestions = [];
        _error = "No hotels found matching your search.";
      }
    } catch (e) {
      debugPrint('Error searching hotels: $e');
      _searchSuggestions = [];
      _error = "Error searching hotels: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to select a hotel
  void selectHotel(String placeId, String name) {
    _selectedHotelId = placeId;
    _selectedHotelName = name;
    _searchSuggestions = []; // Clear suggestions after selection
    notifyListeners();
  }

  // Method to clear search results
  void clearSuggestions() {
    _searchSuggestions = [];
    notifyListeners();
  }

  // Method to reset the controller
  void reset() {
    _topRatedHotels = [];
    _searchSuggestions = [];
    _selectedHotelId = null;
    _selectedHotelName = null;
    _lastSearchCity = null;
    _error = null;
    notifyListeners();
  }
}

