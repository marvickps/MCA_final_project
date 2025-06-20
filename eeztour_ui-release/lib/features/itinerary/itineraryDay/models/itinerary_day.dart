String formatDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  final parts = <String>[];
  if (hours > 0) parts.add('${hours}h');
  if (minutes > 0) parts.add('${minutes}m');
  if (seconds > 0 || parts.isEmpty) parts.add('${seconds}s');

  return parts.join(' ');
}
String formatDuration_without_seconds(int totalSeconds) {
  final totalMinutes = totalSeconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  } else if (hours > 0) {
    return '${hours}h';
  } else {
    return '${minutes}m';
  }
}


class ItineraryDay {
    final int itineraryId;
    final String date;
    final String dayTitle;
    final String departureTime;
    final double dayCost;
    final double dayDistanceKm;
    final String estimatedTotalDuration;
    final String totalStayDuration;

    List<itineraryStop> stops;

    ItineraryDay({
      required this.itineraryId,
      required this.date,
      required this.dayTitle,
      required this.departureTime,
      required this.dayCost,
      required this.dayDistanceKm,
      required this.estimatedTotalDuration,
      required this.stops, required this.totalStayDuration,
    });

    factory ItineraryDay.fromJson(Map<String, dynamic> json) {
      final durationRaw = json['estimated_total_duration'];
      final tripDuration = json['total_stay_duration'];

      return ItineraryDay(
        itineraryId: json['itinerary_id'] as int,
        date: json['date'] ?? '',
        dayTitle: json['day_title'] ?? '',
        departureTime: json['departure_time'] ?? '',
        dayCost: (json['day_cost'] as num).toDouble(),
        dayDistanceKm: (json['day_distance_km'] as num).toDouble()  / 1000,
        estimatedTotalDuration: durationRaw != null
            ? formatDuration_without_seconds((durationRaw as num).toInt())
            : '0m',
        totalStayDuration: tripDuration != null
      ? formatDuration_without_seconds((tripDuration as num).toInt())
          : '0m',
        stops: (json['stops'] as List)
            .map((stop) => itineraryStop.fromJson(stop))
            .toList(),
      );
    }




    ItineraryDay? fromJson(Map<String, dynamic> mockData) {}

  }
  class itineraryStop {
    final int stopId;
    int order;
    final String name;
    final String address;
    final String type;
    final String eta;
    final int stayDuration;
    final String? fromPreviousDuration;
    final double? distanceFromPreviousKm; // in KM
    final int? cost;
    final double lat;
    final double lng;
    final String desc;

    itineraryStop({
      required this.stopId,
      required this.order,
      required this.name,
      required this.address,
      required this.type,
      required this.eta,
      required this.stayDuration,
      this.fromPreviousDuration,
      this.distanceFromPreviousKm,
      this.cost,
      required this.lat,
      required this.lng,
      required this.desc,
    });

    factory itineraryStop.fromJson(Map<String, dynamic> json) {
      final durationStops = json['from_previous_duration'];
      return itineraryStop(
        stopId: json['stop_id'],
        order: json['order'],
        name: json['name'],
        address: json['address'],
        type: json['type'],
        eta: json['eta'],
        stayDuration: json['stay_duration'],
        fromPreviousDuration: durationStops != null
            ? formatDuration((durationStops as num).toInt())
            : '0m',
        distanceFromPreviousKm: json['distance_from_previous_stop'] != null
            ? (json['distance_from_previous_stop'] as num).toDouble() / 1000.0
            : null,

        cost: json['cost'] != null ? (json['cost'] as num).toInt() : 0,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        desc: json['description'] != null ? (json['description']) : "",
      );
    }
  }
