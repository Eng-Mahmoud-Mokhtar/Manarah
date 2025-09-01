import 'package:flutter/material.dart';
import 'package:manarah/Core/Const/Colors.dart';
import 'package:manarah/Features/Quran/presentation/view_model/views/Listen.dart';
import 'package:manarah/Features/Quran/presentation/view_model/views/Read.dart';

class Quran extends StatefulWidget {
  const Quran({super.key});

  @override
  State<Quran> createState() => _QuranState();
}

class _QuranState extends State<Quran> {

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: KprimaryColor,
            elevation: 0,
            title: Text(
              'القرآن الكريم',
              style: TextStyle(
                fontSize: fontBig,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: iconSize),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'قراءة'),
                Tab(text: 'استماع'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Read(),
              Listen()
            ],
          ),
        ),
      ),
    );
  }
}