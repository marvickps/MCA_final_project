import 'package:eeztour/common/config.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/route_model.dart';
import '../models/day_itineraryMap_model.dart';

class ItineraryRouteController extends ChangeNotifier {
  final List<DayItineraryModel> _days = [];
  final Map<String, List<RouteModel>> _dayRoutes = {};
  bool _isLoading = false;
  int _dataVersion = 0; // Add data version counter
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final List<Color> _routeColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];

  Future<void> loadSampleItineraryData(int id, String day) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/itinerary/get_route/$id?day=$day'),
      );

      if (response.statusCode == 200) {
        final sampleData = json.decode(response.body);
        loadItineraryData(sampleData);
      } else {
        print("Failed to load itinerary data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error loading itinerary data: $e");
    }
  }

  //actual model
  List<DayItineraryModel> get days => List.unmodifiable(_days);

  Map<String, List<RouteModel>> get dayRoutes =>
      Map.unmodifiable(_dayRoutes); 

  bool get isLoading => _isLoading;
  int get dataVersion => _dataVersion;

  Future<void> loadItineraryData(List<dynamic> itineraryJson) async {
    _isLoading = true;
    _days.clear();
    _dayRoutes.clear();
    notifyListeners();

    try {
      for (int i = 0; i < itineraryJson.length; i++) {
        final color = _routeColors[i % _routeColors.length];
        final day = DayItineraryModel.fromJson(itineraryJson[i], color: color);
        _days.add(day);
      }

      await Future.wait(
        _days.map((day) => _calculateRoutesForDay(day)),
      ); 

      debugPrint('Finished calculating all routes.');
      // Debug check for routes
      _dayRoutes.forEach((dayId, routes) {
        debugPrint(
          'Day $dayId has ${routes.length} routes stored in controller.',
        );
        for (var route in routes) {
          debugPrint('  - Route ${route.id}: ${route.points.length} points');
        }
      });

    } catch (e) {
      debugPrint('Error loading itinerary data: $e');
      // Consider setting an error state here
    } finally {
      _isLoading = false;
      _dataVersion++; 
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> transformBackendResponse(
    List<dynamic> backendResponse,
  ) {
    final Map<String, Map<String, dynamic>> dayMap = {};

    for (var entry in backendResponse) {
      final itemMap = entry['item'] as Map<String, dynamic>;
      final itemKey = itemMap.keys.first;
      final placeData = itemMap[itemKey];

      final dayId = entry['day_id']?.toString() ?? 'default';
      final date = entry['date']?.toString() ?? '';

      if (!dayMap.containsKey(dayId)) {
        dayMap[dayId] = {'day_id': dayId, 'date': date, 'item': {}};
      }

      final uniqueKey = 'place_${placeData['order']}';
      dayMap[dayId]!['place'][uniqueKey] = {
        'order': placeData['order'],
        'placeID': placeData['placeID'],
        'lat': placeData['lat'].toString(),
        'lng': placeData['lng'].toString(),
        'placeType': placeData['placeType'],
        'name': placeData['name'],
        'address': placeData['address'],
      };
    }

    return dayMap.values.toList();
  }

  Future<void> _calculateRoutesForDay(DayItineraryModel day) async {
    final List<PlaceModel> sortedPlaces = day.sortedPlaces;

    if (sortedPlaces.length < 2) {
      debugPrint('Not enough places for day ${day.dayId} to calculate routes.');
      return; // Exit if not enough places
    }

    List<RouteModel> routesForThisDay =
        []; // Temporary list for this day's routes

    for (int i = 0; i < sortedPlaces.length - 1; i++) {
      final PlaceModel origin = sortedPlaces[i];
      final PlaceModel destination = sortedPlaces[i + 1];

      // Ensure coordinates are valid before calling API
      if (origin.latitude == 0.0 ||
          origin.longitude == 0.0 ||
          destination.latitude == 0.0 ||
          destination.longitude == 0.0) {
        debugPrint(
          'Skipping route calculation due to invalid coordinates for ${origin.name} or ${destination.name}',
        );
        continue;
      }

      try {
        debugPrint(
          'Calculating route for Day ${day.dayId}: ${origin.name} (${origin.latitude}, ${origin.longitude}) to ${destination.name} (${destination.latitude}, ${destination.longitude})',
        );

        final PolylinePoints polylinePoints = PolylinePoints();
        final PointLatLng originPoint = PointLatLng(
          origin.latitude,
          origin.longitude,
        );
        final PointLatLng destinationPoint = PointLatLng(
          destination.latitude,
          destination.longitude,
        );

        final result = await polylinePoints.getRouteBetweenCoordinates(
          apiKey,
          originPoint,
          destinationPoint,
          travelMode: TravelMode.driving,
        );

        debugPrint(
          'Polyline API Status for ${origin.name} -> ${destination.name}: ${result.status}, Error: ${result.errorMessage}',
        );

        if (result.points.isNotEmpty) {
          List<LatLng> points =
              result.points
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList();

          debugPrint(
            'Route from ${origin.name} to ${destination.name} has ${points.length} points.',
          );

          // Get distance and duration (Optional, keep if needed, but ensure it doesn't block polyline creation)
          double distance = 0.0;
          double duration = 0.0;
          try {
            final distanceMatrixUrl = Uri.parse(
              'https://maps.googleapis.com/maps/api/distancematrix/json?'
              'origins=${origin.latitude},${origin.longitude}&'
              'destinations=${destination.latitude},${destination.longitude}&'
              'mode=driving&key=$apiKey',
            );
            final response = await http.get(distanceMatrixUrl);
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data['status'] == 'OK' &&
                  data['rows'][0]['elements'][0]['status'] == 'OK') {
                distance =
                    data['rows'][0]['elements'][0]['distance']['value']
                        .toDouble();
                duration =
                    data['rows'][0]['elements'][0]['duration']['value']
                        .toDouble();
              } else {
                debugPrint(
                  'Distance Matrix API Error: ${data['status']} / ${data['rows']?[0]?['elements']?[0]?['status']}',
                );
              }
            } else {
              debugPrint('Distance Matrix HTTP Error: ${response.statusCode}');
            }
          } catch (e) {
            debugPrint("Error fetching distance/duration: $e");
          }

          // Add the ROUTE DATA (RouteModel) to the temporary list
          routesForThisDay.add(
            RouteModel(
              id: '${origin.placeId}_${destination.placeId}',
              originPlaceId: origin.placeId,
              destinationPlaceId: destination.placeId,
              points: points, // Store the calculated LatLng points
              distance: distance,
              duration: duration,
            ),
          );

          debugPrint(
            'RouteModel added to temp list: ${origin.placeId}_${destination.placeId}',
          );
        } else {
          debugPrint(
            'No polyline points returned for route from ${origin.name} to ${destination.name}. Status: ${result.status}. Error: ${result.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint(
          'Error getting route between ${origin.name} and ${destination.name}: $e',
        );
      }
    }

    // Add the collected routes for this day to the main map
    if (routesForThisDay.isNotEmpty) {
      _dayRoutes[day.dayId] = routesForThisDay;
      debugPrint(
        'Stored ${routesForThisDay.length} RouteModels for day ${day.dayId} in controller.',
      );
    } else {
      debugPrint('No RouteModels generated for day ${day.dayId}');
      _dayRoutes[day.dayId] = []; // Ensure the key exists even if no routes
    }
    // DO NOT call notifyListeners here. Wait for all days to finish.
  }

  // Load sample itinerary data

  
}