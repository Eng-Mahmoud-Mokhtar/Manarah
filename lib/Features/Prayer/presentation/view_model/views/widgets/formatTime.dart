import 'package:intl/intl.dart';

String formatTime(String time) {
  try {
    final parsed = DateFormat('HH:mm').parse(time);
    final formatted = DateFormat('h:mm a').format(parsed);
    return formatted
        .replaceAll('AM', 'ص')
        .replaceAll('PM', 'م')
        .replaceFirst(RegExp(r'^0'), '');
  } catch (e) {
    return time;
  }
}