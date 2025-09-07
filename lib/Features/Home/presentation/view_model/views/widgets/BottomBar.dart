import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:manarah/Features/Home/presentation/view_model/views/HomeBody.dart';
import '../../../../../Azkar/presentation/view_model/views/Azkar.dart';
import '../../../../../Prayer/presentation/view_model/views/PrayerTimes.dart';
import '../../../../../Qubla/presentation/view_model/views/Qubla.dart';
import '../../../../../../Core/Const/Colors.dart';


// ---------------- BottomNavCubit ----------------
class BottomNavCubit extends Cubit<int> {
  BottomNavCubit({required int initialIndex}) : super(initialIndex);

  void setIndex(int index) async {
    emit(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_page', index);
  }
}


class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  final List<Widget> pages = [
    HomeBody(),
    const PrayerTimes(),
    Qiblah(),
    const AzkarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: BlocBuilder<BottomNavCubit, int>(
        builder: (context, currentIndex) {
          return IndexedStack(index: currentIndex, children: pages);
        },
      ),
      bottomNavigationBar: BlocBuilder<BottomNavCubit, int>(
        builder: (context, currentIndex) {
          return BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => context.read<BottomNavCubit>().setIndex(index),
            backgroundColor: KprimaryColor,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: width * 0.03,
            unselectedFontSize: width * 0.03,
            showUnselectedLabels: true,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.5),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                label: 'الرئيسية',
                icon: Image.asset(
                  'Assets/Group 4.png',
                  width: width * 0.05,
                  height: width * 0.05,
                  color: currentIndex == 0
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
              BottomNavigationBarItem(
                label: 'الصلاة',
                icon: Image.asset(
                  'Assets/012-prayer 1.png',
                  width: width * 0.05,
                  height: width * 0.05,
                  color: currentIndex == 1
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
              BottomNavigationBarItem(
                label: 'القبلة',
                icon: Image.asset(
                  'Assets/explore.png',
                  width: width * 0.05,
                  height: width * 0.05,
                  color: currentIndex == 2
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
              BottomNavigationBarItem(
                label: 'الأذكار',
                icon: Image.asset(
                  'Assets/fluent-emoji-high-contrast_prayer-beads.png',
                  width: width * 0.05,
                  height: width * 0.05,
                  color: currentIndex == 3
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

