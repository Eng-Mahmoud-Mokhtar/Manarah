import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manarah/Features/Azkar/presentation/view_model/views/AzkarDetailPage.dart';
import 'package:manarah/Features/Azkar/presentation/view_model/views/widgets/AzkarDialogs.dart';
import 'package:manarah/Features/Azkar/presentation/view_model/views/widgets/azkarSections.dart';
import 'package:manarah/Features/Home/presentation/view_model/views/Home.dart';
import '../../../../../Core/Const/Colors.dart';
import '../azkar_cubit.dart';

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

    return BlocProvider(
      create: (context) => AzkarCubit()..loadUserAzkar(),
      child: Builder(
        builder: (context) => Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              image: DecorationImage(
                image: AssetImage('Assets/Login.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                AppBar(
                  backgroundColor: KprimaryColor,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () {
                      context.read<BottomNavCubit>().setIndex(0);
                    },
                  ),
                  title: Text(
                    'الأذكار',
                    style: TextStyle(
                      fontSize: fontBig,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        final cubit = context.read<AzkarCubit>();
                        AzkarDialogs.addAzkar(
                          context,
                              (Map<String, dynamic> newSection) async {
                            cubit.addAzkarSection(newSection);
                          },
                              () async => await cubit.saveUserAzkar(),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: BlocBuilder<AzkarCubit, List<Map<String, dynamic>>>(
                    builder: (context, userAzkarSections) {
                      final allAzkarSections = [...azkarSections, ...userAzkarSections];
                      return ListView.builder(
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: allAzkarSections.length,
                        itemBuilder: (context, index) {
                          final section = allAzkarSections[index];
                          final isUserSection = index >= azkarSections.length;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AzkarDetailPage(
                                    title: section['title'],
                                    azkarList: List<Map<String, dynamic>>.from(section['data']),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                              decoration: BoxDecoration(
                                color: KprimaryColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      section['title'] ?? 'ذكر جديد',
                                      style: TextStyle(
                                        fontSize: fontBig,
                                        fontFamily: 'AmiriQuran-Regular',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: isUserSection
                                        ? () {
                                      context
                                          .read<AzkarCubit>()
                                          .removeAzkarSection(index - azkarSections.length);
                                    }
                                        : null,
                                    icon: Icon(
                                      isUserSection ? Icons.delete : Icons.arrow_forward_ios,
                                      size: fontBig,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
