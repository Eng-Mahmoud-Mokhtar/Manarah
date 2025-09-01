import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../../Core/Const/permission.dart';
import '../../../../Home/presentation/view_model/views/Home.dart';

class Qiblah extends StatefulWidget {
  const Qiblah({super.key});

  @override
  State<Qiblah> createState() => _QiblahState();
}

class _QiblahState extends State<Qiblah> with WidgetsBindingObserver {
  bool permissionGranted = false;
  bool sensorSupported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _initSensorSupport();
  }

  Future<void> _checkPermissions() async {
    // استخدام PermissionManager لطلب أذونات الموقع
    final granted = await PermissionManager.requestPermissions();
    if (mounted) {
      setState(() {
        permissionGranted = granted;
      });
    }
  }

  void _initSensorSupport() {
    FlutterQiblah.androidDeviceSensorSupport().then((support) {
      if (mounted) {
        setState(() => sensorSupported = support!);
      }
    }).catchError((_) {
      if (mounted) setState(() => sensorSupported = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // إعادة التحقق من الإذن عند عودة التطبيق
      _checkPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: KprimaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: iconSize),
          onPressed: () {
            context.read<BottomNavCubit>().setIndex(0);
          },
        ),
        title: Text(
          'القبلة',
          style: TextStyle(fontSize: fontBig, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('Assets/Login.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: !permissionGranted
                ? Text('برجاء تفعيل موقع الجهاز', style: TextStyle(fontSize: fontBig))
                : !sensorSupported
                ? Text("الجهاز لا يدعم البوصلة", style: TextStyle(fontSize: fontBig))
                : const QiblahCompassWidget(),
          ),
        ],
      ),
    );
  }
}

class QiblahCompassWidget extends StatelessWidget {
  const QiblahCompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compassSize = width * 0.8;
    final needleSize = width * 0.8;

    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: KprimaryColor),
              const SizedBox(height: 20),
              Text('جاري تهيئة التطبيق', style: TextStyle(fontSize: width * 0.04)),
            ],
          );
        }

        final direction = snapshot.data!;

        return Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'Assets/compass.svg',
              width: compassSize,
              height: compassSize,
            ),
            Transform.rotate(
              angle: -direction.qiblah * 3.141592653589793 / 180,
              child: SvgPicture.asset(
                'Assets/needle.svg',
                width: needleSize,
                height: needleSize,
              ),
            ),
          ],
        );
      },
    );
  }
}
