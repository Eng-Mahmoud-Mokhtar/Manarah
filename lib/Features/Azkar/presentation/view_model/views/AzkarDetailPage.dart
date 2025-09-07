import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../Core/Const/Colors.dart';
import 'dart:convert';
import 'dart:io';

class AzkarDetailPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> azkarList;

  const AzkarDetailPage({
    super.key,
    required this.title,
    required this.azkarList,
  });

  @override
  State<AzkarDetailPage> createState() => _AzkarDetailPageState();
}

class _AzkarDetailPageState extends State<AzkarDetailPage> {
  late List<int> countsOriginal;
  late List<int> countsCurrent;

  @override
  void initState() {
    super.initState();
    countsOriginal = widget.azkarList.map((e) {
      final count = e['count'];
      if (count is int) return count;
      if (count is String) return int.tryParse(count) ?? 1;
      return 1;
    }).toList();

    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.title;
    final savedData = prefs.getString(key);
    if (savedData != null) {
      final List<dynamic> savedList = jsonDecode(savedData);
      countsCurrent = savedList.map((e) => e as int).toList();
    } else {
      countsCurrent = List<int>.from(countsOriginal);
    }
    setState(() {});
  }

  Future<void> _saveCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final key = widget.title;
    prefs.setString(key, jsonEncode(countsCurrent));
  }

  void _decreaseCount(int index) {
    if (countsCurrent[index] > 0) {
      setState(() {
        countsCurrent[index]--;
      });
      _saveCounts();
    }
  }

  void _resetCount(int index) {
    setState(() {
      countsCurrent[index] = countsOriginal[index];
    });
    _saveCounts();
  }

  void _resetAll() {
    setState(() {
      countsCurrent = List<int>.from(countsOriginal);
    });
    _saveCounts();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontBig = width * 0.04;
    final iconSize = width * 0.05;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: KprimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: iconSize),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: fontBig,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white, size: width * 0.08),
            tooltip: 'إعادة جميع الأذكار',
            onPressed: _resetAll,
          ),
        ],
      ),
      body: countsCurrent.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("Assets/Login.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ListView.builder(
            padding: EdgeInsets.all(width * 0.04),
            itemCount: widget.azkarList.length,
            itemBuilder: (context, index) {
              final item = widget.azkarList[index];
              final count = countsCurrent[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(width * 0.06),
                      decoration: BoxDecoration(
                        color: SecoundColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: item['image'] != null && item['image'].isNotEmpty
                                ? Builder(
                              builder: (context) {
                                final file = File(item['image']);
                                if (file.existsSync()) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImagePage(imagePath: item['image']),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        file,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Text(
                                            'فشل في تحميل الصورة',
                                            style: TextStyle(
                                              fontSize: fontBig,
                                              color: Colors.red,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  return Text(
                                    'الصورة غير متوفرة',
                                    style: TextStyle(
                                      fontSize: fontBig,
                                      color: Colors.red,
                                    ),
                                  );
                                }
                              },
                            )
                                : Text(
                              item['text'] ?? '',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: fontBig,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AmiriQuran-Regular',
                                height: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => _decreaseCount(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: KprimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                    size: iconSize * 1.5,
                                  ),
                                ),
                              ),
                              Text(
                                count > 0 ? '$count' : 'انتهى',
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _resetCount(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: KprimaryColor, width: 2),
                                  ),
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Icon(
                                    Icons.refresh,
                                    color: KprimaryColor,
                                    size: iconSize * 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Image.asset(
                        'Assets/Right.png',
                        width: iconSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Image.asset(
                        'Assets/left.png',
                        width: iconSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// صفحة عرض الصورة بالحجم الكامل مع إمكانية التكبير
class FullScreenImagePage extends StatelessWidget {
  final String imagePath;

  const FullScreenImagePage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: file.existsSync()
            ? InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(file),
        )
            : const Text(
          'الصورة غير متوفرة',
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      ),
    );
  }
}
