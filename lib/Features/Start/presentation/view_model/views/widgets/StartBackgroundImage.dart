import 'package:flutter/cupertino.dart';

class StartBackgroundImage extends StatelessWidget {
  final Size size;
  const StartBackgroundImage({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Image.asset(
        "Assets/intricate-mosque-building-architecture-with-sky-landscape-clouds.jpg",
        fit: BoxFit.cover,
      ),
    );
  }
}
