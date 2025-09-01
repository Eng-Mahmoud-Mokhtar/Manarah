import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manarah/Core/Const/Colors.dart';
import '../../States.dart';
import '../../SurahCubit.dart';

class Surah extends StatelessWidget {
  final String surahId;
  final String surahName;

  const Surah({super.key, required this.surahId, required this.surahName});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final fontNormal = width * 0.035;

    return BlocProvider(
      create: (_) => SurahCubit(surahId: surahId),
      child: BlocBuilder<SurahCubit, SurahState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              backgroundColor: KprimaryColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: width * 0.05),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                surahName,
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
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('Assets/Login.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SafeArea(
                  child: Builder(
                    builder: (context) {
                      if (state is SurahLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: KprimaryColor),
                        );
                      } else if (state is SurahError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.message, style: TextStyle(fontSize: fontNormal)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => context.read<SurahCubit>().fetchReciters(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: KprimaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'إعادة المحاولة',
                                  style: TextStyle(
                                    fontSize: fontNormal,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (state is SurahLoaded) {
                        final cubit = context.read<SurahCubit>();
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.reciters.length,
                          itemBuilder: (context, index) {
                            final reciter = state.reciters[index];
                            final isPlaying = index == state.playingIndex;

                            return Card(
                              color: KprimaryColor,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: isPlaying ? 8 : 3,
                              child: ListTile(
                                title: Text(
                                  reciter['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontBig,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  reciter['englishName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: fontNormal,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                                trailing: state.isLoading && isPlaying
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : IconButton(
                                  icon: Icon(
                                    (isPlaying && state.isPlaying)
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  onPressed: () => cubit.playAudio(
                                    reciter['identifier'],
                                    index,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
