class HotelSuggestion {
  final String placeId;
  final String name;
  final String address;
  final String rating;
  final String? priceLevel;

  HotelSuggestion({
    required this.placeId,
    required this.name,
    required this.address,
    required this.rating,
    this.priceLevel,
  });
}