import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../../Core/Const/convertToArabicNumerals.dart';

/// ---------------------
/// PrayerRepository
/// ---------------------
class PrayerRepository {
  static final PrayerRepository instance = PrayerRepository._internal();
  PrayerRepository._internal();
  SharedPreferences? _prefs;
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  final List<String> prayers = ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"];

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    String todayStr = _dateToStr(DateTime.now());
    String? lastSaved = _prefs!.getString("last_saved_date");
    if (lastSaved == null) {
      await _ensureDayExists(todayStr);
      await _prefs!.setString("last_saved_date", todayStr);
      notifier.value++;
      return;
    }
    DateTime last = DateTime.parse(lastSaved);
    DateTime today = DateTime.now();
    int diff = today.difference(last).inDays;
    if (diff <= 0) {
      await _ensureDayExists(todayStr);
      notifier.value++;
      return;
    }
    for (int i = 1; i <= diff; i++) {
      DateTime d = last.add(Duration(days: i));
      String dStr = _dateToStr(d);
      await _ensureDayExists(dStr);
    }
    await _prefs!.setString("last_saved_date", todayStr);
    notifier.value++;
  }

  Future<void> _ensureDayExists(String dateStr) async {
    for (var p in prayers) {
      if (!_prefs!.containsKey("$dateStr-$p")) {
        await _prefs!.setBool("$dateStr-$p", false);
      }
    }
  }

  Future<void> setPrayer(String dateStr, String prayer, bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool("$dateStr-$prayer", value);
    notifier.value++;
  }

  Future<bool> getPrayer(String dateStr, String prayer) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool("$dateStr-$prayer") ?? false;
  }

  Future<Map<String, int>> getMissedCountForLastDays(int days) async {
    _prefs ??= await SharedPreferences.getInstance();
    final Map<String, int> counts = {for (var p in prayers) p: 0};
    DateTime today = DateTime.now();
    for (int i = 0; i < days; i++) {
      String dStr = _dateToStr(today.subtract(Duration(days: i)));
      bool hasData = false;
      for (var p in prayers) {
        if (_prefs!.containsKey("$dStr-$p")) {
          hasData = true;
          bool done = _prefs!.getBool("$dStr-$p") ?? false;
          if (!done) counts[p] = counts[p]! + 1;
        }
      }
      if (!hasData) {
        continue;
      }
    }
    return counts;
  }

  Future<List<DateTime>> getLastDates(int days) async {
    DateTime today = DateTime.now();
    return List.generate(days, (i) => today.subtract(Duration(days: i)));
  }

  static String _dateToStr(DateTime d) {
    return DateTime(d.year, d.month, d.day).toIso8601String().split("T")[0];
  }

  /// Mark all stored days (within a range) as prayed (used for markAllAsPrayed)
  Future<void> markAllAsPrayedInDates(List<DateTime> dates) async {
    _prefs ??= await SharedPreferences.getInstance();
    for (var date in dates) {
      String dStr = _dateToStr(date);
      for (var p in prayers) {
        await _prefs!.setBool("$dStr-$p", true);
      }
    }
    notifier.value++;
  }

  /// Helper: ensure today exists and update last_saved_date
  Future<void> ensureTodayExistsAndUpdateLast() async {
    _prefs ??= await SharedPreferences.getInstance();
    String todayStr = _dateToStr(DateTime.now());
    await _ensureDayExists(todayStr);
    await _prefs!.setString("last_saved_date", todayStr);
    notifier.value++;
  }
}

/// ---------------------
/// Top-level callback for AndroidAlarmManager
/// ---------------------
Future<void> resetDailyPrayers() async {
  final prefs = await SharedPreferences.getInstance();
  final prayers = ["الفجر", "الظهر", "العصر", "المغرب", "العشاء"];
  String today = DateTime.now().toIso8601String().split("T")[0];
  for (var prayer in prayers) {
    if (!prefs.containsKey("$today-$prayer")) {
      await prefs.setBool("$today-$prayer", false);
    }
  }
  String? lastSaved = prefs.getString("last_saved_date");
  if (lastSaved == null) {
    await prefs.setString("last_saved_date", today);
  } else {
    DateTime last = DateTime.parse(lastSaved);
    DateTime todayDT = DateTime.parse(today);
    int diff = todayDT.difference(last).inDays;
    if (diff > 0) {
      for (int i = 1; i <= diff; i++) {
        DateTime d = last.add(Duration(days: i));
        String dStr = d.toIso8601String().split("T")[0];
        for (var p in prayers) {
          if (!prefs.containsKey("$dStr-$p")) {
            await prefs.setBool("$dStr-$p", false);
          }
        }
      }
      await prefs.setString("last_saved_date", today);
    }
  }
}

