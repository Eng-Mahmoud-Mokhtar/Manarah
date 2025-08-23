import 'package:flutter/material.dart';
import '../../../../../../Core/Const/Colors.dart';
import '../../prayer_state.dart';
import 'NextPrayerCountdownWithImage.dart';

Widget PrayerTimesList(
    BuildContext context,
    PrayerLoaded state,
    double fontBig,
    double width,
    double height,
    ) {
  final prayerTimes = state.prayerTimes;
  final Map<String, String> arabicNames = {
    'Fajr': 'الفجر',
    'Sunrise': 'الشروق',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  return Column(
    children:
    prayerTimes.entries.map((entry) {
      final prayerKey = entry.key;
      final time = entry.value;
      if (!arabicNames.containsKey(prayerKey)) return const SizedBox();
      return Container(
        margin: EdgeInsets.symmetric(vertical: height * 0.005),
        child: Card(
          color: KprimaryColor,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.015,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: width * 0.05,
                ),
                SizedBox(width: width * 0.03),
                Text(
                  arabicNames[prayerKey]!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontBig,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  formatTime(time),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontBig,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}