// lib/itineraryTimeline/models/itinerary_timeline_model.dart
class ItineraryTimelineResponse {
  final int itineraryId;
  final Map<String, DayData> days;
  final String itineraryName;
  final String totalCost;
  final String totalDistance;

  ItineraryTimelineResponse({
    required this.itineraryId,
    required this.days,
    required this.itineraryName,
    required this.totalCost,
    required this.totalDistance,
  });

  factory ItineraryTimelineResponse.fromJson(Map<String, dynamic> json) {
    // Extract days data
    Map<String, DayData> daysMap = {};

    json.forEach((key, value) {
      if (key.startsWith('day')) {
        daysMap[key] = DayData.fromJson(value);
      }
    });

    return ItineraryTimelineResponse(
      itineraryId: json['itinerary_id'],
      days: daysMap,
      // You might want to fetch these from the API as well
      itineraryName: "Trip to Shillong", // Default or from API
      totalCost: "₹ 11800/-", // Default or from API
      totalDistance: "123 km", // Default or from API
    );
  }
}

class DayData {
  final String address;
  final String date;
  final int dayId;
  final List<String> type;

  DayData({required this.address, required this.date, required this.dayId, required this.type});

  factory DayData.fromJson(Map<String, dynamic> json) {
    return DayData(
      address: json['address'],
      date: json['date'],
      dayId: json['day_id'],
      type: List<String>.from(json['type']),
    );
  }
}
