import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Model class for Place data
class Place {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String photoReference;

  Place({
    required this.id,
    required this.name,
    required this.address,
    this.rating = 0.0,
    this.photoReference = '',
  });
}

/// Controller class for handling map location and similar places data
class AddLocationMapController {
  final String apiKey;

  AddLocationMapController({required this.apiKey});

  /// Fetch details for a specific place using its ID
  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,formatted_address&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final loc = result['geometry']['location'];

          return {
            'success': true,
            'location': LatLng(loc['lat'], loc['lng']),
            'address': result['formatted_address'] ?? 'Address not available',
          };
        } else {
          debugPrint('Place details error: ${data["status"]}');
          return {'success': false, 'error': data['status']};
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return {'success': false, 'error': 'HTTP error ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch similar places based on type and location
  Future<List<Place>> fetchSimilarPlaces(LatLng location, String ezType, String currentPlaceId) async {
    try {
      // Convert ezType to the appropriate Google Places type
      String placeType = _convertEzTypeToGoogleType(ezType);

      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${location.latitude},${location.longitude}'
          '&radius=5000' // 5km radius
          '&type=$placeType'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<Place> places = [];

          for (var result in data['results']) {
            // Skip the current place
            if (result['place_id'] == currentPlaceId) continue;

            String photoRef = '';
            if (result['photos'] != null && result['photos'].isNotEmpty) {
              photoRef = result['photos'][0]['photo_reference'];
            }

            places.add(Place(
              id: result['place_id'],
              name: result['name'],
              address: result['vicinity'] ?? 'Address not available',
              rating: result['rating']?.toDouble() ?? 0.0,
              photoReference: photoRef,
            ));

            // Only get top 5 places
            if (places.length >= 5) break;
          }

          return places;
        } else {
          debugPrint('Similar places error: ${data["status"]}');
          return [];
        }
      } else {
        debugPrint('HTTP error when fetching similar places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching similar places: $e');
      return [];
    }
  }

  String _convertEzTypeToGoogleType(String ezType) {
    switch (ezType.toLowerCase()) {
      case 'restaurant':
        return 'restaurant';
      case 'hotel':
        return 'lodging';
      default:
        return '';
    }
  }

  /// Get photo URL from photo reference
  String getPhotoUrl(String photoReference) {
    if (photoReference.isEmpty) {
      return 'https://via.placeholder.com/100x100?text=No+Image';
    }
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=$photoReference'
        '&key=$apiKey';
  }


  IconData getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }
}