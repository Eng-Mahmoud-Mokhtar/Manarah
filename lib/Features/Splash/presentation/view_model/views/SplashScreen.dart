import 'package:flutter/material.dart';
import 'package:manarah/Features/Splash/presentation/view_model/views/widgets/SplashContent.dart';
import '../../../../Start/presentation/view_model/views/Start.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Start()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("Assets/Splash (1).png"),
            fit: BoxFit.cover,
          ),
        ),
        child: const SplashContent(),
      ),
    );
  }
}
