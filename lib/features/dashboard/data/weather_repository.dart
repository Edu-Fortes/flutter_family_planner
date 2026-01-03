import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 1. The Models
class WeatherData {
  final double currentTemp;
  final String currentCondition; // e.g., "Clouds"
  final String iconCode; // e.g., "04d"
  final List<DailyForecast> daily;

  WeatherData({
    required this.currentTemp,
    required this.currentCondition,
    required this.iconCode,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final dailyList = (json['daily'] as List)
        .take(6)
        .map((x) => DailyForecast.fromJson(x))
        .toList();

    return WeatherData(
      currentTemp: (current['temp'] as num).toDouble(),
      currentCondition: current['weather'][0]['main'],
      iconCode: current['weather'][0]['icon'],
      daily: dailyList,
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

// 2. The Repository
class WeatherRepository {
  Future<WeatherData> fetchWeather() async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    final lat = dotenv.env['LATITUDE'];
    final lon = dotenv.env['LONGITUDE'];

    if (apiKey == null || lat == null || lon == null) {
      throw Exception("Missing Weather Config in .env");
    }

    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,alerts&units=metric&appid=$apiKey',
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
