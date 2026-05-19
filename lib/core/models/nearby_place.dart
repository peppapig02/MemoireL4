class NearbyPlace {
  final String? id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double? distance;
  final String? address;
  final double? rating;
  final String? source;

  const NearbyPlace({
    this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.address,
    this.rating,
    this.source,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      id: json['id'] as String?,
      name: (json['name'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      distance: _toDouble(json['distance']),
      address: json['address'] as String?,
      rating: _toDouble(json['rating']),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'address': address,
      'rating': rating,
      'source': source,
    };
  }

  NearbyPlace copyWith({
    String? id,
    String? name,
    String? category,
    double? latitude,
    double? longitude,
    double? distance,
    String? address,
    double? rating,
    String? source,
  }) {
    return NearbyPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      source: source ?? this.source,
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
