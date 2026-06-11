import 'package:flutter/material.dart';
import '../../../models/weather_model.dart';
import '../../../services/app_data_manager.dart';
import 'weather_card.dart';

class WeatherSection extends StatelessWidget {
  final List<WeatherForecast> forecasts;

  const WeatherSection({
    super.key,
    required this.forecasts,
  });

  @override
  Widget build(BuildContext context) {
    final city = AppDataManager().selectedFestival?.city;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            city != null ? 'Météo à $city' : 'Météo',
            style: const TextStyle(
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
              children: forecasts.map((forecast) => WeatherCard(forecast: forecast)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}