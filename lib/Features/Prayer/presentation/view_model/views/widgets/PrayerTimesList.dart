import 'package:flutter/material.dart';
import '../../../../../../Core/Const/Colors.dart';
import '../../prayer_state.dart';
import 'formatTime.dart';

Widget PrayerTimesList(
    BuildContext context,
    PrayerLoaded state,
    double fontBig,
    double width,
    double height,
    Map<String, bool> adhanEnabled,
    Function(String) toggleAdhanForPrayer,
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
    children: prayerTimes.entries.map((entry) {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => toggleAdhanForPrayer(prayerKey),
                  child: Icon(
                    adhanEnabled[prayerKey] == true
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: adhanEnabled[prayerKey] == true
                        ? Colors.orange
                        : Colors.red,
                    size: fontBig * 1.3,
                  ),
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