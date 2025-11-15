import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = 'https://api.frankfurter.app';

  static const String _ratesCacheKeyPrefix = 'cached_all_rates_';
  static const String _ratesTimestampKeyPrefix = 'rates_cache_timestamp_';
  static const String kAutoUpdateKey = 'isAutoUpdateEnabled';

  Future<Map<String, double>> getRatesForBaseCurrency(
      String fromCurrency, List<String> toCurrencies) async {

    if (toCurrencies.isEmpty) {
      return {};
    }

    final String toList = toCurrencies.join(',');
    final String url = '$_baseUrl/latest?from=$fromCurrency&to=$toList';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['rates'] != null && data['rates'] is Map) {
          final rates = data['rates'] as Map<String, dynamic>;

          return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        } else {
          throw Exception('Format data rates tidak valid');
        }
      } else {
        throw Exception('Gagal memuat kurs (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal memuat kurs: ${e.toString()}');
    }
  }

  Future<Map<String, double>> getAllRates(String fromCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = '$_ratesCacheKeyPrefix$fromCurrency';
    final String timestampKey = '$_ratesTimestampKeyPrefix$fromCurrency';

    final bool isAutoUpdateEnabled = prefs.getBool(kAutoUpdateKey) ?? true;

    final String? cachedTimestampStr = prefs.getString(timestampKey);
    final String? cachedRatesStr = prefs.getString(cacheKey);

    if (cachedTimestampStr != null && cachedRatesStr != null) {
      final DateTime cachedTimestamp = DateTime.parse(cachedTimestampStr);
      final bool isCacheFresh = DateTime.now().difference(cachedTimestamp).inHours < 24;

      if (isCacheFresh || !isAutoUpdateEnabled) {
        final Map<String, dynamic> cachedMap = json.decode(cachedRatesStr);
        return cachedMap.map((key, value) => MapEntry(key, value as double));
      }
    }

    final String url = '$_baseUrl/latest?from=$fromCurrency';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rates'] != null && data['rates'] is Map) {
          final rates = data['rates'] as Map<String, dynamic>;
          final Map<String, double> doubleRates = rates.map((key, value) => MapEntry(key, (value as num).toDouble()));

          await prefs.setString(timestampKey, DateTime.now().toIso8601String());
          await prefs.setString(cacheKey, json.encode(doubleRates));

          return doubleRates;
        } else {
          throw Exception('Format data rates tidak valid');
        }
      } else {
        throw Exception('Gagal memuat kurs (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal memuat kurs: ${e.toString()}');
    }
  }
}