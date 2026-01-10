import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/weather_repository.dart';

class WeatherWidget extends ConsumerStatefulWidget {
  const WeatherWidget({super.key});

  @override
  ConsumerState<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends ConsumerState<WeatherWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 minutes (1800 seconds)
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) {
      ref.invalidate(weatherProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Helper to get Icon URL
  String getIconUrl(String code) =>
      'https://openweathermap.org/img/wn/$code@2x.png';

  void _showAlertModal(BuildContext context, WeatherAlert alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.event,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (alert.source != null) ...[
                Text(
                  'Fonte: ${alert.source}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Validade: ${DateFormat('dd/MM/yyyy HH:mm', 'pt-BR').format(alert.start)} - ${DateFormat('dd/MM/yyyy HH:mm', 'pt-BR').format(alert.end)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                alert.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Weather Error: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (weather) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 0. Weather Alerts (if any)
              if (weather.alerts.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: weather.alerts.map((alert) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAlertModal(context, alert),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                border: Border.all(
                                  color: Colors.orange[700]!,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    alert.event,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // 1. Current Weather (Big Header)
              Row(
                children: [
                  Image.network(
                    getIconUrl(weather.iconCode),
                    width: 64,
                    height: 64,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.currentTemp.round()}°',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      Text(
                        weather.currentCondition,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _WeatherStatCard(
                          label: 'Sensação',
                          value: '${weather.feelsLike.round()}°',
                          context: context,
                        ),
                        _WeatherStatCard(
                          label: 'Nascer do sol',
                          value: weather.sunrise,
                          context: context,
                        ),
                        _WeatherStatCard(
                          label: 'Pôr do sol',
                          value: weather.sunset,
                          context: context,
                        ),
                        _UVIndexStatCard(uvi: weather.uvi, context: context),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 30, color: Colors.black12),

              // 2. Daily Forecast Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weather.daily.skip(1).take(6).map((day) {
                  // skip(1) to avoid showing "Today" again in the small list
                  return Column(
                    children: [
                      Text(
                        DateFormat(
                          'E',
                          'pt-BR',
                        ).format(day.date), // SEG, TER...
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Image.network(
                        getIconUrl(day.iconCode),
                        width: 40,
                        height: 40,
                      ),
                      Text(
                        '${day.maxTemp.round()}°',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${day.minTemp.round()}°',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Private widget for displaying a single weather stat (label + value).
class _WeatherStatCard extends StatelessWidget {
  const _WeatherStatCard({
    required this.label,
    required this.value,
    required this.context,
  });

  final String label;
  final String value;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Private widget for displaying UV Index with color-coded risk level.
class _UVIndexStatCard extends StatelessWidget {
  const _UVIndexStatCard({required this.uvi, required this.context});

  final double uvi;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final uvLevel = UVIndexLevel.getLevel(uvi);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Índice UV: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: uvLevel.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              uvLevel.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
