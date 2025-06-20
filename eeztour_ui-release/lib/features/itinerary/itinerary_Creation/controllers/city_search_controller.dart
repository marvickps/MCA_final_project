import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class CitySearchController extends ChangeNotifier {
  List<AutocompletePrediction> _predictions = [];
  GooglePlace? _googlePlace;
  String? _selectedCityName;
  String? _selectedPlaceId;
  bool _isLoading = false;
  Timer? _debounce;
  bool _isInitialized = false;
  String _lastQuery = '';
  bool _shouldSearch = false;

  CitySearchController() {
    _initGooglePlace();
  }

  List<AutocompletePrediction> get predictions => _predictions;
  bool get isLoading => _isLoading;
  String? get selectedCityName => _selectedCityName;
  String? get selectedPlaceId => _selectedPlaceId;
  bool get isInitialized => _isInitialized;

  Future<void> _initGooglePlace() async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _googlePlace = GooglePlace(apiKey);
        _isInitialized = true;
        notifyListeners();
      } else {
        print('API key not found in environment variables');
      }
    } catch (e) {
      print('Error initializing Google Place: $e');
    }
  }

  void updateQuery(String query) {
    // Clear predictions if query is empty
    if (query.isEmpty) {
      _predictions = [];
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
      _predictions = [];
      _shouldSearch = false;
      notifyListeners();
      return;
    }

    // Enable searching
    _shouldSearch = true;

    // Debounce the input
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_shouldSearch) {
        _getPlacePredictions(query);
      }
    });
  }

  Future<void> _getPlacePredictions(String input) async {
    if (!_shouldSearch || !_isInitialized || _googlePlace == null || input.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      final result = await _googlePlace!.autocomplete.get(
        input,
        types: '(cities)',
        language: 'en',
      );

      _isLoading = false;
      if (result != null && result.predictions != null) {
        _predictions = result.predictions!;
      } else {
        _predictions = [];
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _predictions = [];
      print('Place Autocomplete Exception: $e');
      notifyListeners();
    }
  }

  void selectPrediction(AutocompletePrediction prediction) {
    if (prediction.placeId == null || prediction.placeId!.isEmpty) return;
    
    _selectedPlaceId = prediction.placeId;
    _selectedCityName = prediction.description;
    
    _predictions = [];
    _shouldSearch = false;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCityName = null;
    _selectedPlaceId = null;
    _predictions = [];
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