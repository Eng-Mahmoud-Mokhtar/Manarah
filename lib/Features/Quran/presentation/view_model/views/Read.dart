import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:manarah/Features/Quran/presentation/view_model/views/widgets/surahNames.dart';
import '../../../../../Core/Const/Colors.dart';
import '../../../../../Core/Const/convertToArabicNumerals.dart';
import 'widgets/SurahRead.dart';

class Read extends StatefulWidget {
  const Read({super.key});

  @override
  State<Read> createState() => _ReadState();
}

class _ReadState extends State<Read> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _surahs = [];
  List<Map<String, dynamic>> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
        _filterSurahs();
      });
    });
    _loadSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    final String jsonString =
    await DefaultAssetBundle.of(context).loadString('Assets/data.json');
    final List<dynamic> verses = json.decode(jsonString);
    final Map<int, List<Map<String, dynamic>>> surahToVerses = {};

    for (var verse in verses) {
      int surah = verse['surah_number'];
      if (!surahToVerses.containsKey(surah)) {
        surahToVerses[surah] = [];
      }
      surahToVerses[surah]!.add(verse);
    }

    final List<Map<String, dynamic>> surahs = surahToVerses.keys.map((surahNumber) {
      return {
        'number': surahNumber,
        'name': surahNames[surahNumber] ?? 'غير معروف',
        'ayahCount': surahToVerses[surahNumber]!.length,
        'verses': surahToVerses[surahNumber]!
      };
    }).toList()
      ..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));

    setState(() {
      _surahs = surahs;
      _filteredSurahs = surahs;
    });
  }

  void _filterSurahs() {
    const List<String> surahPrefixes = ['سورة', 'سوره'];
    if (_searchQuery.isEmpty) {
      _filteredSurahs = _surahs;
    } else {
      String query = _searchQuery;
      bool prefixFound = false;

      for (String prefix in surahPrefixes) {
        if (_searchQuery.startsWith(prefix)) {
          prefixFound = true;
          query = _searchQuery.substring(prefix.length).trim().toLowerCase();
          if (query.isEmpty) {
            _filteredSurahs = [];
            return;
          }
          break;
        }
      }

      _filteredSurahs = _surahs.where((surah) {
        return (surah['name'] as String).toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fontBig = width * 0.04;
    final fontNormal = width * 0.035;
    final iconSize = width * 0.05;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('Assets/Login.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextFormField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                    _filterSurahs();
                  });
                },
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
              child: _surahs.isEmpty
                  ? const Center(
                  child: CircularProgressIndicator(color: KprimaryColor))
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                              builder: (context) => SurahPage(
                                surahNumber: surah['number'],
                                surahName: surah['name'],
                                verses: surah['verses'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                                  convertToArabicNumerals(
                                      surah['number']),
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
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'سورة ${surah['name']}',
                                      style: TextStyle(
                                        fontSize: fontBig,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Amiri',
                                      ),
                                    ),
                                    Text(
                                      '${convertToArabicNumerals(surah['ayahCount'])} آيات',
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
      ],
    );
  }
}