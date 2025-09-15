import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/prayer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerCubit extends Cubit<PrayerState> {
  final Dio dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ServiceStatus>? _locationServiceSubscription;

  PrayerCubit({Dio? dio})
      : dio = dio ?? Dio(),
        super(PrayerInitial()) {
    _monitorConnectivity();
    _monitorLocationService();
    getPrayerTimes();
  }

  // دالة للحصول على فهرس الصلاة في القائمة
  int getPrayerIndex(String prayer) {
    final List<String> prayerOrder = [
      'Fajr',
      'Sunrise',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha'
    ];
    return prayerOrder.indexOf(prayer);
  }

  // مراقبة الاتصال بالإنترنت
  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasConnection = results.any((result) =>
      result == ConnectivityResult.mobile || result == ConnectivityResult.wifi);
      if (hasConnection) {
        await getPrayerTimes();
      } else {
        // إذا لم يكن هناك اتصال، نحاول تحميل البيانات المخزنة
        _loadCachedData();
      }
    });
  }

  // مراقبة خدمات الموقع
  void _monitorLocationService() {
    _locationServiceSubscription = Geolocator.getServiceStatusStream().listen((ServiceStatus status) async {
      if (status == ServiceStatus.enabled) {
        await getPrayerTimes();
      } else {
        emit(const PrayerError(message: 'خدمات الموقع غير مفعلة'));
      }
    });
  }

  // تحميل البيانات المخزنة
  Future<void> _loadCachedData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('prayer_times_data');
      final cachedDate = prefs.getString('prayer_times_date');

      if (cachedData != null && cachedDate != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        final Map<String, String> prayerTimes = Map<String, String>.from(data['prayerTimes']);
        final String city = data['city'];
        final String country = data['country'];

        emit(PrayerLoaded(prayerTimes: prayerTimes, city: city, country: country));
      } else {
        emit(const PrayerError(message: 'لا يوجد اتصال بالإنترنت'));
      }
    } catch (e) {
      emit(const PrayerError(message: 'لا يوجد اتصال بالإنترنت'));
    }
  }

  // التحقق مما إذا تم عرض رسالة الإذن من قبل
  Future<bool> _hasShownPermissionDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_shown_permission_dialog') ?? false;
  }

  // تعيين حالة عرض رسالة الإذن
  Future<void> _setPermissionDialogShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_permission_dialog', true);
  }

  // دالة لتعيين البيانات المخزنة
  void setCachedData(Map<String, String> prayerTimes, String city, String country) {
    emit(PrayerLoaded(prayerTimes: prayerTimes, city: city, country: country));
  }

  // دالة لتعيين حالة الخطأ
  void setErrorState(String message) {
    emit(PrayerError(message: message));
  }

  // جلب أوقات الصلاة
  Future<void> getPrayerTimes() async {
    try {
      emit(PrayerLoading());

      // التحقق من الاتصال بالإنترنت
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any((result) =>
      result == ConnectivityResult.mobile || result == ConnectivityResult.wifi);
      if (!hasConnection) {
        await _loadCachedData();
        return;
      }

      // التحقق من تفعيل خدمات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        bool hasShownDialog = await _hasShownPermissionDialog();
        if (!hasShownDialog) {
          emit(const PrayerError(message: 'خدمات الموقع غير مفعلة'));
          await _setPermissionDialogShown();
        }
        return;
      }

      // التحقق من إذن الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        bool hasShownDialog = await _hasShownPermissionDialog();
        if (!hasShownDialog) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            emit(const PrayerError(message: 'تم رفض إذن الموقع'));
            await _setPermissionDialogShown();
            return;
          }
          await _setPermissionDialogShown();
        } else {
          emit(const PrayerError(message: 'تم رفض إذن الموقع'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        bool hasShownDialog = await _hasShownPermissionDialog();
        if (!hasShownDialog) {
          emit(const PrayerError(message: 'إذن الموقع مرفوض نهائيًا'));
          await _setPermissionDialogShown();
        } else {
          emit(const PrayerError(message: 'إذن الموقع مرفوض نهائيًا'));
        }
        return;
      }

      // جلب الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // تحويل الإحداثيات إلى اسم المدينة والدولة
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String city = placemarks.first.locality ?? 'مدينة غير معروفة';
      String country = placemarks.first.country ?? 'دولة غير معروفة';

      // جلب المنطقة الزمنية
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;

      // طلب أوقات الصلاة من API
      final response = await dio.get(
        'http://api.aladhan.com/v1/timings',
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'method': 5,
          'adjustment': 1,
          'timezone': timeZoneName,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final timings = data['data']['timings'] as Map<String, dynamic>;
        final prayerTimes = {
          'Fajr': timings['Fajr'] as String,
          'Sunrise': timings['Sunrise'] as String,
          'Dhuhr': timings['Dhuhr'] as String,
          'Asr': timings['Asr'] as String,
          'Maghrib': timings['Maghrib'] as String,
          'Isha': timings['Isha'] as String,
        };
        emit(PrayerLoaded(
          prayerTimes: prayerTimes,
          city: city,
          country: country,
        ));
      } else {
        await _loadCachedData();
      }
    } catch (e) {
      await _loadCachedData();
    }
  }

  // دالة لتعطيل وظائف الموقع
  void disableLocation() {
    emit(const PrayerError(message: 'تم تعطيل خدمات الموقع'));
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _locationServiceSubscription?.cancel();
    return super.close();
  }
}