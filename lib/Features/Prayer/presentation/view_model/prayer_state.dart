import 'package:equatable/equatable.dart';

abstract class PrayerState extends Equatable {
  const PrayerState();
  @override
  List<Object?> get props => [];
}

class PrayerInitial extends PrayerState {}

class PrayerLoading extends PrayerState {}

class PrayerLoaded extends PrayerState {
  final Map<String, String> prayerTimes;
  final String city;
  final String country;

  const PrayerLoaded({
    required this.prayerTimes,
    required this.city,
    required this.country,
  });

  @override
  List<Object?> get props => [prayerTimes, city, country];
}

class PrayerError extends PrayerState {
  final String message;

  const PrayerError({this.message = 'حدث خطأ، يرجى المحاولة مرة أخرى'});

  @override
  List<Object?> get props => [message];
}