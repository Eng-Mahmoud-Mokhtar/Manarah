import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'date_state.dart';

class DateCubit extends Cubit<DateState> {
  Timer? _timer;

  DateCubit() : super(DateState.initial()) {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final timeFormat = DateFormat('hh:mm');
      final timeText = timeFormat.format(now);
      final hijri = HijriCalendar.fromDate(now);
      final periodFormat = DateFormat('a', 'ar');
      final period = periodFormat.format(now) == 'ص' ? 'ص' : 'م';
      final gregorianDate = DateFormat('dd MMMM yyyy', 'ar').format(now);
      final hijriDate =
          '${hijri.hDay} ${DateState.hijriMonths[hijri.hMonth - 1]} ${hijri.hYear} هـ';
      String backgroundImage;
      final hour = now.hour;
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

      emit(DateState(
        hijriDate: hijriDate,
        gregorianDate: gregorianDate,
        timeText: timeText,
        period: period,
        backgroundImage: backgroundImage,
      ));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
