import 'package:flutter/material.dart';

import '../../../../../../Core/Const/Colors.dart';
import '../../../../../Home/presentation/view_model/views/Home.dart';

class StartBottomScreen extends StatelessWidget {
  final Size size;
  const StartBottomScreen({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.06,
            ),
            decoration: const BoxDecoration(
              color: SecoundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'منارة تضيء قلبك ودربك',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.02),
                Text(
                  'رفيقك اليومي الذي يمنحك النور والسكينة أينما كنت .',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: size.height * 0.05),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KprimaryColor,
                      padding: EdgeInsets.symmetric(vertical: size.width * 0.03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ابدأ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -7,
            left: 3,
            child: Image.asset(
              color: Color(0xffFACC15),
              "Assets/left.png",
              width: size.width * 0.15,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: -7,
            right: 3,
            child: Image.asset(
              color: Color(0xffFACC15),
              "Assets/Right.png",
              width: size.width * 0.15,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
