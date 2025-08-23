import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manarah/Features/Azkar/presentation/view_model/views/widgets/AzkarStorage.dart';

class AzkarCubit extends Cubit<List<Map<String, dynamic>>> {
  AzkarCubit() : super([]);

  Future<void> loadUserAzkar() async {
    await AzkarStorage.loadUserAzkar((decoded) {
      emit(decoded.map((e) => Map<String, dynamic>.from(e)).toList());
    });
  }

  Future<void> saveUserAzkar() async {
    await AzkarStorage.saveUserAzkar(state);
    emit([...state]); // Trigger rebuild
  }

  void addAzkarSection(Map<String, dynamic> section) {
    final updatedSections = [...state, section];
    emit(updatedSections);
  }

  void removeAzkarSection(int index) {
    final updatedSections = [...state];
    updatedSections.removeAt(index);
    emit(updatedSections);
    AzkarStorage.saveUserAzkar(updatedSections);
  }
}