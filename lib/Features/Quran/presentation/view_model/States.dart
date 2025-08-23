import 'package:equatable/equatable.dart';

abstract class SurahState extends Equatable {
  const SurahState();
  @override
  List<Object?> get props => [];
}

class SurahInitial extends SurahState {}

class SurahLoading extends SurahState {}

class SurahError extends SurahState {
  final String message;
  const SurahError({required this.message});
  @override
  List<Object?> get props => [message];
}

class SurahLoaded extends SurahState {
  final List<Map<String, dynamic>> reciters;
  final int? playingIndex;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isLoading;

  const SurahLoaded({
    required this.reciters,
    this.playingIndex,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.isLoading,
  });

  SurahLoaded copyWith({
    List<Map<String, dynamic>>? reciters,
    int? playingIndex,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isLoading,
  }) {
    return SurahLoaded(
      reciters: reciters ?? this.reciters,
      playingIndex: playingIndex ?? this.playingIndex,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props =>
      [reciters, playingIndex, duration, position, isPlaying, isLoading];
}