// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // ✅ NOUVELLE MÉTHODE : Gère l'ouverture du lien Google Maps
  Future<void> _openLocation() async {
    if (!mounted) return;

    final url = Uri.parse('https://www.google.com/maps?q=51.026997,5.443735');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le lien vers Google Maps.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ouverture du lien.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
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

    final firstSetTimeLocal = _firstSetItem!.startTime;
    final difference = firstSetTimeLocal.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Container(
      color: Colors.grey[900],
      child: SingleChildScrollView(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${AppUtils.formatFullDate(firstSetTimeLocal)} - ${AppUtils.formatTime(firstSetTimeLocal)}',
                style: const TextStyle(fontSize: 16, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
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
            // ✅ NOUVEAU : Icône de localisation sous la météo
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.location_on, color: Colors.white, size: 30),
                    onPressed: _openLocation, // ✅ Appel de la méthode dédiée
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Parking Camping',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _forecasts.map((forecast) => _buildWeatherCard(forecast)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard(WeatherForecast forecast) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
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
          Positioned(
            top: 35,
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
          Positioned(
            top: 77,
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
          Positioned(
            top: 103,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  forecast.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
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