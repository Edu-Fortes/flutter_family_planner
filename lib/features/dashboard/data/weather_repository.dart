import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

// UV Index Risk Levels
class UVIndexLevel {
  final double minValue;
  final double maxValue;
  final String label;
  final Color color;

  const UVIndexLevel({
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.color,
  });

  static const levels = <UVIndexLevel>[
    UVIndexLevel(
      minValue: 0,
      maxValue: 2.9,
      label: 'Baixo',
      color: Color(0xFF4CAF50), // Green
    ),
    UVIndexLevel(
      minValue: 3,
      maxValue: 5.9,
      label: 'Moderado',
      color: Color(0xFFFFC107), // Yellow
    ),
    UVIndexLevel(
      minValue: 6,
      maxValue: 7.9,
      label: 'Alto',
      color: Color(0xFFFF9800), // Orange
    ),
    UVIndexLevel(
      minValue: 8,
      maxValue: 10.9,
      label: 'Muito alto',
      color: Color(0xFFF44336), // Red
    ),
  ];

  static UVIndexLevel getLevel(double uvi) {
    for (final level in levels) {
      if (uvi >= level.minValue && uvi <= level.maxValue) {
        return level;
      }
    }
    // If UVI is 11+, return the highest level
    return levels.last;
  }
}

class WeatherData {
  final double currentTemp;
  final double feelsLike;
  final String currentCondition; // e.g., "Clouds"
  final String iconCode; // e.g., "04d"
  final String sunrise;
  final String sunset;
  final double uvi;
  final List<DailyForecast> daily;
  final List<WeatherAlert> alerts;

  WeatherData({
    required this.currentTemp,
    required this.feelsLike,
    required this.currentCondition,
    required this.iconCode,
    required this.daily,
    required this.sunrise,
    required this.sunset,
    required this.uvi,
    required this.alerts,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final dailyList = (json['daily'] as List)
        .take(7)
        .map((x) => DailyForecast.fromJson(x))
        .toList();
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      current['sunrise'] * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      current['sunset'] * 1000,
    );

    return WeatherData(
      currentTemp: (current['temp'] as num).toDouble(),
      feelsLike: (current['feels_like'] as num).toDouble(),
      currentCondition: current['weather'][0]['description'],
      iconCode: current['weather'][0]['icon'],
      daily: dailyList,
      sunrise: DateFormat('HH:mm').format(sunrise),
      sunset: DateFormat('HH:mm').format(sunset),
      uvi: (current['uvi'] as num).toDouble(),
      alerts: json['alerts'] != null
          ? (json['alerts'] as List)
                .map((x) => WeatherAlert.fromJson(x))
                .toList()
          : <WeatherAlert>[],
    );
  }
}

class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final String iconCode;

  DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.iconCode,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      minTemp: (json['temp']['min'] as num).toDouble(),
      maxTemp: (json['temp']['max'] as num).toDouble(),
      iconCode: json['weather'][0]['icon'],
    );
  }
}

class WeatherAlert {
  final String event;
  final String description;
  final DateTime start;
  final DateTime end;
  final String? source;

  WeatherAlert({
    required this.event,
    required this.description,
    required this.start,
    required this.end,
    this.source,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      event: json['event'] ?? 'Weather Alert',
      description: json['description'] ?? '',
      start: DateTime.fromMillisecondsSinceEpoch(json['start'] * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(json['end'] * 1000),
      source: json['tags']?[0] as String?,
    );
  }
}

// 2. The Repository
class WeatherRepository {
  Future<WeatherData> fetchWeather() async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    final lat = dotenv.env['LATITUDE'];
    final lon = dotenv.env['LONGITUDE'];
    final lang = dotenv.env['LANGUAGE'];

    if (apiKey == null || lat == null || lon == null) {
      throw Exception("Missing Weather Config in .env");
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&lang=$lang&exclude=minutely,hourly&units=metric&appid=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather: ${response.body}');
    }
  }
}

// 3. The Provider
final weatherProvider = FutureProvider<WeatherData>((ref) async {
  return WeatherRepository().fetchWeather();
});
