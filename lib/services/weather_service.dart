import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../models/festival_model.dart';
import 'api_service.dart';

class WeatherService {
  static const String _weatherBaseUrl = 'https://extremalineup.onrender.com/weather';

  /// Fenêtre de prévision de WeatherAPI : les prévisions ne sont disponibles
  /// que dans les [forecastWindowDays] jours qui précèdent une date.
  /// WeatherAPI compte aujourd'hui comme jour 1 → jour 14 = aujourd'hui + 13 j.
  /// Pour que le 1er jour du festival soit couvert, on soustrait 13 jours.
  static const int forecastWindowDays = 13;

  /// Heures (locales) auxquelles le CRON serveur rafraîchit la météo. Entre deux
  /// créneaux, les données du serveur ne changent pas → inutile de re-requêter.
  static const List<int> cronHours = [6, 10, 14, 18, 22];

  // Caches namespacés par festival (données ET horodatage) pour éviter tout
  // mélange entre festivals.
  String get _cacheKey => 'cached_weather_${ApiService.currentFestivalId ?? 0}';
  String get _cacheTsKey => 'cached_weather_ts_${ApiService.currentFestivalId ?? 0}';

  /// Date d'ouverture des prévisions pour un festival (= début − [forecastWindowDays] jours).
  static DateTime availabilityDate(Festival f) =>
      DateTime(f.startDate.year, f.startDate.month, f.startDate.day)
          .subtract(const Duration(days: forecastWindowDays));

  /// La météo est-elle interrogeable à [now] ? = dans la fenêtre de prévision
  /// (à partir de [availabilityDate]) et pas au-delà de la fin du festival.
  static bool isAvailable(Festival f, DateTime now) {
    final until = DateTime(f.endDate.year, f.endDate.month, f.endDate.day)
        .add(const Duration(days: 1));
    return !now.isBefore(availabilityDate(f)) && now.isBefore(until);
  }

  /// Dernier créneau CRON (6/10/14/18/22h) atteint à [now]. Avant 6h, c'est 22h
  /// la veille.
  static DateTime latestCronSlot(DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day);
    DateTime? slot;
    for (final h in cronHours) {
      final b = midnight.add(Duration(hours: h));
      if (!b.isAfter(now)) slot = b;
    }
    return slot ??
        midnight.subtract(const Duration(days: 1)).add(const Duration(hours: 22));
  }

  /// Récupère les prévisions. Par défaut, **n'interroge pas le serveur** si le
  /// cache a déjà été rempli après le dernier créneau CRON (données fraîches) ;
  /// passer [force] pour ignorer ce cache. En cas d'échec réseau, retombe sur le
  /// dernier cache disponible (même périmé).
  Future<List<WeatherForecast>?> getWeatherForecast({bool force = false}) async {
    final festivalId = ApiService.currentFestivalId;
    if (festivalId == null) return null;

    if (!force) {
      final fresh = await _getCachedWeatherIfFresh();
      if (fresh != null) return fresh;
    }

    try {
      final url = Uri.parse('$_weatherBaseUrl?festival_id=$festivalId');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final forecasts =
            data.map((json) => WeatherForecast.fromJson(json)).toList();
        await _cacheWeather(forecasts);
        return forecasts;
      } else {
        throw Exception('Échec serveur: ${response.statusCode}');
      }
    } catch (e) {
      // Repli : on rend le dernier cache connu (même périmé) plutôt que rien.
      return _getCachedWeather();
    }
  }

  Future<void> _cacheWeather(List<WeatherForecast> forecasts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(forecasts.map((f) => f.toJson()).toList());
    await prefs.setString(_cacheKey, jsonString);
    await prefs.setString(_cacheTsKey, DateTime.now().toIso8601String());
  }

  /// Cache encore frais = rempli APRÈS le dernier créneau CRON → on évite la
  /// requête réseau jusqu'au prochain créneau.
  Future<List<WeatherForecast>?> _getCachedWeatherIfFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_cacheTsKey);
    if (ts == null) return null;
    final fetchedAt = DateTime.parse(ts);
    if (fetchedAt.isBefore(latestCronSlot(DateTime.now()))) return null; // périmé
    return _getCachedWeather();
  }

  /// Dernier cache connu, sans condition de fraîcheur (repli hors-ligne).
  Future<List<WeatherForecast>?> _getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    if (jsonString == null) return null;
    final List<dynamic> data = json.decode(jsonString);
    return data.map((json) => WeatherForecast.fromJson(json)).toList();
  }
}
