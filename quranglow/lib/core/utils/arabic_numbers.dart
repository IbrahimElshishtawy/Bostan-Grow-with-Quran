class ArabicNumbers {
  static const Map<String, String> _easternArabicDigits = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  /// Converts any number or numeric string to Arabic-Indic numerals (٠-٩)
  static String convert(dynamic number) {
    if (number == null) return '';
    final input = number.toString();
    return input.split('').map((char) => _easternArabicDigits[char] ?? char).join();
  }
}

extension ArabicNumberExtension on int {
  String toArabic() => ArabicNumbers.convert(this);
}
