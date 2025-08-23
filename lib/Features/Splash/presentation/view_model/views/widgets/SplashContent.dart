import 'package:flutter/material.dart';
import '../../../../../../Core/Const/Colors.dart';
import '../../../../../../Core/Const/Images.dart';

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = screenWidth * 0.4;

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            KprimaryImage,
            width: imageSize,
            height: imageSize,
          ),
          SizedBox(height: screenHeight * 0.05),
           Text(
            'جميع الحقوق محفوظة',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: SecoundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
