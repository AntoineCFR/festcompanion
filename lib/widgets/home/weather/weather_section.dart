import 'package:flutter/material.dart';
import '../../../models/weather_model.dart';
import 'weather_card.dart';

class WeatherSection extends StatelessWidget {
  final List<WeatherForecast> forecasts;

  const WeatherSection({
    super.key,
    required this.forecasts,
  });

  @override
  Widget build(BuildContext context) {
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
              children: forecasts.map((forecast) => WeatherCard(forecast: forecast)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}