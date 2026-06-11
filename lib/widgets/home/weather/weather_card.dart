import '../../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../models/weather_model.dart';
import '../../../utils/utils.dart';

class WeatherCard extends StatelessWidget {
  final WeatherForecast forecast;

  const WeatherCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceAlt),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppUtils.getDayName(forecast.festivalDay),
                style: TextStyle(
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
}