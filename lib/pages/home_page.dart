import 'package:flutter/material.dart';
import 'dart:async';
import '../models/timetable_item.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../widgets/home/countdown_timer.dart';
import '../widgets/home/event_header.dart';
import '../widgets/home/first_set_info.dart';
import '../widgets/home/location_button.dart';
import '../widgets/home/weather/weather_section.dart';
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
    try {
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
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Aucun set trouvé',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final difference = HomeHelper.calculateTimeDifference(_firstSetItem!.startTime);

    return Container(
      color: Colors.grey[900],
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
            else if (_hasWeatherError || _forecasts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Météo non disponible',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
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