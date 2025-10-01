import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../../Core/Const/permission.dart';
import '../../../../Home/presentation/view_model/views/widgets/BottomBar.dart';

class Qiblah extends StatefulWidget {
  const Qiblah({super.key});

  @override
  State<Qiblah> createState() => _QiblahState();
}

class _QiblahState extends State<Qiblah> with WidgetsBindingObserver {
  bool permissionGranted = false;
  bool sensorSupported = true;
  QiblahDirection? _direction;
  StreamSubscription<QiblahDirection>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _initSensorSupport();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionManager.requestPermissions();
    if (mounted) {
      setState(() {
        permissionGranted = granted;
      });
      _updateStream();
    }
  }

  void _initSensorSupport() {
    FlutterQiblah.androidDeviceSensorSupport().then((support) {
      if (mounted) {
        sensorSupported = support ?? false;
        setState(() {});
        _updateStream();
      }
    }).catchError((_) {
      if (mounted) {
        sensorSupported = false;
        setState(() {});
      }
    });
  }

  void _updateStream() {
    _subscription?.cancel();
    _direction = null;

    if (permissionGranted && sensorSupported) {
      _subscription = FlutterQiblah.qiblahStream.listen((dir) {
        if (mounted) {
          setState(() {
            if (_direction == null ||
                (dir.qiblah - _direction!.qiblah).abs() > 0.5) {
              _direction = dir;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    } else if (state == AppLifecycleState.paused) {
      _subscription?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;
    final compassSize = width * 0.8;

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
                ? Text('برجاء تفعيل الموقع', style: TextStyle(fontSize: fontBig))
                : !sensorSupported
                ? Text("الجهاز لا يدعم البوصلة", style: TextStyle(fontSize: fontBig))
                : (_direction == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: KprimaryColor),
                const SizedBox(height: 20),
                Text('جاري تهيئة التطبيق', style: TextStyle(fontSize: fontBig)),
              ],
            )
                : Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'Assets/compass.svg',
                  width: compassSize,
                  height: compassSize,
                ),
                Transform.rotate(
                  angle: -_direction!.qiblah * 3.141592653589793 / 180,
                  child: SvgPicture.asset(
                    'Assets/needle.svg',
                    width: compassSize,
                    height: compassSize,
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}
