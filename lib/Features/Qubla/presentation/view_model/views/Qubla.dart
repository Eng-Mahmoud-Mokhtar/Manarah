import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../Home/presentation/view_model/views/Home.dart';
import 'qiblah_compass.dart';
import 'package:manarah/Features/Qubla/presentation/view_model/views/widgets/loading_indicator.dart';

class Qiblah extends StatefulWidget {
  const Qiblah({super.key});

  @override
  _QiblahState createState() => _QiblahState();
}

class _QiblahState extends State<Qiblah> {
  late final Future<bool?> _deviceSupport;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever!');
      return;
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() {
        _hasLocationPermission = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontNormal = MediaQuery.of(context).size.width * 0.025;
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: KprimaryColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: iconSize),
            onPressed: () {
              context.read<BottomNavCubit>().setIndex(0);
            },
          ),
          title: Text(
            'القبلة',
            style: TextStyle(
              fontSize: fontBig,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: _hasLocationPermission
            ? FutureBuilder<bool?>(
          future: _deviceSupport,
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.data ?? false) {
              return QiblahCompass();
            } else {
              return Center(
                child: Text(
                  "الهاتف لا يدعم استشعار البوصله",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontNormal,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
          },
        )
            : Center(
          child: ElevatedButton(
            onPressed: _requestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: KprimaryColor,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "تفعيل صلاحية الموقع",
              style: TextStyle(
                fontSize: fontNormal,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
