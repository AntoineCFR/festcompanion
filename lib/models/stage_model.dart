class Stage {
  final String stage;
  final int? stageId;
  final int? stageOrder;
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

  /// Position de la scène sur l'illustration de la carte du festival (fraction
  /// 0-1 de la largeur/hauteur de l'image, indépendante de sa résolution).
  /// Null (ou (0,0), valeur par défaut à la création) tant qu'aucun admin n'a
  /// calibré la scène via l'écran dédié — la carte l'ignore alors simplement.
  final double? mapAnchorX;
  final double? mapAnchorY;

  /// Rayon (fraction de la largeur image) autour de l'ancre à ne pas
  /// recouvrir d'avatars — les pictogrammes de la carte varient en taille.
  final double? mapExclusionRadius;

  Stage({
    required this.stage,
    this.stageId,
    this.stageOrder,
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
    this.mapAnchorX,
    this.mapAnchorY,
    this.mapExclusionRadius,
  });

  /// True si l'ancre a été calibrée (ni absente, ni laissée à sa valeur par
  /// défaut (0, 0) posée à la création de la scène).
  bool get hasMapAnchor =>
      mapAnchorX != null &&
      mapAnchorY != null &&
      (mapAnchorX != 0.0 || mapAnchorY != 0.0);

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      stage: json['stage'] as String? ?? '',
      stageId: (json['stage_id'] as num?)?.toInt(),
      stageOrder: (json['stage_order'] as num?)?.toInt(),
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
      mapAnchorX: (json['map_anchor_x'] as num?)?.toDouble(),
      mapAnchorY: (json['map_anchor_y'] as num?)?.toDouble(),
      mapExclusionRadius: (json['map_exclusion_radius'] as num?)?.toDouble(),
    );
  }

  Stage copyWith({
    String? stage,
    int? stageId,
    int? stageOrder,
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
    double? mapAnchorX,
    double? mapAnchorY,
    double? mapExclusionRadius,
  }) {
    return Stage(
      stage: stage ?? this.stage,
      stageId: stageId ?? this.stageId,
      stageOrder: stageOrder ?? this.stageOrder,
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
      mapAnchorX: mapAnchorX ?? this.mapAnchorX,
      mapAnchorY: mapAnchorY ?? this.mapAnchorY,
      mapExclusionRadius: mapExclusionRadius ?? this.mapExclusionRadius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'stage_id': stageId,
      'stage_order': stageOrder,
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
      'map_anchor_x': mapAnchorX,
      'map_anchor_y': mapAnchorY,
      'map_exclusion_radius': mapExclusionRadius,
    };
  }
}
