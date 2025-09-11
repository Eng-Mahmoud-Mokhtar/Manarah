import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../Core/Const/Colors.dart';
import '../../../../../../Core/Const/convertToArabicNumerals.dart';

class MissedPrayers extends StatefulWidget {
  @override
  State<MissedPrayers> createState() => _MissedPrayersState();
}

class _MissedPrayersState extends State<MissedPrayers> {
  late SharedPreferences _prefs;
  Map<String, bool> prayerTypes = {
    "الفجر": false,
    "الظهر": false,
    "العصر": false,
    "المغرب": false,
    "العشاء": false,
  };
  List<DateTime> dates = [];

  Map<String, int> missedCount = {
    "الفجر": 0,
    "الظهر": 0,
    "العصر": 0,
    "المغرب": 0,
    "العشاء": 0,
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    DateTime today = DateTime.now();
    String todayStr = today.toString().split(" ")[0];

    // التأكد من أول تشغيل
    bool isFirstRun = _prefs.getBool("is_first_run_missed") ?? true;
    if (isFirstRun) {
      for (var prayer in prayerTypes.keys) {
        await _prefs.setBool("$todayStr-$prayer", false); // غير مؤدى بعد
      }
      await _prefs.setBool("is_first_run_missed", false);
    }

    // إعداد آخر 30 يوم
    List<DateTime> tempDates = [];
    for (int i = 0; i < 30; i++) {
      tempDates.add(today.subtract(Duration(days: i)));
    }

    _calculateMissed(tempDates);

    setState(() {
      dates = tempDates;
    });
  }

  void _calculateMissed(List<DateTime> dateList) {
    missedCount.updateAll((key, value) => 0);

    for (var date in dateList) {
      String dateStr = date.toString().split(" ")[0];

      bool hasData = false;
      for (var prayer in prayerTypes.keys) {
        bool? done = _prefs.getBool("$dateStr-$prayer");
        if (done != null) {
          hasData = true;
          if (!done) missedCount[prayer] = (missedCount[prayer] ?? 0) + 1;
        }
      }
      if (!hasData) continue;
    }
  }

  Future<void> markAllAsPrayed() async {
    for (var date in dates) {
      String dateStr = date.toString().split(" ")[0];
      for (var prayer in prayerTypes.keys) {
        await _prefs.setBool("$dateStr-$prayer", true);
      }
    }
    _calculateMissed(dates);
    setState(() {});
  }

  Widget buildMissedCounters(double width) {
    return Container(
      padding: EdgeInsets.only(left: width * 0.02, right: width * 0.02, top: width * 0.04),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: missedCount.keys.map((prayer) {
            return Container(
              width: width * 0.2,
              height: width * 0.2,
              margin: const EdgeInsets.only(right: 6, left: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: KprimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prayer,
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${missedCount[prayer]}",
                    style: TextStyle(
                      fontSize: width * 0.03,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;

    if (dates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<String> allMissed = [];
    for (var date in dates) {
      String dateStr = date.toString().split(" ")[0];
      for (var prayer in prayerTypes.keys) {
        bool? done = _prefs.getBool("$dateStr-$prayer");
        if (done != null && !done) allMissed.add(prayer);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: DecorationImage(
          image: AssetImage('Assets/Login.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          buildMissedCounters(width),
          Expanded(
            child: allMissed.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "Assets/party.png",
                    width: width * 0.4,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "ما أجمل المحافظة على الصلاة",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            )
                : ListView(
              padding: EdgeInsets.all(width * 0.04),
              children: dates.map((date) {
                String dateStr = date.toString().split(" ")[0];
                String dayName = DateFormat.EEEE('ar').format(date);
                String formattedDate = DateFormat('d-M-yyyy').format(date);
                formattedDate = convertToArabicNumbers2(formattedDate);

                List<String> missedPrayersForDate = [];
                for (var prayer in prayerTypes.keys) {
                  bool? done = _prefs.getBool("$dateStr-$prayer");
                  if (done != null && !done) missedPrayersForDate.add(prayer);
                }

                if (missedPrayersForDate.isEmpty) return SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: KprimaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    childrenPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: fontBig,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: fontBig,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    children: missedPrayersForDate.map((prayer) {
                      bool value = _prefs.getBool("$dateStr-$prayer") ?? false;
                      return Theme(
                        data: Theme.of(context).copyWith(
                          unselectedWidgetColor: Colors.transparent,
                          checkboxTheme: CheckboxThemeData(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: MaterialStateBorderSide.resolveWith((states) {
                              return const BorderSide(color: Colors.white, width: 2);
                            }),
                            fillColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.white;
                              }
                              return Colors.transparent;
                            }),
                            checkColor: MaterialStateProperty.all(KprimaryColor),
                          ),
                        ),
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          title: Text(
                            prayer,
                            style: TextStyle(
                              fontSize: fontBig,
                              fontFamily: 'AmiriQuran-Regular',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: value,
                          onChanged: (bool? v) async {
                            await _prefs.setBool("$dateStr-$prayer", v ?? false);
                            _calculateMissed(dates);
                            setState(() {});
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
