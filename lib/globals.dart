import 'package:intl/intl.dart';

class Globals {
  static List<Map<String, dynamic>> cart = [];

  static String formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    
    num parsedNumber;
    if (number is String) {
      parsedNumber = num.tryParse(number) ?? 0;
    } else if (number is num) {
      parsedNumber = number;
    } else {
      parsedNumber = 0;
    }
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(parsedNumber);
  }
}

