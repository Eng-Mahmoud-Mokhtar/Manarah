import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

class DateState {
  final String hijriDate;
  final String gregorianDate;
  final String timeText;
  final String period;
  final String backgroundImage;

  static const List<String> hijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الثانية',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  DateState({
    required this.hijriDate,
    required this.gregorianDate,
    required this.timeText,
    required this.period,
    required this.backgroundImage,
  });

  factory DateState.initial() {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    final timeFormat = DateFormat('hh:mm');
    final periodFormat = DateFormat('a', 'ar');
    final hour = now.hour;
    String backgroundImage;
    if (hour >= 4 && hour < 6) {
      backgroundImage = 'Assets/Rectangle 1 (4).png';
    } else if (hour >= 6 && hour < 9) {
      backgroundImage = 'Assets/Rectangle 1.png';
    } else if (hour >= 9 && hour < 17) {
      backgroundImage = 'Assets/Rectangle 1 (1).png';
    } else if (hour >= 17 && hour < 19) {
      backgroundImage = 'Assets/Rectangle 1 (3).png';
    } else {
      backgroundImage = 'Assets/Rectangle 1 (2).png';
    }
    return DateState(
      hijriDate: '${hijri.hDay} ${hijriMonths[hijri.hMonth - 1]} ${hijri.hYear} هـ',
      gregorianDate: DateFormat('dd MMMM yyyy', 'ar').format(now),
      timeText: timeFormat.format(now),
      period: periodFormat.format(now) == 'ص' ? 'ص' : 'م',
      backgroundImage: backgroundImage,
    );
  }
}
