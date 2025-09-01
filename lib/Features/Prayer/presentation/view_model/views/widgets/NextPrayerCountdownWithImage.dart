import 'dart:async';
import 'package:flutter/material.dart';

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
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    DateTime? nextPrayerTime;
    String nextPrayerName = '';

    for (var prayer in prayers) {
      final timeStr = widget.prayerTimes[prayer];
      if (timeStr != null) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        DateTime prayerTime = today.add(Duration(hours: hour, minutes: minute));

        // إذا الصلاة مضت اليوم، نضيف يوم
        if (prayerTime.isBefore(now)) {
          prayerTime = prayerTime.add(const Duration(days: 1));
        }

        if (nextPrayerTime == null || prayerTime.isBefore(nextPrayerTime)) {
          nextPrayerTime = prayerTime;
          nextPrayerName = prayer;
        }
      }
    }

    if (nextPrayerTime != null) {
      _nextPrayer = nextPrayerName;
      _remainingTime = nextPrayerTime.difference(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height / 2,
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
