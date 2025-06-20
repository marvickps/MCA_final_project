import 'package:flutter/material.dart';

class PlaceModel {
  final String placeId;
  final String order;
  final String placeType;
  final double latitude;
  final double longitude;
  final String name;
  final String address;

  PlaceModel({
    required this.placeId,
    required this.order,
    required this.placeType,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.address,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['placeID'] ?? '',
      order: json['order'] ?? '0',
      placeType: json['placeType'] ?? 'place',
      latitude: double.tryParse(json['lat'] ?? '0') ?? 0,
      longitude: double.tryParse(json['lng'] ?? '0') ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
    );
  }

}

class DayItineraryModel {
  final String dayId;
  final String date;
  final Map<String, PlaceModel> places;
  final Color routeColor;

  DayItineraryModel({
    required this.dayId,
    required this.date,
    required this.places,
    required this.routeColor,
  });

  factory DayItineraryModel.fromJson(
    Map<String, dynamic> json, {
    required Color color,
  }) {
    Map<String, PlaceModel> placesMap = {};

    if (json.containsKey('place') && json['place'] is Map) {
      final Map<String, dynamic> placesJson = json['place'];
      placesJson.forEach((key, value) {
        placesMap[key] = PlaceModel.fromJson(value);
      });
    }

    return DayItineraryModel(
      dayId: json['day_id'] ?? '',
      date: json['date'] ?? '',
      places: placesMap,
      routeColor: color,
    );
  }

  List<PlaceModel> get sortedPlaces {
    List<PlaceModel> placesList = places.values.toList();
    placesList.sort((a, b) => int.parse(a.order).compareTo(int.parse(b.order)));
    return placesList;
  }
}
