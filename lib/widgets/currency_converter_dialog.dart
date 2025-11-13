// lib/widgets/currency_converter_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xpense/services/api_service.dart';

class CurrencyConverterDialog extends StatefulWidget {
  final double accountBalance;
  final String baseCurrency; // e.g., "IDR"

  const CurrencyConverterDialog({
    super.key,
    required this.accountBalance,
    this.baseCurrency = 'IDR',
  });

  @override
  State<CurrencyConverterDialog> createState() => _CurrencyConverterDialogState();
}

class _CurrencyConverterDialogState extends State<CurrencyConverterDialog> {
  final ApiService _apiService = ApiService();
  late TextEditingController _amountController;
  late String _fromCurrency;

  // Daftar mata uang yang ingin Anda gunakan
  final List<String> _allCurrencies = [
    'IDR', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'MYR'
  ];

  // Daftar mata uang target (tidak termasuk 'from')
  List<String> get _targetCurrencies =>
      _allCurrencies.where((c) => c != _fromCurrency).toList();

  Map<String, double>? _conversionRates;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Set nilai awal dari properti widget
    _amountController = TextEditingController(
      text: widget.accountBalance.toStringAsFixed(0),
    );
    _fromCurrency = widget.baseCurrency;

    // Langsung panggil API saat dialog dibuka
    _fetchRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _conversionRates = null;
    });

    try {
      final rates = await _apiService.getRatesForBaseCurrency(
        _fromCurrency,
        _targetCurrencies,
      );

      setState(() {
        _conversionRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convert Balance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Amount:"),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown untuk mata uang 'FROM'
                DropdownButton<String>(
                  value: _fromCurrency,
                  items: _allCurrencies.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _fromCurrency = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(width: 10),
                // Text field untuk jumlah
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchRates,
                child: Text(_isLoading ? 'Converting...' : 'Convert'),
              ),
            ),
            const Divider(height: 24),
            _buildResults(), // Widget untuk menampilkan hasil
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  // Widget helper untuk menampilkan hasil
  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Tampilkan jika _conversionRates sudah ada (setelah fetch sukses)
    if (_conversionRates != null) {
      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      final String formattedBaseAmount = NumberFormat.currency(
          symbol: '$_fromCurrency ',
          decimalDigits: 0,
          locale: 'id_ID'
      ).format(amount);

      final List<Widget> rateWidgets = _conversionRates!.entries.map((entry) {
        final String currencyCode = entry.key;
        final double rate = entry.value;
        final double convertedAmount = amount * rate;

        // Formatter untuk mata uang asing
        final NumberFormat foreignFormatter = NumberFormat.currency(
          locale: 'en_US', // Locale umum untuk format desimal
          symbol: '', // Simbol akan ditambahkan manual
          decimalDigits: 2,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyCode,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                foreignFormatter.format(convertedAmount),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$formattedBaseAmount is worth:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 16),
          ...rateWidgets,
        ],
      );
    }

    // State awal sebelum menekan 'Convert'
    return const Center(child: Text('Press Convert to see rates.'));
  }
}