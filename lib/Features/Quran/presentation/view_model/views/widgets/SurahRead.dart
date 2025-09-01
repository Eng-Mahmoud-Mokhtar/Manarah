import 'package:flutter/material.dart';
import '../../../../../../Core/Const/Colors.dart';

class SurahPage extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final List<Map<String, dynamic>> verses;

  const SurahPage({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.verses,
  });

  String convertToArabicNumerals(int number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicNumerals[int.parse(digit)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.14;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: KprimaryColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: width * 0.05),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'سورة $surahName',
            style: TextStyle(
              fontSize: fontBig,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              top: iconSize / 15,
              left: iconSize / 15,
              right: iconSize / 15,
              child: Container(
                height: 10,
                color: KprimaryColor.withOpacity(0.2),
              ),
            ),
            // الخط الأفقي السفلي
            Positioned(
              bottom: iconSize / 15,
              left: iconSize / 15,
              right: iconSize / 15,
              child: Container(
                height: 10,
                color: KprimaryColor.withOpacity(0.2),
              ),
            ),
            // الخط العمودي الأيسر
            Positioned(
              top: iconSize / 15,
              bottom: iconSize / 15,
              left: iconSize / 15,
              child: Container(
                width: 10,
                color: KprimaryColor.withOpacity(0.2),
              ),
            ),
            // الخط العمودي الأيمن
            Positioned(
              top: iconSize / 15,
              bottom: iconSize / 15,
              right: iconSize / 15,
              child: Container(
                width: 10,
                color: KprimaryColor.withOpacity(0.2),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                'Assets/WhatsApp_Image_2025-06-28_at_9.48.25_AM__4_-removebg-preview 9.png',
                width: iconSize,
                color: KprimaryColor,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'Assets/WhatsApp_Image_2025-06-28_at_9.48.25_AM__4_-removebg-preview 8.png',
                width: iconSize,
                color: KprimaryColor,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                'Assets/WhatsApp_Image_2025-06-28_at_9.48.25_AM__4_-removebg-preview 7.png',
                width: iconSize,
                fit: BoxFit.contain,
                color: KprimaryColor,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'Assets/WhatsApp_Image_2025-06-28_at_9.48.25_AM__4_-removebg-preview 4.png',
                width: iconSize,
                fit: BoxFit.contain,
                color: KprimaryColor,
              ),
            ),

            // قائمة الآيات فوق كل شيء
            Padding(
              padding: EdgeInsets.all(width * 0.1),
              child: ListView(
                children: [
                  Text.rich(
                    TextSpan(
                      children: verses.map<TextSpan>((verse) {
                        return TextSpan(
                          children: [
                            TextSpan(
                              text: verse['content'],
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: fontBig,
                                fontWeight: FontWeight.bold,
                                height: 2.8,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: ' ﴿',
                              style: TextStyle(
                                color: KprimaryColor,
                                fontSize: fontBig,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: convertToArabicNumerals(verse['verse_number']),
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Amiri',
                                fontSize: fontBig,
                              ),
                            ),
                            TextSpan(
                              text: '﴾ ',
                              style: TextStyle(
                                color: KprimaryColor,
                                fontSize: fontBig,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: width * 0.2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}