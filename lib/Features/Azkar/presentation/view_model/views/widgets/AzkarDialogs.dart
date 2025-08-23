import 'dart:io';
import 'package:flutter/material.dart';
import 'package:manarah/Core/Const/Colors.dart';
import 'AzkarStorage.dart';

class AzkarDialogs {
  static void showCustomMessage(BuildContext context, String message, {double? width}) {
    final screenWidth = width ?? MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SecoundColor,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void addAzkar(
      BuildContext context,
      Future<void> Function(Map<String, dynamic>) addAzkarSectionCallback,
      Future<void> Function() saveUserAzkar,
      ) {
    final width = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        content: SizedBox(
          width: width * 0.95,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إضافة ذكر',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: KprimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showTextAzkarDialog(context, addAzkarSectionCallback, saveUserAzkar);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KprimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'كتابة',
                  style: TextStyle(color: Colors.white, fontSize: width * 0.035),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showImageAzkarDialog(context, addAzkarSectionCallback, saveUserAzkar);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KprimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'صورة',
                  style: TextStyle(color: Colors.white, fontSize: width * 0.035),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showTextAzkarDialog(
      BuildContext context,
      Future<void> Function(Map<String, dynamic>) addAzkarSectionCallback,
      Future<void> Function() saveUserAzkar,
      ) {
    final width = MediaQuery.of(context).size.width;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final countController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        content: SizedBox(
          width: width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'كتابة ذكر جديد',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.bold, color: KprimaryColor),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 40),
                  child: TextField(
                    style: TextStyle(fontSize: width * 0.035, color: Colors.black),
                    controller: titleController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'عنوان الذكر',
                      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.035),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: KprimaryColor, width: 2)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  style: TextStyle(fontSize: width * 0.035, color: Colors.black),
                  controller: contentController,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'محتوي الذكر',
                    labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.035),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: KprimaryColor, width: 2)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 40),
                  child: TextField(
                    style: TextStyle(fontSize: width * 0.035, color: Colors.black),
                    controller: countController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'العدد',
                      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.035),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: KprimaryColor, width: 2)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    final count = int.tryParse(countController.text.trim()) ?? 1;

                    if (title.isNotEmpty && content.isNotEmpty) {
                      addAzkarSectionCallback({
                        'title': title,
                        'data': [
                          {'name': title, 'text': content, 'count': count, 'image': null}
                        ],
                      });
                      saveUserAzkar();
                      Navigator.pop(context);
                    } else {
                      showCustomMessage(context, 'يرجى إدخال البيانات كاملة', width: width);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: KprimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 40)),
                  child: Text('حفظ', style: TextStyle(color: Colors.white, fontSize: width * 0.035)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: width * 0.035)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void showImageAzkarDialog(
      BuildContext context,
      Future<void> Function(Map<String, dynamic>) addAzkarSectionCallback,
      Future<void> Function() saveUserAzkar,
      ) {
    final width = MediaQuery.of(context).size.width;
    final titleController = TextEditingController();
    final imageController = TextEditingController();
    final countController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          content: SizedBox(
            width: width * 0.95,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إضافة صورة للذكر',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.bold, color: KprimaryColor),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await AzkarStorage.pickImage(imageController);
                      setStateDialog(() {});
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: KprimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 40)),
                    child: Text('اختيار صورة', style: TextStyle(color: Colors.white, fontSize: width * 0.035)),
                  ),
                  if (imageController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final file = File(imageController.text);
                        if (file.existsSync()) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(file, height: 150, width: double.infinity, fit: BoxFit.cover),
                          );
                        }
                        return const Text('الصورة غير متوفرة');
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 40),
                    child: TextField(
                      style: TextStyle(fontSize: width * 0.035, color: Colors.black),
                      controller: titleController,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'عنوان الذكر',
                        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.035),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: KprimaryColor, width: 2)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 40),
                    child: TextField(
                      style: TextStyle(fontSize: width * 0.035, color: Colors.black),
                      controller: countController,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'العدد',
                        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.035),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: KprimaryColor, width: 2)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final image = imageController.text.trim();
                      final count = int.tryParse(countController.text.trim()) ?? 1;

                      if (title.isNotEmpty && image.isNotEmpty) {
                        final file = File(image);
                        if (file.existsSync()) {
                          addAzkarSectionCallback({
                            'title': title,
                            'data': [
                              {'name': title, 'text': null, 'count': count, 'image': image}
                            ],
                          });
                          saveUserAzkar();
                          Navigator.pop(context);
                        } else {
                          showCustomMessage(context, 'الصورة غير متوفرة، حاول اختيار صورة أخرى', width: width);
                        }
                      } else {
                        showCustomMessage(context, 'يرجى إدخال العنوان والصورة', width: width);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: KprimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 40)),
                    child: Text('حفظ', style: TextStyle(color: Colors.white, fontSize: width * 0.035)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: width * 0.035)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
