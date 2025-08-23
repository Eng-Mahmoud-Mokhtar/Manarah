import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manarah/Features/Qubla/presentation/view_model/views/widgets/loading_indicator.dart';
import 'package:manarah/Features/Qubla/presentation/view_model/views/widgets/location_erorr_widget.dart';


class QiblahCompass extends StatefulWidget {
  const QiblahCompass({super.key});

  @override
  _QiblahCompassState createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass> {
  final _locationStreamController = StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
  }

  Future<void> _checkLocationStatus() async {
    final status = await FlutterQiblah.checkLocationStatus();
    if (status.enabled && status.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      final s = await FlutterQiblah.checkLocationStatus();
      _locationStreamController.sink.add(s);
    } else {
      _locationStreamController.sink.add(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LocationStatus>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();

        if (snapshot.data?.enabled == true) {
          switch (snapshot.data!.status) {
            case LocationPermission.always:
            case LocationPermission.whileInUse:
              return const QiblahCompassWidget();
            case LocationPermission.denied:
              return LocationErrorWidget(
                error: "Location permission denied",
                callback: _checkLocationStatus,
              );
            case LocationPermission.deniedForever:
              return LocationErrorWidget(
                error: "Location permission denied forever",
                callback: _checkLocationStatus,
              );
            default:
              return const SizedBox();
          }
        } else {
          return LocationErrorWidget(
            error: "Please enable location service",
            callback: _checkLocationStatus,
          );
        }
      },
    );
  }
}

class QiblahCompassWidget extends StatelessWidget {
  const QiblahCompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final _compassSvg = SvgPicture.asset('assets/images/compass.svg');
    final _needleSvg = SvgPicture.asset(
      'assets/images/needle.svg',
      fit: BoxFit.contain,
      height: 300,
      alignment: Alignment.center,
    );

    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();

        final qiblahDirection = snapshot.data!;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -qiblahDirection.direction * (pi / 180),
              child: _compassSvg,
            ),
            Transform.rotate(
              angle: -qiblahDirection.qiblah * (pi / 180),
              alignment: Alignment.center,
              child: _needleSvg,
            ),
            Positioned(
              bottom: 8,
              child: Text("${qiblahDirection.offset.toStringAsFixed(3)}°"),
            ),
          ],
        );
      },
    );
  }
}
