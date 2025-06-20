import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final String id;
  final String originPlaceId;
  final String destinationPlaceId;
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds
  
  RouteModel({
    required this.id,
    required this.originPlaceId,
    required this.destinationPlaceId,
    required this.points,
    required this.distance,
    required this.duration,
  });
  
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      originPlaceId: json['originPlaceId'],
      destinationPlaceId: json['destinationPlaceId'],
      points: (json['points'] as List)
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList(),
      distance: json['distance'],
      duration: json['duration'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originPlaceId': originPlaceId,
      'destinationPlaceId': destinationPlaceId,
      'points': points
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'distance': distance,
      'duration': duration,
    };
  }
}