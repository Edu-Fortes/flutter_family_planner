import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BigClockWidget extends StatefulWidget {
  const BigClockWidget({super.key});

  @override
  State<BigClockWidget> createState() => _BigClockWidgetState();
}

class _BigClockWidgetState extends State<BigClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(_now); // e.g., 19:41
    // final amPm = DateFormat('a').format(_now); // AM/PM
    final dateStr = DateFormat(
      'EEEE, d \'de\' MMMM \'de\' yyyy',
      'pt_BR',
    ).format(_now); // Domingo, 21 de Dezembro de 2025

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.w200,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
        ),
      ],
    );
  }
}
