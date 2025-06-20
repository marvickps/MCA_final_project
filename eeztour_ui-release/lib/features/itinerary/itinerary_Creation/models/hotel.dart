class Hotel {
  final String placeId;
  final String name;
  final String address;
  final double? rating;
  final String? photoReference;

  Hotel({
    required this.placeId,
    required this.name,
    required this.address,
    this.rating,
    this.photoReference,
  });
  
 factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      placeId: json['place_id'],
      name: json['name'],
      address: json['vicinity'] ?? '',
      rating: json['rating']?.toDouble(),
      photoReference: json['photos'] != null && json['photos'].isNotEmpty 
          ? json['photos'][0]['photo_reference'] 
          : null,
    );
  }
}