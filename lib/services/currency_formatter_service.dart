import 'package:intl/intl.dart';

class CurrencyFormatterService {
  static final Map<String, (String, int)> _currencyFormatInfo = {
    'IDR': ('Rp ', 0),
    'USD': ('\$', 2),
    'EUR': ('€', 2),
    'JPY': ('¥', 0),
    'GBP': ('£', 2),
    'AUD': ('A\$', 2),
    'SGD': ('S\$', 2),
    'MYR': ('RM', 2),
  };

  static String format(double amount, String currencyCode) {
    final (String symbol, int decimals) =
        _currencyFormatInfo[currencyCode] ?? (currencyCode, 2);

    final String locale = (decimals == 0) ? 'id_ID' : 'en_US';

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimals,
    );

    return formatter.format(amount);
  }

  static String getSymbol(String currencyCode) {
    final (String symbol, int _) =
        _currencyFormatInfo[currencyCode] ?? (currencyCode, 2);
    return symbol.trim();
  }
}