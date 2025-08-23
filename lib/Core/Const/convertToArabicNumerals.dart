String convertToArabicNumerals(int number) {
  final arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((e) => arabicNumbers[int.parse(e)]).join();
}