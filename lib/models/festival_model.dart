class Festival {
  final int festivalId;
  final String slug;
  final String name;
  final String city;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final String timezone;
  final bool isActive;
  final String? parking; // requête Maps (adresse ou "lat,lon")

  Festival({
    required this.festivalId,
    required this.slug,
    required this.name,
    required this.city,
    required this.country,
    required this.startDate,
    required this.endDate,
    required this.timezone,
    this.isActive = true,
    this.parking,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      festivalId: json['festival_id'] as int,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      // Les dates arrivent au format ISO 'YYYY-MM-DD'.
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      isActive: json['is_active'] as bool? ?? true,
      parking: json['parking'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'festival_id': festivalId,
      'slug': slug,
      'name': name,
      'city': city,
      'country': country,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'timezone': timezone,
      'is_active': isActive,
      'parking': parking,
    };
  }
}
