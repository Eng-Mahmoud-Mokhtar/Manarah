import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'States.dart';

class SurahCubit extends Cubit<SurahState> {
  final String surahId;
  final Dio dio;
  late final AudioPlayer _player;
  List<String> ayahAudioUrls = [];

  SurahCubit({required this.surahId, Dio? dio})
      : dio = dio ?? Dio(),
        super(SurahInitial()) {
    _player = AudioPlayer();
    _listenPlayer();
    fetchReciters();
  }

  /// مراقبة حالة اللاعب وتحديث الحالة
  void _listenPlayer() {
    _player.positionStream.listen((p) {
      if (state is SurahLoaded) {
        final s = state as SurahLoaded;
        emit(s.copyWith(position: p));
      }
    });

    _player.durationStream.listen((d) {
      if (state is SurahLoaded) {
        final s = state as SurahLoaded;
        emit(s.copyWith(duration: d ?? Duration.zero));
      }
    });

    _player.playerStateStream.listen((playerState) {
      if (state is SurahLoaded) {
        final s = state as SurahLoaded;

        if (playerState.processingState == ProcessingState.completed) {
          emit(s.copyWith(
            isPlaying: false,
            isLoading: false,
            position: s.duration,
          ));
          return;
        }

        emit(s.copyWith(
          isPlaying: playerState.playing,
          isLoading: playerState.processingState == ProcessingState.loading ||
              playerState.processingState == ProcessingState.buffering,
        ));
      }
    });
  }

  /// جلب قائمة القراء
  Future<void> fetchReciters() async {
    emit(SurahLoading());
    try {
      final response = await dio
          .get('https://api.alquran.cloud/v1/edition?format=audio')
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.data;
        final reciters = List<Map<String, dynamic>>.from(data['data'])
            .where((reciter) =>
        reciter['format'] == 'audio' &&
            reciter['type'] == 'versebyverse')
            .toList();

        emit(SurahLoaded(
          reciters: reciters,
          playingIndex: null,
          duration: Duration.zero,
          position: Duration.zero,
          isPlaying: false,
          isLoading: false,
        ));
      } else {
        emit(SurahError(message: 'فشل تحميل قائمة القراء'));
      }
    } catch (e) {
      emit(SurahError(message: e.toString()));
    }
  }

  /// جلب رابط كامل للسورة
  Future<String?> getFullSurahAudioUrl(String editionIdentifier) async {
    final url =
        'https://cdn.alquran.cloud/media/audio/full/$editionIdentifier/$surahId.mp3';
    try {
      final response = await dio.head(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return url;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// جلب روابط آيات السورة
  Future<List<String>> getAyahAudioUrls(String editionIdentifier) async {
    try {
      final response = await dio
          .get('https://api.alquran.cloud/v1/surah/$surahId/$editionIdentifier')
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = response.data;
        final ayahs = data['data']['ayahs'] as List;

        // تصفية أي nulls والتحويل إلى List<String>
        return ayahs
            .map((ayah) => ayah['audio'])
            .whereType<String>()
            .toList();
      } else {
        debugPrint('Failed to load ayah audio URLs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception in getAyahAudioUrls: $e');
      return [];
    }
  }

  /// تشغيل أو إيقاف الصوت
  Future<void> playAudio(String editionIdentifier, int index) async {
    if (state is! SurahLoaded) return;
    final s = state as SurahLoaded;

    try {
      if (s.playingIndex == index) {
        if (s.isPlaying) {
          await _player.pause();
          emit(s.copyWith(isPlaying: false));
        } else {
          await _player.play();
          emit(s.copyWith(isPlaying: true));
        }
        return;
      }

      await _player.stop();
      emit(s.copyWith(
        isLoading: true,
        playingIndex: index,
        isPlaying: false,
        duration: Duration.zero,
        position: Duration.zero,
      ));

      String? fullSurahUrl = await getFullSurahAudioUrl(editionIdentifier);
      if (fullSurahUrl != null) {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(fullSurahUrl)));
        ayahAudioUrls = [fullSurahUrl];
      } else {
        ayahAudioUrls = await getAyahAudioUrls(editionIdentifier);
        if (ayahAudioUrls.isEmpty) {
          emit(s.copyWith(isLoading: false, playingIndex: null));
          return;
        }
        await _player.setAudioSource(
          ConcatenatingAudioSource(
            children: ayahAudioUrls
                .map((url) => AudioSource.uri(Uri.parse(url)))
                .toList(),
          ),
        );
      }

      emit(s.copyWith(
        isLoading: false,
        isPlaying: true,
        playingIndex: index,
        duration: _player.duration ?? Duration.zero,
        position: Duration.zero,
      ));

      await _player.play();
    } catch (e) {
      debugPrint('Exception in playAudio: $e');
      emit(s.copyWith(isLoading: false, playingIndex: null));
    }
  }

  /// الانتقال لموضع محدد
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// تنظيف اللاعب
  void disposePlayer() {
    _player.stop();
    _player.dispose();
  }

  @override
  Future<void> close() {
    _player.dispose();
    return super.close();
  }
}
