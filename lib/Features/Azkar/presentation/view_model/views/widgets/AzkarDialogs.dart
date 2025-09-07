import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../Core/Const/Colors.dart';
import 'AzkarStorage.dart';

class AzkarDialogs {
  static void addAzkar(
      BuildContext context,
      Future<void> Function(Map<String, dynamic>) addAzkarSectionCallback,
      Future<void> Function() saveUserAzkar,
      ) {
    final width = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  showTextAzkarDialog(
                      context, addAzkarSectionCallback, saveUserAzkar);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KprimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'كتابة',
                  style: TextStyle(
                      color: Colors.white, fontSize: width * 0.035),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showImageAzkarDialog(
                      context, addAzkarSectionCallback, saveUserAzkar);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KprimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'صورة',
                  style: TextStyle(
                      color: Colors.white, fontSize: width * 0.035),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // كتابة الذكر
  static void showTextAzkarDialog(
      BuildContext context,
      Future<void> Function(Map<String, dynamic>) addAzkarSectionCallback,
      Future<void> Function() saveUserAzkar,
      ) {
    final width = MediaQuery.of(context).size.width;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final countController = TextEditingController(text: "1");

    String? titleError;
    String? contentError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          content: SizedBox(
            width: width * 0.95,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'كتابة ذكر جديد',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: KprimaryColor),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                        fontSize: width * 0.035, color: Colors.black),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'عنوان الذكر',
                      errorText: titleError,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    style: TextStyle(
                        fontSize: width * 0.035, color: Colors.black),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'محتوي الذكر',
                      errorText: contentError,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countController,
                    style: TextStyle(
                        fontSize: width * 0.035, color: Colors.black),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'العدد',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final content = contentController.text.trim();
                final count =
                    int.tryParse(countController.text.trim()) ?? 1;

                setStateDialog(() {
                  titleError =
                  title.isEmpty ? 'يرجى إدخال العنوان' : null;
                  contentError =
                  content.isEmpty ? 'يرجى إدخال المحتوى' : null;
                });

                if (titleError == null && contentError == null) {
                  addAzkarSectionCallback({
                    'title': title,
                    'data': [
                      {
                        'name': title,
                        'text': content,
                        'count': count,
                        'image': null
                      }
                    ],
                  });
                  saveUserAzkar();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: KprimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 40)),
              child: Text('حفظ',
                  style: TextStyle(
                      color: Colors.white, fontSize: width * 0.035)),
            ),
          ],
        ),
      ),
    );
  }

  // إضافة صورة
  static void showImageAzkarDialog(
      BuildContext context,
      Future<void> Function(Map<String, dynamic>) addAzkarSectionCallback,
      Future<void> Function() saveUserAzkar,
      ) {
    final width = MediaQuery.of(context).size.width;
    final titleController = TextEditingController();
    final imageController = TextEditingController();
    final countController = TextEditingController(text: "1");

    String? titleError;
    String? imageError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          content: SizedBox(
            width: width * 0.95,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إضافة صورة للذكر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: KprimaryColor),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await AzkarStorage.pickImage(imageController);
                      setStateDialog(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: imageController.text.isEmpty
                          ? Colors.red
                          : KprimaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    child: Text(
                      imageController.text.isEmpty
                          ? 'اضافة صورة'
                          : 'تم اختيار صورة',
                      style: TextStyle(
                          color: Colors.white, fontSize: width * 0.035),
                    ),
                  ),
                  if (imageError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      imageError!,
                      style: TextStyle(
                          color: Colors.red, fontSize: width * 0.03),
                    ),
                  ],
                  if (imageController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final file = File(imageController.text);
                        if (file.existsSync()) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(file,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          );
                        }
                        return const Text('الصورة غير متوفرة');
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                        fontSize: width * 0.035, color: Colors.black),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'عنوان الذكر',
                      errorText: titleError,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countController,
                    style: TextStyle(
                        fontSize: width * 0.035, color: Colors.black),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'العدد',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final image = imageController.text.trim();
                final count =
                    int.tryParse(countController.text.trim()) ?? 1;

                setStateDialog(() {
                  titleError =
                  title.isEmpty ? 'يرجى إدخال العنوان' : null;
                  imageError =
                  image.isEmpty ? 'يرجى اختيار صورة' : null;
                });

                if (titleError == null && imageError == null) {
                  final file = File(image);
                  if (file.existsSync()) {
                    addAzkarSectionCallback({
                      'title': title,
                      'data': [
                        {
                          'name': title,
                          'text': null,
                          'count': count,
                          'image': image
                        }
                      ],
                    });
                    saveUserAzkar();
                    Navigator.pop(context);
                  } else {
                    setStateDialog(() {
                      imageError = 'الصورة غير متوفرة';
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: KprimaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 40)),
              child: Text('حفظ',
                  style: TextStyle(
                      color: Colors.white, fontSize: width * 0.035)),
            ),
          ],
        ),
      ),
    );
  }
}

