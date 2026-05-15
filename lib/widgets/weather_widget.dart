import 'package:flutter/material.dart';
import '../models/weather_model.dart';

class WeatherWidget extends StatelessWidget {
  final List<WeatherForecast> forecasts;

  const WeatherWidget({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
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
            height: 140, // Hauteur fixe pour le widget
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: forecasts.length,
              itemBuilder: (context, index) {
                final forecast = forecasts[index];
                return _buildWeatherCard(forecast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherForecast forecast) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            forecast.dayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Image.network(
            forecast.iconUrl,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image,
              color: Colors.white54,
              size: 40,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                width: 40,
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            forecast.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}