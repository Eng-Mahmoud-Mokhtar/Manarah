import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AzkarStorage {
  static Future<void> loadUserAzkar(void Function(List<dynamic>) onLoaded) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('userAzkarSections');
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        onLoaded(decoded);
      } catch (e) {
        print('Error decoding userAzkarSections: $e');
      }
    }
  }

  static Future<void> saveUserAzkar(List<Map<String, dynamic>> userAzkarSections) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString('userAzkarSections', jsonEncode(userAzkarSections));
      print('UserAzkarSections saved: $userAzkarSections');
    } catch (e) {
      print('Error saving userAzkarSections: $e');
    }
  }

  static Future<void> pickImage(TextEditingController controller) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final imagePath = picked.path;
        final file = File(imagePath);
        if (await file.exists()) {
          controller.text = imagePath;
          print('Image picked: $imagePath');
        } else {
          throw Exception('Image file does not exist: $imagePath');
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }
}