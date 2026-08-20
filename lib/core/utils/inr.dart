/// Rupee amounts the way people in this market actually write them.
///
/// A budget in this CRM is typed, not picked: "1.2 Cr", "80 L", "45 lakh",
/// "₹4,50,00,000". Both surfaces have to agree on what those mean, and the
/// server already does the formatting for anything it sends — this exists for
/// the one direction the server cannot help with, which is reading what a rep
/// types into a filter before it becomes a query.
abstract final class Inr {
  static const double lakh = 100000;
  static const double crore = 10000000;

  /// The number in "1.2 Cr", or 0 when there is no number in it.
  ///
  /// A bare number is taken at face value: someone who types 4500000 means
  /// forty-five lakh, not forty-five lakh crore. The unit words are the only
  /// multipliers, and "cr"/"crore"/"c" all count — a filter that silently
  /// ignored an unrecognised spelling would search for ₹1.2 and find nothing.
  static double parse(String raw) {
    final String text = raw.toLowerCase().replaceAll(',', '').trim();
    if (text.isEmpty) return 0;

    final RegExpMatch? number = RegExp(r'\d+(\.\d+)?').firstMatch(text);
    if (number == null) return 0;
    final double value = double.tryParse(number[0]!) ?? 0;
    if (value == 0) return 0;

    final String unit = text.substring(number.end).trim();
    if (unit.startsWith('cr') || unit == 'c') return value * crore;
    if (unit.startsWith('l') || unit.startsWith('lac')) return value * lakh;
    return value;
  }

  /// "₹1.2 Cr", "₹80 L", "₹4,500". Matches the server's `format_inr_compact`
  /// closely enough that a chip and a card never disagree about the same
  /// number.
  static String format(double value) {
    if (value <= 0) return '';
    if (value >= crore) {
      final double cr = value / crore;
      return '₹${_trim(cr)} Cr';
    }
    if (value >= lakh) {
      final double l = value / lakh;
      return '₹${_trim(l)} L';
    }
    return '₹${value.round()}';
  }

  /// 1.20 → "1.2", 3.00 → "3". A trailing zero on a price reads as precision
  /// that is not there.
  static String _trim(double value) {
    final String fixed = value.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
