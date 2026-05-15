import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _weatherUrl = 'https://extremalineup.onrender.com/weather';
  static const String _cacheKey = 'cached_weather';
  static const String _cacheTimestampKey = 'cached_weather_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  Future<List<WeatherForecast>?> getWeatherForecast() async {
    try {
      // 1. Essaye de récupérer depuis le serveur
      final response = await http.get(Uri.parse(_weatherUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final forecasts = data.map((json) => WeatherForecast.fromJson(json)).toList();
        await _cacheWeather(forecasts);
        return forecasts;
      } else {
        throw Exception('Échec serveur: ${response.statusCode}');
      }
    } catch (e) {
      final cached = await _getCachedWeather();
      if (cached != null) {
        return cached;
      } else {
        return null;
      }
    }
  }

  Future<void> _cacheWeather(List<WeatherForecast> forecasts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(forecasts.map((f) => f.toJson()).toList());
    await prefs.setString(_cacheKey, jsonString);
    await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  Future<List<WeatherForecast>?> _getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    final timestampString = prefs.getString(_cacheTimestampKey);

    if (jsonString == null || timestampString == null) {
      return null;
    }

    final timestamp = DateTime.parse(timestampString);
    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      return null;
    }

    final List<dynamic> data = json.decode(jsonString);
    return data.map((json) => WeatherForecast.fromJson(json)).toList();
  }
}