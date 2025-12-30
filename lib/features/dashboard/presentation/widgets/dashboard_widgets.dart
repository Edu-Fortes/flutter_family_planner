import 'dart:async';
// import 'dart:math';
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
    ).format(_now); // Monday, Dec 21

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

class QuoteWidget extends StatelessWidget {
  const QuoteWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, you might fetch these from an API or Supabase
    final quotes = [
      '"Family is not an important thing. It\'s everything." – Michael J. Fox',
      '"The memories we make with our family is everything."',
      '"In family life, love is the oil that eases friction, the cement that binds closer together, and the music that brings harmony." – Friedrich Nietzsche',
      '"Ohana means family. Family means nobody gets left behind or forgotten."',
    ];
    final randomQuote = quotes[DateTime.now().day % quotes.length];

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        randomQuote,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
      ),
    );
  }
}
