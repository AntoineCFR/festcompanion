class WeatherForecast {
  final String date;
  final String dayName;
  final double temperature;
  final String description;
  final String iconUrl;
  final int humidity;
  final double windSpeed;
  final String festivalDay;

  WeatherForecast({
    required this.date,
    required this.dayName,
    required this.temperature,
    required this.description,
    required this.iconUrl,
    required this.humidity,
    required this.windSpeed,
    required this.festivalDay,
  });

  // Conversion depuis JSON (pour l'API)
  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      iconUrl: json['icon'] ?? '',
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      festivalDay: json['festival_day'] ?? '',
    );
  }

  // Conversion vers JSON (pour le cache local)
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_name': dayName,
      'temperature': temperature,
      'description': description,
      'icon': iconUrl,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'festival_day': festivalDay,
    };
  }
}