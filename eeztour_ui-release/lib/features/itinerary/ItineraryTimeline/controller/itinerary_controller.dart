// lib/itineraryTimeline/controllers/itinerary_controller.dart
import 'dart:convert';
import 'package:eeztour/common/config.dart';
import 'package:http/http.dart' as http;
import '../../../../common/functions.dart';
import '../models/timeline_model.dart';

class ItineraryController {
  late final String itineraryName;
  ItineraryController({this.itineraryName = ""}); 
  // Default value
  int totalCost = 0;
  int totalDistance = 0;
  int formatedCost = 0;
  String formatedDistance = "null";
  bool isLoading = true;
  String error = '';

  late ItineraryTimelineResponse _timelineData;

  // Fetch itinerary data from API

  Future<void> fetchItineraryData(int id) async {
    try {
      final url = Uri.parse('$baseUrl/itinerary/timeline/$id');
      final response = await http.get(url);
      
      // print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _timelineData = ItineraryTimelineResponse.fromJson(data);


        isLoading = false;
      } else {
        error = 'Failed to load itinerary data: ${response.statusCode}';
        isLoading = false;
      }
    } catch (e) {
      error = 'Error fetching itinerary data: $e';
      isLoading = false;
    }
  }

  Future<List<DayActivity>> getActivities() async {
    if (isLoading || error.isNotEmpty) {
      return [];
    }

    final List<DayActivity> activities = [];
    final sortedDays =
        _timelineData.days.entries.toList()..sort(
          (a, b) => int.parse(
            a.key.substring(3),
          ).compareTo(int.parse(b.key.substring(3))),
        );

    for (int i = 0; i < sortedDays.length; i++) {
      final entry = sortedDays[i];
      final dayData = entry.value;
      final int dayId = dayData.dayId;

      // Fetch real details for each day
      final url = Uri.parse('$baseUrl/itinerary/get_day_details/$dayId');
      final response = await http.get(url);

      // Default values in case the request fails
      int dayDistance = 0;
      int estimatedDuration = 0;
      int dayCost = 0;

      if (response.statusCode == 200) {
        final Map<String, dynamic> details = json.decode(response.body);
        dayDistance = (details['day_distance_km'] ?? 0).toDouble().toInt();
        estimatedDuration = toInt(details['estimated_total_duration']);
        dayCost = (details['day_cost'] ?? 0).toDouble().toInt();

      } else {
        print('Failed to fetch details for dayId: $dayId');
      }

      totalCost= totalCost + dayCost;
      totalDistance= totalDistance+ dayDistance;

      final DateTime dateTime = DateTime.parse(dayData.date);
      final String formattedDate = '${dateTime.day} ${_getMonthAbbreviation(dateTime.month)}';
      final String dayOfWeek = _getDayOfWeek(dateTime.weekday);

      final bool hasBus = i == 0 || i == sortedDays.length - 1;

      activities.add(
        DayActivity(
          address: dayData.address,
          dayId: dayId,
          date: formattedDate,
          dayOfWeek: dayOfWeek,
          travelTime: formatDuration(estimatedDuration), // 1587 => "26h 27m"
          distance: '${(dayDistance / 1000).toStringAsFixed(1)} km', // 9947 => "9.9 km"
          cost: '₹ $dayCost', // ₹ 0 or whatever actual cost
          hasHotel: dayData.type.contains('hotel'),
          hasBus: hasBus,
          hasRestaurant: dayData.type.contains('restaurant'),
          hasPlace: dayData.type.contains('place'),
        ),
      );
    }
    formatedDistance= '${(totalDistance / 1000).toStringAsFixed(1)} km';
    formatedCost=totalCost;
    totalCost=0;
    totalDistance=0;

    return activities;
  }

  String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }


  int toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }


  String _getDayOfWeek(int weekday) {
    const List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}

class DayActivity {
  final String address;
  final int dayId;
  final String date;
  final String dayOfWeek;
  final String travelTime;
  final String distance;
  final String cost;
  final bool hasHotel;
  final bool hasBus;
  final bool hasRestaurant;
  final bool hasPlace;

  DayActivity({
    required this.address,
    required this.dayId,
    required this.date,
    required this.dayOfWeek,
    required this.travelTime,
    required this.distance,
    required this.cost,
    required this.hasHotel,
    required this.hasBus,
    this.hasRestaurant = false,
    this.hasPlace = false,

  });
}
