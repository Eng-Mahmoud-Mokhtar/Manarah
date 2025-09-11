import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manarah/Core/Const/Colors.dart';
import 'package:manarah/Core/Const/Images.dart';
import 'package:manarah/Features/Home/presentation/view_model/date_cubit.dart';
import 'package:manarah/Features/Home/presentation/view_model/date_state.dart';
import 'package:manarah/Features/Home/presentation/view_model/views/widgets/duas.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/prayer_cubit.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/prayer_state.dart';
import 'package:manarah/Features/Sebha/presentation/view_model/views/Sebha.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../../../../main.dart';
import '../../../../PrayerTracking/presentation/view_model/views/PrayerTracking.dart';
import '../../../../Quran/presentation/view_model/views/Quran.dart';
import 'widgets/CustomContainer.dart';
import 'widgets/ProcessNotification.dart' hide globalNotificationsPlugin, callbackDispatcher;

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> with WidgetsBindingObserver {
  late Map<String, String> randomDua;
  bool isLocationEnabled = false;
  bool notificationsEnabled = true;
  StreamSubscription<ServiceStatus>? _locationServiceSubscription;

  @override
  void initState() {
    super.initState();
    print("🟢 [HOME_BODY] تهيئة حالة HomeBody");

    WidgetsBinding.instance.addObserver(this);
    randomDua = duas[Random().nextInt(duas.length)];

    _initializeApp().then((_) {
      print("✅ [HOME_BODY] التهيئة اكتملت بنجاح");
    }).catchError((error) {
      print("❌ [HOME_BODY] خطأ في التهيئة: $error");
    });
  }

  // تهيئة التطبيق بالكامل
  Future<void> _initializeApp() async {
    print("🔵 [INIT] بدء تهيئة التطبيق");

    await _initializeWorkManager();
    await _loadNotificationSettings();
    await _checkAndRequestLocationPermission();
    await _checkLocationStatus();
    await _setupNotificationChannel();

    _locationServiceSubscription =
        Geolocator.getServiceStatusStream().listen((status) {
          print("🔵 [LOCATION] حالة خدمة الموقع تغيرت: $status");
          _checkLocationStatus();
        });

    print("✅ [INIT] تهيئة التطبيق اكتملت");
  }
  // تهيئة WorkManager
  Future<void> _initializeWorkManager() async {
    try {
      print("🔵 [WORKMANAGER] بدء تهيئة WorkManager");

      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );

      // تسجيل المهمة الدورية مرة واحدة فقط
      final prefs = await SharedPreferences.getInstance();
      final isTaskRegistered = prefs.getBool('task_registered') ?? false;

      if (!isTaskRegistered) {
        print("🔵 [WORKMANAGER] تسجيل المهمة الدورية لأول مرة");
        await _startBackgroundNotifications();
        await prefs.setBool('task_registered', true);
        print("✅ [WORKMANAGER] تم تسجيل المهمة الدورية بنجاح");
      } else {
        print("🔵 [WORKMANAGER] المهمة مسجلة مسبقاً، جاري التحقق من狀態ها");
        // تحقق من حالة المهمة وقم بإعادة جدولتها إذا لزم الأمر
        await _startBackgroundNotifications();
      }
    } catch (e) {
      print("❌ [WORKMANAGER] خطأ في تهيئة WorkManager: $e");
      // بديل باستخدام AndroidAlarmManager
      await _setupAlarmManager();
    }
  }
  // تهيئة AndroidAlarmManager كبديل
  Future<void> _setupAlarmManager() async {
    try {
      print("🔵 [ALARM_MANAGER] بدء تهيئة AndroidAlarmManager");

      await AndroidAlarmManager.initialize();
      await AndroidAlarmManager.periodic(
        const Duration(minutes: 40),
        0,
        alarmManagerCallback,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      print("✅ [ALARM_MANAGER] تم تفعيل الإشعارات باستخدام AndroidAlarmManager");
    } catch (e) {
      print("❌ [ALARM_MANAGER] خطأ في تهيئة AndroidAlarmManager: $e");
    }
  }
  // تحميل إعدادات الإشعارات من SharedPreferences
  Future<void> _loadNotificationSettings() async {
    try {
      print("🔵 [SETTINGS] جاري تحميل إعدادات الإشعارات");

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });

      print("✅ [SETTINGS] تم تحميل إعدادات الإشعارات: $notificationsEnabled");
    } catch (e) {
      print("❌ [SETTINGS] خطأ في تحميل إعدادات الإشعارات: $e");
    }
  }
  // حفظ إعدادات الإشعارات إلى SharedPreferences
  Future<void> _saveNotificationSettings(bool value) async {
    try {
      print("🔵 [SETTINGS] جاري حفظ إعدادات الإشعارات: $value");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      setState(() {
        notificationsEnabled = value;
      });

      if (value) {
        print("🔵 [SETTINGS] تفعيل الإشعارات في الخلفية");
        await _startBackgroundNotifications();
      } else {
        print("🔵 [SETTINGS] إلغاء تفعيل الإشعارات في الخلفية");
        await Workmanager().cancelByTag("quarter_hourly_task");
        try {
          await AndroidAlarmManager.cancel(0);
          print("✅ [SETTINGS] تم إلغاء الإشعارات بنجاح");
        } catch (e) {
          print("❌ [SETTINGS] خطأ في إلغاء الإشعارات: $e");
        }
      }

      print("✅ [SETTINGS] تم حفظ إعدادات الإشعارات بنجاح");
    } catch (e) {
      print("❌ [SETTINGS] خطأ في حفظ إعدادات الإشعارات: $e");
    }
  }
  // إنشاء قناة الإشعارات
  Future<void> _setupNotificationChannel() async {
    try {
      print("🔵 [NOTIFICATIONS] جاري إنشاء قناة الإشعارات");

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'quarter_hourly_channel',
        'الإشعارات الربع ساعية',
        description: 'قناة للإشعارات المرسلة كل ربع ساعة',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await globalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print("✅ [NOTIFICATIONS] تم إنشاء قناة الإشعارات بنجاح");
    } catch (e) {
      print("❌ [NOTIFICATIONS] خطأ في إنشاء قناة الإشعارات: $e");
    }
  }
  // بدء الإشعارات في الخلفية (كل ربع ساعة)
  Future<void> _startBackgroundNotifications() async {
    try {
      print("🔵 [BACKGROUND] بدء إعداد إشعارات الخلفية");

      // إلغاء أي مهام سابقة بنفس الاسم
      await Workmanager().cancelByTag("quarter_hourly_task");

      // تسجيل المهمة الدورية
      await Workmanager().registerPeriodicTask(
        "quarter_hourly_task",
        "quarter_hourly_task",
        frequency: const Duration(minutes: 40),
        initialDelay: const Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresBatteryNotLow: false,
        ),
        tag: "quarter_hourly_task",
      );
      print("✅ [BACKGROUND] تم تفعيل إشعارات كل ربع ساعة بنجاح باستخدام WorkManager");
    } catch (e) {
      print("❌ [BACKGROUND] خطأ في تفعيل الإشعارات باستخدام WorkManager: $e");

      // حل بديل باستخدام android_alarm_manager_plus
      await _setupAlarmManager();
    }
  }
  @override
  void dispose() {
    print("🔵 [HOME_BODY] جاري التخلص من الموارد");

    _locationServiceSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    print("✅ [HOME_BODY] تم التخلص من الموارد بنجاح");
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔵 [LIFECYCLE] تغير حالة التطبيق: $state");

    if (state == AppLifecycleState.resumed) {
      print("🔵 [LIFECYCLE] التطبيق عاد للعمل، جاري تحديث البيانات");
      _checkLocationStatus();
      context.read<PrayerCubit>().getPrayerTimes();
    }
  }
  Future<void> _checkLocationStatus() async {
    try {
      print("🔵 [LOCATION] جاري التحقق من حالة الموقع");

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      setState(() {
        isLocationEnabled = serviceEnabled &&
            (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always);
      });

      print("✅ [LOCATION] حالة الموقع: $isLocationEnabled (الخدمة: $serviceEnabled, الإذن: $permission)");
    } catch (e) {
      print("❌ [LOCATION] خطأ في التحقق من حالة الموقع: $e");
    }
  }
  Future<bool> _hasShownPermissionDialog() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_shown_permission_dialog') ?? false;
    } catch (e) {
      print("❌ [PERMISSION] خطأ في التحقق من حالة الحوار: $e");
      return false;
    }
  }
  Future<void> _setPermissionDialogShown() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_shown_permission_dialog', true);
    } catch (e) {
      print("❌ [PERMISSION] خطأ في حفظ حالة الحوار: $e");
    }
  }
  Future<void> _checkAndRequestLocationPermission() async {
    try {
      print("🔵 [PERMISSION] جاري التحقق من أذونات الموقع");

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled) {
        bool hasShownDialog = await _hasShownPermissionDialog();
        if (!hasShownDialog && mounted) {
          print("🔵 [PERMISSION] عرض حوار تفعيل خدمات الموقع");
          _showLocationDialog('يرجى تفعيل خدمات الموقع');
          await _setPermissionDialogShown();
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        bool hasShownDialog = await _hasShownPermissionDialog();
        if (!hasShownDialog && mounted) {
          print("🔵 [PERMISSION] طلب إذن الموقع");
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied && mounted) {
            print("🔵 [PERMISSION] تم رفض إذن الموقع، عرض الحوار");
            _showLocationDialog('تم رفض إذن الموقع.');
            await _setPermissionDialogShown();
            return;
          }
        }
      }

      if (permission == LocationPermission.deniedForever && mounted) {
        bool hasShownDialog = await _hasShownPermissionDialog();
        if (!hasShownDialog) {
          print("🔵 [PERMISSION] إذن الموقع مرفوض نهائياً، عرض الحوار");
          _showLocationDialog('إذن الموقع مرفوض نهائيًا. يرجى تفعيله من إعدادات التطبيق.');
          await _setPermissionDialogShown();
        }
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print("✅ [PERMISSION] أذونات الموقع ممنوحة بنجاح");
        _checkLocationStatus();
      }
    } catch (e) {
      print("❌ [PERMISSION] خطأ في التحقق من أذونات الموقع: $e");
    }
  }
  void _showLocationDialog(String message) {
    if (!mounted) return;

    print("🔵 [DIALOG] عرض حوار الموقع: $message");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        titlePadding: const EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: 8,
        ),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.orangeAccent, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'إذن الموقع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: KprimaryColor.withOpacity(0.1),
            ),
            onPressed: () {
              print("🔵 [DIALOG] تم النقر على موافق في حوار الموقع");
              Navigator.pop(context);
            },
            child: Text(
              'حسنًا',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: KprimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> toggleLocationPermission(bool value) async {
    try {
      print("🔵 [LOCATION] تغيير إذن الموقع إلى: $value");

      if (value) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print("🔵 [LOCATION] خدمات الموقع معطلة، فتح إعدادات الموقع");
          await Geolocator.openLocationSettings();
          await _checkLocationStatus();
          if (await Geolocator.isLocationServiceEnabled()) {
            context.read<PrayerCubit>().getPrayerTimes();
          }
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          print("🔵 [LOCATION] طلب إذن الموقع");
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.deniedForever) {
            print("🔵 [LOCATION] فتح إعدادات التطبيق لمنح الإذن");
            await Geolocator.openAppSettings();
          }
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          setState(() {
            isLocationEnabled = true;
          });
          context.read<PrayerCubit>().getPrayerTimes();
          print("✅ [LOCATION] تم تفعيل الموقع بنجاح");
        }
      } else {
        setState(() {
          isLocationEnabled = false;
        });
        context.read<PrayerCubit>().disableLocation();
        print("✅ [LOCATION] تم تعطيل الموقع بنجاح");
      }
    } catch (e) {
      print("❌ [LOCATION] خطأ في تغيير إذن الموقع: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final List<Map<String, dynamic>> items = [
    {
      'name': 'القرآن الكريم',
    'image': 'Assets/alquran (1).png',
    'action': () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Quran()));
  },
      },
      {
        'name': 'التسبيح',
        'image': 'Assets/noto.png',
        'page': Sebha(),
      },
      {
        'name': 'متابعة الصلاه',
        'image': 'Assets/dua.png',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PrayerTracking()),
          );
        },
      },
    ];
    return BlocListener<PrayerCubit, PrayerState>(
      listener: (context, state) {
        if (state is PrayerLoaded) {
          print("✅ [PRAYER] تم تحميل أوقات الصلاة بنجاح");
          setState(() {
            isLocationEnabled = true;
          });
        } else if (state is PrayerError) {
          print("❌ [PRAYER] خطأ في تحميل أوقات الصلاة: ${state.message}");
          setState(() {
            isLocationEnabled = false;
          });
        }
      },
      child: Scaffold(
        endDrawer: Drawer(
          width: width * 0.6,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: height * 0.15,
                  width: double.infinity,
                  color: KprimaryColor,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: Colors.white, size: width * 0.07),
                          SizedBox(width: width * 0.04),
                          Text(
                            'الإعدادات',
                            style: TextStyle(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(width * 0.01),
                    children: [
                      ListTile(
                        title: Text(
                          'إذن الموقع',
                          style: TextStyle(fontSize: width * 0.03, fontWeight: FontWeight.bold),
                        ),
                        trailing: Switch(
                          value: isLocationEnabled,
                          activeColor: KprimaryColor,
                          inactiveTrackColor: Colors.red.shade600,
                          onChanged: (value) {
                            print("🔵 [SETTINGS] تغيير إذن الموقع إلى: $value");
                            toggleLocationPermission(value);
                          },
                        ),
                      ),
                      ListTile(
                        title: Text(
                          'الإشعارات',
                          style: TextStyle(fontSize: width * 0.03, fontWeight: FontWeight.bold),
                        ),
                        trailing: Switch(
                          value: notificationsEnabled,
                          activeColor: KprimaryColor,
                          inactiveTrackColor: Colors.red.shade600,
                          onChanged: (value) {
                            print("🔵 [SETTINGS] تغيير الإشعارات إلى: $value");
                            _saveNotificationSettings(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("Assets/Login.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(width * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocSelector<
                    DateCubit,
                    DateState,
                    ({String hijriDate, String gregorianDate})>(
                  selector: (state) => (
                  hijriDate: state.hijriDate,
                  gregorianDate: state.gregorianDate,
                  ),
                  builder: (context, date) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: height * 0.02,
                        top: height * 0.02,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(width * 0.025),
                                child: Image.asset(
                                  KprimaryImage,
                                  fit: BoxFit.contain,
                                  color: KprimaryColor,
                                  cacheWidth: (width *
                                      0.04 *
                                      MediaQuery.of(context).devicePixelRatio)
                                      .round(),
                                  cacheHeight: (width *
                                      0.05 *
                                      MediaQuery.of(context).devicePixelRatio)
                                      .round(),
                                ),
                              ),
                              SizedBox(width: width * 0.02),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    date.hijriDate,
                                    style: TextStyle(
                                      fontSize: width * 0.03,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    '${date.gregorianDate} م',
                                    style: TextStyle(
                                      fontSize: width * 0.03,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: width * 0.12,
                            height: width * 0.12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.settings_outlined,
                                color: KprimaryColor,
                                size: width * 0.07,
                              ),
                              onPressed: () {
                                print("🔵 [UI] فتح دروج الإعدادات");
                                Scaffold.of(context).openEndDrawer();
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                BlocSelector<
                    DateCubit,
                    DateState,
                    ({String timeText, String period, String backgroundImage})>(
                  selector: (state) => (
                  timeText: state.timeText,
                  period: state.period,
                  backgroundImage: state.backgroundImage,
                  ),
                  builder: (context, timeData) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          height: width > 600 ? height * 0.28 : height * 0.22,
                          padding: EdgeInsets.all(width * 0.02),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: KprimaryColor, width: 2),
                            image: DecorationImage(
                              image: AssetImage(timeData.backgroundImage),
                              fit: BoxFit.cover,
                              opacity: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${timeData.timeText} ${timeData.period}',
                                  style: TextStyle(
                                    fontSize: width * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: width * 0.08),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items.asMap().entries.map((entry) {
                    final item = entry.value;
                    return [
                      Expanded(
                        child: GestureDetector(
                          onTap: item['action'] != null
                              ? item['action'] as VoidCallback
                              : () {
                            print("🔵 [NAVIGATION] الانتقال إلى ${item['name']}");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => item['page'],
                              ),
                            );
                          },
                          child: CustomContainer(
                            name: item['name'],
                            imagePath: item['image'],
                            width: width * 0.3,
                          ),
                        ),
                      ),
                      if (entry.key < items.length - 1)
                        SizedBox(width: width * 0.04),
                    ];
                  }).expand((element) => element).toList(),
                ),
                SizedBox(height: width * 0.08),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: SecoundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        randomDua['text']!,
                        style: TextStyle(
                          fontSize: width * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.7,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: height * 0.01),
                      Text(
                        randomDua['narrator']!,
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}