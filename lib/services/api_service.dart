import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = 'https://api.frankfurter.app';
  final List<String> _currencies = ['USD', 'EUR', 'JPY', 'GBP', 'AUD'];

  static const String _ratesCacheKey = 'cached_exchange_rates';
  static const String _ratesTimestampKey = 'rates_cache_timestamp';

  Future<Map<String, num>> getExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();

    final String? cachedTimestampStr = prefs.getString(_ratesTimestampKey);
    // renew every 24 hours
    if (cachedTimestampStr != null) {
      final DateTime cachedTimestamp = DateTime.parse(cachedTimestampStr);
      final bool isCacheFresh = DateTime.now().difference(cachedTimestamp).inHours < 24;

      if (isCacheFresh) {
        final String? cachedRatesStr = prefs.getString(_ratesCacheKey);
        if (cachedRatesStr != null) {
          final Map<String, dynamic> cachedMap = json.decode(cachedRatesStr);
          return cachedMap.map((key, value) => MapEntry(key, value as num));
        }
      }
    }

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

      await prefs.setString(_ratesTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_ratesCacheKey, json.encode(flatRates));

      return flatRates;

    } catch (e) {
      throw Exception('Failed to load exchange rates: ${e.toString()}');
    }
  }
}
