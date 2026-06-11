class Stage {
  final String stage;
  final double latAvg;
  final double lonAvg;
  final double latAvd;  // Avant-droit
  final double lonAvd;
  final double latArg;  // Arrière-gauche
  final double lonArg;
  final double latArd;  // Arrière-droit
  final double lonArd;
  final double latRallyPoint;
  final double lonRallyPoint;

  Stage({
    required this.stage,
    required this.latAvg,
    required this.lonAvg,
    required this.latAvd,
    required this.lonAvd,
    required this.latArg,
    required this.lonArg,
    required this.latArd,
    required this.lonArd,
    required this.latRallyPoint,
    required this.lonRallyPoint,
  });

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      stage: json['stage'] as String? ?? '',
      latAvg: (json['lat_avg'] as num?)?.toDouble() ?? 0.0,
      lonAvg: (json['lon_avg'] as num?)?.toDouble() ?? 0.0,
      latAvd: (json['lat_avd'] as num?)?.toDouble() ?? 0.0,
      lonAvd: (json['lon_avd'] as num?)?.toDouble() ?? 0.0,
      latArg: (json['lat_arg'] as num?)?.toDouble() ?? 0.0,
      lonArg: (json['lon_arg'] as num?)?.toDouble() ?? 0.0,
      latArd: (json['lat_ard'] as num?)?.toDouble() ?? 0.0,
      lonArd: (json['lon_ard'] as num?)?.toDouble() ?? 0.0,
      latRallyPoint: (json['lat_rally_point'] as num?)?.toDouble() ?? 0.0,
      lonRallyPoint: (json['lon_rally_point'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Stage copyWith({
    String? stage,
    double? latAvg,
    double? lonAvg,
    double? latAvd,
    double? lonAvd,
    double? latArg,
    double? lonArg,
    double? latArd,
    double? lonArd,
    double? latRallyPoint,
    double? lonRallyPoint,
  }) {
    return Stage(
      stage: stage ?? this.stage,
      latAvg: latAvg ?? this.latAvg,
      lonAvg: lonAvg ?? this.lonAvg,
      latAvd: latAvd ?? this.latAvd,
      lonAvd: lonAvd ?? this.lonAvd,
      latArg: latArg ?? this.latArg,
      lonArg: lonArg ?? this.lonArg,
      latArd: latArd ?? this.latArd,
      lonArd: lonArd ?? this.lonArd,
      latRallyPoint: latRallyPoint ?? this.latRallyPoint,
      lonRallyPoint: lonRallyPoint ?? this.lonRallyPoint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'lat_avg': latAvg,
      'lon_avg': lonAvg,
      'lat_avd': latAvd,
      'lon_avd': lonAvd,
      'lat_arg': latArg,
      'lon_arg': lonArg,
      'lat_ard': latArd,
      'lon_ard': lonArd,
      'lat_rally_point': latRallyPoint,
      'lon_rally_point': lonRallyPoint,
    };
  }
}
