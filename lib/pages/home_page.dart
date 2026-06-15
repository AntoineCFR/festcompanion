import 'package:flutter/material.dart';
import 'dart:async';
import '../models/timetable_item.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/app_data_manager.dart';
import '../utils/utils.dart';
import '../widgets/home/countdown_timer.dart';
import '../widgets/home/event_header.dart';
import '../widgets/home/first_set_info.dart';
import '../widgets/home/location_button.dart';
import '../widgets/home/weather/weather_section.dart';
import '../widgets/shared/festival_background.dart';
import '../helpers/home_helper.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int userId;

  const HomePage({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimetableItem? _firstSetItem;
  Timer? _timer;
  List<WeatherForecast> _forecasts = [];
  bool _isLoadingWeather = true;
  bool _hasWeatherError = false;
  // Non-null quand on est AVANT la fenêtre de prévision (14 j) : on n'interroge
  // pas le serveur et on indique la date d'ouverture des prévisions.
  DateTime? _weatherAvailableFrom;

  @override
  void initState() {
    super.initState();
    _firstSetItem = HomeHelper.getFirstSetItem();
    _loadWeather();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    // Gate de disponibilité : WeatherAPI ne fournit les prévisions que dans les
    // 14 jours qui précèdent. Hors fenêtre → on N'INTERROGE PAS le serveur.
    final festival = AppDataManager().selectedFestival;
    final now = DateTime.now();
    if (festival != null) {
      final from = WeatherService.availabilityDate(festival);
      if (now.isBefore(from)) {
        if (mounted) {
          setState(() {
            _isLoadingWeather = false;
            _weatherAvailableFrom = from;
          });
        }
        return;
      }
      if (!WeatherService.isAvailable(festival, now)) {
        // Après le festival : météo inutile, pas de requête (section masquée).
        if (mounted) setState(() => _isLoadingWeather = false);
        return;
      }
    }

    try {
      // getWeatherForecast réutilise le cache tant qu'aucun nouveau créneau CRON
      // (6/10/14/18/22h) n'est passé → pas de requête superflue entre créneaux.
      final forecasts = await WeatherService().getWeatherForecast();
      if (mounted) {
        setState(() {
          if (forecasts != null) {
            _forecasts = forecasts;
            _hasWeatherError = false;
          } else {
            _hasWeatherError = true;
          }
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _hasWeatherError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firstSetItem == null) {
      return const FestivalBackground(
        imageKey: 'home',
        child: Center(
          child: Text(
            'Aucun set trouvé',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final difference = HomeHelper.calculateTimeDifference(_firstSetItem!.startTime);

    return FestivalBackground(
      imageKey: 'home',
      refreshDomains: const [LoadDomain.timetable],
      refreshLabel: 'Mise à jour du programme…',
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EventHeader(),
            CountdownTimer(difference: difference),
            const SizedBox(height: 30),
            FirstSetInfo(firstSetTime: _firstSetItem!.startTime),
            if (_isLoadingWeather)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CircularProgressIndicator(),
              )
            else if (_weatherAvailableFrom != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_queue,
                        color: Colors.white54, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Météo bientôt disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Les prévisions s\'ouvrent le ${AppUtils.formatFullDate(_weatherAvailableFrom!)}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (_hasWeatherError || _forecasts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Météo non disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            else
              WeatherSection(forecasts: _forecasts),
            const LocationButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}