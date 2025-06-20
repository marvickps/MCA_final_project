import '../models/itinerary_day.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eeztour/common/config.dart';

class itineraryDayController {
  ItineraryDay? itineraryDay;
  bool isLoading = true;

  Future<void> fetchitineraryDay(int dayId) async {
    final url = Uri.parse('$baseUrl/itinerary/get_day_details/$dayId');

    isLoading = true;
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        itineraryDay = ItineraryDay.fromJson(data);
      } else {
        throw Exception('Failed to load itinerary day. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching itinerary day: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateitineraryStopsOrder(int dayId) async {
    if (itineraryDay == null) return false;

    try {
      final Map<String, dynamic> payload = {
        "itinerary_day_id": dayId,
        "stops": itineraryDay!.stops.map((stop) => {
          "stop_id": stop.stopId,
          "order": stop.order,
        }).toList(),
      };

      final jsonString = jsonEncode(payload);

      final response = await http.put(
        Uri.parse('$baseUrl/itinerary/reorder_itinerary_items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonString,
      );

      if (response.statusCode == 200) {
        print('Successfully updated stops order on backend!');
        return true;
      } else {
        print('Failed to update stops order. Status code: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('Error updating itinerary stops order: $e');
      return false;
    }
  }
}