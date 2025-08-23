import 'package:flutter/material.dart';
import 'package:manarah/Features/Start/presentation/view_model/views/widgets/StartBackgroundImage.dart';
import 'package:manarah/Features/Start/presentation/view_model/views/widgets/StartBottomScreen.dart';

class Start extends StatelessWidget {
  const Start({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          StartBackgroundImage(size: size),
          StartBottomScreen(size: size),
        ],
      ),
    );
  }
}




