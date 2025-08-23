import 'package:flutter/cupertino.dart';
import '../../prayer_state.dart';
import 'NextPrayerCountdownWithImage.dart';

Widget CountdownWithImage(
    BuildContext context,
    PrayerLoaded state,
    double fontBig,
    double width,
    double height,
    ) {
  return NextPrayerCountdownWithImage(
    prayerTimes: state.prayerTimes,
    fontBig: fontBig,
    fontNormal: fontBig,
    height: height * 0.15,
  );
}