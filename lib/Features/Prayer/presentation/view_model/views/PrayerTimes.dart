import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/views/widgets/CountdownWithImage.dart';
import 'package:manarah/Features/Prayer/presentation/view_model/views/widgets/PrayerTimesList.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../Prayer/presentation/view_model/prayer_cubit.dart';
import '../../../../Prayer/presentation/view_model/prayer_state.dart';

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  State<PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PrayerCubit>().getPrayerTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PrayerCubit>().getPrayerTimes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fontBig = width * 0.04;
    final fontNormal = width * 0.025;

    return Scaffold(
      body: Container(
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
            AppBar(
              backgroundColor: KprimaryColor,
              elevation: 0,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: width * 0.05,
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أوقات الصلاة',
                    style: TextStyle(
                      fontSize: fontBig,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 5),
                        Icon(Icons.location_on, color: Colors.orangeAccent, size: width * 0.04),
                        Text(
                          context.watch<PrayerCubit>().state is PrayerLoaded
                              ? '${(context.watch<PrayerCubit>().state as PrayerLoaded).city}, ${(context.watch<PrayerCubit>().state as PrayerLoaded).country}'
                              : 'تحميل..',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontNormal,
                            fontFamily: 'AmiriQuran-Regular',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            Expanded(
              child: BlocBuilder<PrayerCubit, PrayerState>(
                builder: (context, state) {
                  if (state is PrayerLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: KprimaryColor,
                      ),
                    );
                  } else if (state is PrayerError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.message,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: fontBig,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                if (state.message.contains('خدمات الموقع غير مفعلة')) {
                                  await Geolocator.openLocationSettings();
                                } else if (state.message.contains('إذن الموقع')) {
                                  if (state.message.contains('نهائيًا')) {
                                    await Geolocator.openAppSettings();
                                  } else {
                                    await Geolocator.requestPermission();
                                  }
                                }
                                context.read<PrayerCubit>().getPrayerTimes();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KprimaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                state.message.contains('خدمات الموقع غير مفعلة')
                                    ? 'تفعيل خدمات الموقع'
                                    : 'منح إذن الموقع',
                                style: TextStyle(
                                  fontSize: fontNormal,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is PrayerLoaded) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: width * 0.04),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                            child: CountdownWithImage(
                              context,
                              state,
                              fontBig,
                              width,
                              height,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.03,
                              vertical: height * 0.01,
                            ),
                            child: PrayerTimesList(
                              context,
                              state,
                              fontBig,
                              width,
                              height,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'جاري تهيئة التطبيق...',
                            style: TextStyle(
                              fontSize: fontBig,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}