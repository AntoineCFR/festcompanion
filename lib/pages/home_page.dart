import 'package:flutter/material.dart';
import 'dart:async';
import '../models/timetable_item.dart';
import '../models/weather_model.dart';
import '../services/app_data_manager.dart';
import '../services/weather_service.dart';
import '../utils/utils.dart';

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
    _updateFirstSetItem();
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

  void _updateFirstSetItem() {
    final timetable = AppDataManager().timetable;
    if (timetable.isNotEmpty) {
      _firstSetItem = timetable.reduce((a, b) =>
        a.startTime.isBefore(b.startTime) ? a : b);
    } else {
      _firstSetItem = null;
    }
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
    final now = DateTime.now();
    if (_firstSetItem == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: const Text('Accueil'),
        ),
        body: const Center(
          child: Text(
            'Aucun set trouvé',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final firstSetTimeLocal = _firstSetItem!.startTime;
    final difference = firstSetTimeLocal.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Text(
                'Extrema Outdoor 2026',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeUnit('Jours', days),
                  const Text(
                    ' : ',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  _buildTimeUnit('Heures', hours),
                  const Text(
                    ' : ',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  _buildTimeUnit('Minutes', minutes),
                  const Text(
                    ' : ',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  _buildTimeUnit('Secondes', seconds),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Premier set',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '${AppUtils.formatFullDate(firstSetTimeLocal)} - ${AppUtils.formatTime(firstSetTimeLocal)}',
                style: const TextStyle(fontSize: 16, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
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
                _buildWeatherSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Météo à Houthalen-Helchteren',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _forecasts.length,
            itemBuilder: (context, index) {
              final forecast = _forecasts[index];
              return _buildWeatherCard(forecast);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(WeatherForecast forecast) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          // 1. Jour (aligné en haut, centré horizontalement)
          Positioned(
            top: 8, // Aligné sur le haut (après padding)
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppUtils.getDayName(forecast.dayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 2. Icône (centrée verticalement et horizontalement)
          Positioned(
            top: 35, // (hauteur tuile - hauteur icône)/2 - hauteur température/2
            left: 0,
            right: 0,
            child: Image.network(
              forecast.iconUrl,
              width: 36,
              height: 36,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image,
                color: Colors.white54,
                size: 36,
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                );
              },
            ),
          ),

          // 3. Température (bas aligné sur le haut de l'icône)
          Positioned(
            top: 77, // (hauteur tuile - hauteur icône)/2 - hauteur température/2
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${forecast.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 4. Texte (haut aligné sur le bas de l'icône)
          Positioned(
            top: 103, // Aligné sur le bas de l'icône
            left: 0,
            right: 0,
            child: Center( // ✅ Centre verticalement ET horizontalement dans la box
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  forecast.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center, // ✅ Centre horizontalement le texte lui-même
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}