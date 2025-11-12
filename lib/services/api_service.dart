import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = 'https://api.frankfurter.app';
  final List<String> _currencies = ['USD', 'EUR', 'JPY', 'GBP', 'AUD'];

  Future<Map<String, num>> getExchangeRates() async {
    final Map<String, num> flatRates = {};
    
    try {
      for (String currency in _currencies) {
        final String url = '$_baseUrl/latest?from=$currency&to=IDR';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final rates = data['rates'];
          
          if (rates != null && rates['IDR'] != null) {
            flatRates[currency] = rates['IDR'];
          }
        } else {
          print('Failed to load rate for $currency: Status Code ${response.statusCode}');
        }
      }

      if (flatRates.isEmpty) {
        throw Exception('Failed to load any exchange rates');
      }

      return flatRates;

    } catch (e) {
      throw Exception('Failed to load exchange rates: ${e.toString()}');
    }
  }
}
