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
import 'package:manarah/Features/Home/presentation/view_model/views/Home.dart';
import 'package:manarah/Features/Home/presentation/view_model/views/widgets/duas.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/prayer_cubit.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/prayer_state.dart';
import 'package:manarah/Features/Sebha/presentation/view_model/views/Sebha.dart';
import '../../../../../Quran/presentation/view_model/views/Quran.dart';
import 'CustomContainer.dart';

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> with WidgetsBindingObserver {
  late Map<String, String> randomDua;
  bool isLocationEnabled = false;
  bool isNotificationsEnabled = false;
  StreamSubscription<ServiceStatus>? _locationServiceSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    randomDua = duas[Random().nextInt(duas.length)];
    _checkAndRequestLocationPermission();
    _checkLocationStatus();
    _loadNotificationStatus();
    _locationServiceSubscription = Geolocator.getServiceStatusStream().listen((status) {
      _checkLocationStatus();
    });
  }

  @override
  void dispose() {
    _locationServiceSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
      context.read<PrayerCubit>().getPrayerTimes();
    }
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    setState(() {
      isLocationEnabled = serviceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always);
    });
  }

  Future<void> _loadNotificationStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<bool> _hasShownPermissionDialog() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_shown_permission_dialog') ?? false;
  }

  Future<void> _setPermissionDialogShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_shown_permission_dialog', true);
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      bool hasShownDialog = await _hasShownPermissionDialog();
      if (!hasShownDialog && mounted) {
        _showLocationDialog('يرجى تفعيل خدمات الموقع');
        await _setPermissionDialogShown();
      }
      return;
    }

    if (permission == LocationPermission.denied) {
      bool hasShownDialog = await _hasShownPermissionDialog();
      if (!hasShownDialog && mounted) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && mounted) {
          _showLocationDialog('تم رفض إذن الموقع.');
          await _setPermissionDialogShown();
          return;
        }
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      bool hasShownDialog = await _hasShownPermissionDialog();
      if (!hasShownDialog) {
        _showLocationDialog('إذن الموقع مرفوض نهائيًا. يرجى تفعيله من إعدادات التطبيق.');
        await _setPermissionDialogShown();
      }
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _checkLocationStatus();
    }
  }

  void _showLocationDialog(String message) {
    if (!mounted) return;
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
            Icon(Icons.location_on, color: Colors.orangeAccent, size: 24),
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
            onPressed: () => Navigator.pop(context),
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
    if (value) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await _checkLocationStatus();
        if (await Geolocator.isLocationServiceEnabled()) {
          context.read<PrayerCubit>().getPrayerTimes();
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          isLocationEnabled = true;
        });
        context.read<PrayerCubit>().getPrayerTimes();
      }
    } else {
      setState(() {
        isLocationEnabled = false;
      });
      context.read<PrayerCubit>().disableLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final List<Map<String, dynamic>> items = [
      {
        'name': 'القرآن الكريم',
        'image': 'Assets/Group.png',
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Quran()),
          );
        },
      },
      {
        'name': 'التسبيح',
        'image': 'Assets/noto.png',
        'page': Sebha(),
      },
      {
        'name': 'الأذكار',
        'image': 'Assets/fluent-emoji-high-contrast_prayer-beads.png',
        'action': () => context.read<BottomNavCubit>().setIndex(3),
      },
    ];

    return BlocListener<PrayerCubit, PrayerState>(
      listener: (context, state) {
        if (state is PrayerLoaded) {
          setState(() {
            isLocationEnabled = true;
          });
        } else if (state is PrayerError) {
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
                         'اذن الموقع',
                          style: TextStyle(fontSize: width * 0.03, fontWeight: FontWeight.bold),
                        ),
                        trailing: Switch(
                          value: isLocationEnabled,
                          activeColor: KprimaryColor,
                          inactiveTrackColor: Colors.red.shade600,
                          onChanged: (value) {
                            toggleLocationPermission(value);
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
                              : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => item['page'],
                            ),
                          ),
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