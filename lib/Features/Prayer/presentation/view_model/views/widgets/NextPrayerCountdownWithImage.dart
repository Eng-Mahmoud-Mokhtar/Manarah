import 'dart:async';
import 'package:flutter/material.dart';
import '../PrayerTimes.dart';

class NextPrayerCountdownWithImage extends StatefulWidget {
  final Map<String, String> prayerTimes;
  final double fontBig;
  final double fontNormal;
  final double height;

  const NextPrayerCountdownWithImage({
    super.key,
    required this.prayerTimes,
    required this.fontBig,
    required this.fontNormal,
    required this.height,
  });

  @override
  State<NextPrayerCountdownWithImage> createState() =>
      _NextPrayerCountdownWithImageState();
}

class _NextPrayerCountdownWithImageState
    extends State<NextPrayerCountdownWithImage> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  String _nextPrayer = '';
  final Map<String, String> arabicNames = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  @override
  void initState() {
    super.initState();
    _calculateNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _calculateNextPrayer();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateNextPrayer() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<DateTime> prayerDateTimes = [];
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    for (var prayer in prayers) {
      final timeStr = widget.prayerTimes[prayer];
      if (timeStr != null) {
        try {
          final cleanedTime = formatTime(timeStr);
          final parts = cleanedTime.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          prayerDateTimes.add(
            today.add(Duration(hours: hour, minutes: minute)),
          );
        } catch (e) {
          print('Error parsing time for $prayer: $e');
        }
      }
    }

    if (prayerDateTimes.isEmpty) {
      _nextPrayer = '';
      _remainingTime = Duration.zero;
      return;
    }

    prayerDateTimes.sort();
    DateTime next = prayerDateTimes.firstWhere(
          (dt) => dt.isAfter(now),
      orElse: () {
        final fajrTimeStr = widget.prayerTimes['Fajr'] ?? '05:00';
        final cleanedTime = formatTime(fajrTimeStr);
        final parts = cleanedTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return today.add(Duration(days: 1, hours: hour, minutes: minute));
      },
    );

    _remainingTime = next.difference(now);

    String nextPrayerKey;
    if (next.day == today.day) {
      int index = prayerDateTimes.indexWhere((dt) => dt.isAtSameMomentAs(next));
      nextPrayerKey = prayers[index];
    } else {
      nextPrayerKey = 'Fajr';
    }
    _nextPrayer = nextPrayerKey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("Assets/Frame 64.png", fit: BoxFit.fill),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.height * 0.08,
              vertical: widget.height * 0.08,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الوقت المتبقي لصلاة ${_nextPrayer.isNotEmpty ? arabicNames[_nextPrayer] : ''}',
                  style: TextStyle(
                    fontSize: widget.fontBig,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: widget.height * 0.08),
                Text(
                  '${_remainingTime.inHours.toString().padLeft(2, '0')}:${(_remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: widget.fontBig,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
String formatTime(String time) {
  final cleanedTime = time.split(' ')[0];
  return cleanedTime;
}