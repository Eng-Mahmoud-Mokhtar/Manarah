import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../Core/Const/Colors.dart';
import 'widgets/SurahListen.dart';

class Listen extends StatefulWidget {
  @override
  _ListenState createState() => _ListenState();
}

class _ListenState extends State<Listen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchSurahs();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _filterSurahs();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // جلب قائمة السور الكاملة من API
  Future<void> fetchSurahs() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          setState(() {
            _surahs = List<Map<String, dynamic>>.from(data['data']).map((surah) {
              return {
                'id': surah['number'].toString(),
                'name': surah['name'],
                'number': surah['number'].toString(),
                'ayahCount': surah['numberOfAyahs'],
              };
            }).toList();
            _filteredSurahs = _surahs;
            isLoading = false;
            hasError = false;
          });
        } else {
          throw Exception('No surahs found in API response');
        }
      } else {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching surahs: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _filterSurahs() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredSurahs = _surahs;
      } else {
        _filteredSurahs = _surahs
            .where((surah) =>
        surah['name'].toLowerCase().contains(_searchQuery) ||
            surah['number'].contains(_searchQuery))
            .toList();
      }
    });
  }

  String convertToArabicNumerals(String number) {
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .split('')
        .map((char) => arabicNumerals[int.parse(char)])
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fontBig = width * 0.04;
    final fontNormal = width * 0.035;
    final iconSize = width * 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('Assets/Login.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextFormField(
                    controller: _searchController,
                    style:
                    TextStyle(fontSize: fontNormal, color: Colors.black87),
                    decoration: InputDecoration(
                      prefixIcon:
                      Icon(Icons.search, color: Colors.black54, size: iconSize),
                      hintText: 'ابحث باسم السورة',
                      hintStyle: TextStyle(
                          fontSize: fontNormal, color: Colors.black54),
                      filled: true,
                      fillColor: KprimaryColor.withOpacity(0.1),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: KprimaryColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: KprimaryColor.withOpacity(0.5), width: 1.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.018,
                      ),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: KprimaryColor))
                      : hasError
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'حدث خطأ اثناء التحميل',
                          style: TextStyle(
                            fontSize: fontNormal,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: fetchSurahs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KprimaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('إعادة المحاولة',
                            style: TextStyle(
                              fontSize: fontNormal,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : _filteredSurahs.isEmpty && _searchQuery.isNotEmpty
                      ? Center(
                    child: Text(
                      'لا توجد نتائج مطابقة لبحثك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontNormal,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _filteredSurahs.length,
                    itemBuilder: (context, index) {
                      final surah = _filteredSurahs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          color: KprimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Surah(
                                    surahId: surah['id'],
                                    surahName: surah['name'],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: Text(
                                      convertToArabicNumerals(surah['number']),
                                      style: TextStyle(
                                        fontSize: fontNormal,
                                        color: KprimaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${surah['name']}',
                                          style: TextStyle(
                                            fontSize: fontBig,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Amiri',

                                          ),
                                        ),
                                        Text(
                                          '${convertToArabicNumerals(surah['ayahCount'].toString())} آيات',
                                          style: TextStyle(
                                            fontSize: fontNormal,
                                            color: Colors.white70,
                                            fontFamily: 'Amiri',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



