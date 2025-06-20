class ItineraryModel {
  final int itineraryId;
  final String itineraryName;
  final String startDate;
  final String endDate;

  ItineraryModel({
    required this.itineraryId,
    required this.itineraryName,
    required this.startDate,
    required this.endDate,
  });
  factory ItineraryModel.fromJson(Map<String, dynamic> json) {
    return ItineraryModel(
      itineraryId: json['itinerary_id'],
      itineraryName: json['itinerary_name'],
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }
}

class MenuItemModel {
  final String title;
  final String iconPath;
  final String route;

  MenuItemModel({
    required this.title,
    required this.iconPath,
    required this.route,
  });
}
