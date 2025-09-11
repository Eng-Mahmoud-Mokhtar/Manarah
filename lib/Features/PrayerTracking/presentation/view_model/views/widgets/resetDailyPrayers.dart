import 'package:shared_preferences/shared_preferences.dart';

Future<void> resetDailyPrayers() async {
  final prefs = await SharedPreferences.getInstance();
  String today = DateTime.now().toString().split(" ")[0];

  final prayers = ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"];
  for (var prayer in prayers) {
    if (!prefs.containsKey("$today-$prayer")) {
      await prefs.setBool("$today-$prayer", false);
    }
  }
}