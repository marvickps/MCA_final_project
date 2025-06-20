import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class LocationSearchController extends ChangeNotifier {
  List<AutocompletePrediction> _suggestions = [];
  GooglePlace? _googlePlace;
  String? _selectedLocationId;
  String? _selectedLocationName;
  bool _isLoading = false;
  Timer? _debounce;
  bool _isInitialized = false;
  String _lastQuery = '';
  bool _shouldSearch = false;
  String? _error;

  // Getters
  List<AutocompletePrediction> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get selectedLocationId => _selectedLocationId;
  String? get selectedLocationName => _selectedLocationName;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  LocationSearchController() {
    _initGooglePlace();
  }

  Future<void> _initGooglePlace() async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _googlePlace = GooglePlace(apiKey);
        _isInitialized = true;
        notifyListeners();
      } else {
        print('API key not found in environment variables');
        _error = 'API key not found';
        notifyListeners();
      }
    } catch (e) {
      print('Error initializing Google Place: $e');
      _error = 'Error initializing: $e';
      notifyListeners();
    }
  }

  void updateQuery(String query) {
    // Clear suggestions if query is empty
    if (query.isEmpty) {
      _suggestions = [];
      _lastQuery = '';
      _shouldSearch = false;
      notifyListeners();
      return;
    }

    // Skip if query is the same as last time
    if (query == _lastQuery) return;

    // Store the current query
    _lastQuery = query;

    // Only search if query has at least 2 characters
    if (query.length < 2) {
      _suggestions = [];
      _shouldSearch = false;
      notifyListeners();
      return;
    }

    // Enable searching
    _shouldSearch = true;
    _error = null;

    // Debounce the input
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_shouldSearch) {
        searchLocations(query);
      }
    });
  }

  Future<void> searchLocations(String query) async {
    if (!_shouldSearch || !_isInitialized || _googlePlace == null || query.isEmpty) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _googlePlace!.autocomplete.get(
        query,
        types: 'establishment|geocode', // Include both establishments and geographic locations
        language: 'en',
      );

      if (result != null && result.predictions != null) {
        _suggestions = result.predictions!;
      } else {
        _suggestions = [];
        _error = "No locations found matching your search.";
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
      _suggestions = [];
      _error = "Error searching locations: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectLocation(AutocompletePrediction prediction) {
    if (prediction.placeId == null || prediction.placeId!.isEmpty) return;
    
    _selectedLocationId = prediction.placeId;
    _selectedLocationName = prediction.description;
    
    _suggestions = []; // Clear suggestions after selection
    _shouldSearch = false;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  void reset() {
    _suggestions = [];
    _selectedLocationId = null;
    _selectedLocationName = null;
    _error = null;
    _lastQuery = '';
    _shouldSearch = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}