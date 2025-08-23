import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../Core/Const/Colors.dart';

class Sebha extends StatefulWidget {
  const Sebha({super.key});

  @override
  State<Sebha> createState() => _SebhaState();
}
class _SebhaState extends State<Sebha> {
  int counter = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }
  Future<void> _loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      counter = prefs.getInt('sebha_counter') ?? 0;
    });
  }
  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('sebha_counter', counter);
  }

  void _incrementCounter() {
    setState(() {
      counter++;
    });
    _saveCounter();
  }

  void _resetCounter() {
    setState(() {
      counter = 0;
    });
    _saveCounter();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: KprimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white,size: iconSize,),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'السبحة',
          style: TextStyle(
            fontSize: fontBig,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'Assets/Login.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Image.asset(
              'Assets/ChatGPT Image Jul 22, 2025, 09_35_48 PM.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: height * 0.02,
            right: width * 0.04,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _resetCounter,
                  child: Container(
                    width: width * 0.14,
                    height: width * 0.14,
                    decoration: BoxDecoration(
                      color: SecoundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: KprimaryColor,
                      size: width * 0.07,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تصفير',
                  style: TextStyle(
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.bold,
                    color: KprimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$counter',
                  style: TextStyle(
                    fontSize: height * 0.07,
                    fontWeight: FontWeight.bold,
                    color:Colors.black,
                  ),
                ),
                SizedBox(height: height * 0.04),
                GestureDetector(
                  onTap: _incrementCounter,
                  child: Container(
                    width: height * 0.12,
                    height: height * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.09),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