/// ---------------------
/// PrayerTracking Widget (الصفحة الرئيسية)
/// ---------------------
class PrayerTracking extends StatelessWidget {
  const PrayerTracking({super.key});
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: KprimaryColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: iconSize),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'متابعة الصلاه',
            style: TextStyle(fontSize: fontBig, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            SizedBox.expand(
              child: Image.asset(
                "Assets/Login.png",
                fit: BoxFit.cover,
              ),
            ),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  color: KprimaryColor,
                  child: const TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: "اليومية"),
                      Tab(text: "الفائتة"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      DailyPrayers(),
                      MissedPrayers(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------
/// MissedPrayers Widget
/// ---------------------
class MissedPrayers extends StatefulWidget {
  @override
  State<MissedPrayers> createState() => _MissedPrayersState();
}

class _MissedPrayersState extends State<MissedPrayers> with AutomaticKeepAliveClientMixin {
  final PrayerRepository repo = PrayerRepository.instance;
  List<DateTime> dates = [];
  Map<String, int> missedCount = {
    "الفجر": 0,
    "الظهر": 0,
    "العصر": 0,
    "المغرب": 0,
    "العشاء": 0,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
    // إضافة listener للتغيرات في الـ notifier
    repo.notifier.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    // إزالة listener عند التخلص من الـ widget
    repo.notifier.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      _calculateMissed();
      setState(() {});
    }
  }

  Future<void> _init() async {
    await repo.init();
    DateTime today = DateTime.now();
    dates = List.generate(30, (i) => today.subtract(Duration(days: i)));
    await _calculateMissed();
    if (mounted) setState(() {});
  }

  Future<void> _calculateMissed() async {
    missedCount = await repo.getMissedCountForLastDays(30);
  }

  Future<void> markAllAsPrayed() async {
    await repo.markAllAsPrayedInDates(dates);
    await _calculateMissed();
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
    super.build(context);
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;

    if (dates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<String> allMissed = [];
    for (var date in dates) {
      String dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split("T")[0];
      for (var prayer in repo.prayers) {
        bool done = (repo._prefs?.getBool("$dateStr-$prayer")) ?? false;
        if (!done && (repo._prefs?.containsKey("$dateStr-$prayer") ?? false)) {
          allMissed.add(prayer);
        }
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
                String dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split("T")[0];
                String dayName = DateFormat.EEEE('ar').format(date);
                String formattedDate = DateFormat('d-M-yyyy').format(date);
                formattedDate = convertToArabicNumbers2(formattedDate);
                List<String> missedPrayersForDate = [];
                for (var prayer in repo.prayers) {
                  bool? done = repo._prefs?.getBool("$dateStr-$prayer");
                  if (done != null && !done) missedPrayersForDate.add(prayer);
                }
                if (missedPrayersForDate.isEmpty) return const SizedBox.shrink();
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
                      bool value = repo._prefs?.getBool("$dateStr-$prayer") ?? false;
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
                            await repo.setPrayer(dateStr, prayer, v ?? false);
                            // لا حاجة لاستدعاء setState هنا لأن الـ listener سيتولى ذلك
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

/// ---------------------
/// DailyPrayers Widget
/// ---------------------
class DailyPrayers extends StatefulWidget {
  const DailyPrayers({super.key});

  @override
  State<DailyPrayers> createState() => _DailyPrayersState();
}

class _DailyPrayersState extends State<DailyPrayers> with AutomaticKeepAliveClientMixin {
  final PrayerRepository repo = PrayerRepository.instance;
  Map<String, bool> prayersState = {
    "الفجر": false,
    "الظهر": false,
    "العصر": false,
    "المغرب": false,
    "العشاء": false,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeDailyPrayers();
    _scheduleDailyReset();
    // إضافة listener للتغيرات في الـ notifier
    repo.notifier.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    // إزالة listener عند التخلص من الـ widget
    repo.notifier.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      _loadTodayFromRepo();
    }
  }

  Future<void> _initializeDailyPrayers() async {
    await repo.init();
    await repo.ensureTodayExistsAndUpdateLast();
    await _loadTodayFromRepo();
    if (mounted) setState(() {});
  }

  Future<void> _loadTodayFromRepo() async {
    String todayStr = DateTime.now().toIso8601String().split("T")[0];
    for (var p in repo.prayers) {
      prayersState[p] = repo._prefs?.getBool("$todayStr-$p") ?? false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _scheduleDailyReset() async {
    await AndroidAlarmManager.initialize();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      1,
      resetDailyPrayers,
      startAt: midnight,
      exact: true,
      wakeup: true,
    );
  }

  Future<void> _savePrayer(String prayer, bool value) async {
    String todayStr = DateTime.now().toIso8601String().split("T")[0];
    await repo.setPrayer(todayStr, prayer, value);
    prayersState[prayer] = value;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;

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
      child: ListView(
        padding: EdgeInsets.all(width * 0.04),
        children: repo.prayers.map((prayer) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
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
            child: Theme(
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
                contentPadding: EdgeInsets.only(left: 0),
                title: Text(
                  prayer,
                  style: TextStyle(
                    fontSize: fontBig,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: prayersState[prayer],
                onChanged: (value) => _savePrayer(prayer, value ?? false),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}