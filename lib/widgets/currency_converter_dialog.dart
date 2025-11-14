import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xpense/viewmodels/main_viewmodel.dart';

class CurrencyConverterSheet extends StatefulWidget {
  final double accountBalance;
  final String baseCurrency;

  const CurrencyConverterSheet({
    super.key,
    required this.accountBalance,
    this.baseCurrency = 'IDR',
  });

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  late TextEditingController _amountController;
  late String _fromCurrency;

  final List<String> _allCurrencies = [
    'IDR', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD', 'MYR'
  ];

  final Map<String, (String, int)> _currencyFormatInfo = {
    'IDR': ('Rp ', 0),
    'USD': ('\$', 2),
    'EUR': ('€', 2),
    'JPY': ('¥', 0),
    'GBP': ('£', 2),
    'AUD': ('A\$', 2),
    'SGD': ('S\$', 2),
    'MYR': ('RM', 2),
  };

  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.baseCurrency;

    final formatter = NumberFormat.decimalPattern(
        _fromCurrency == 'IDR' || _fromCurrency == 'JPY' ? 'id_ID' : 'en_US');
    _amountController = TextEditingController(
      text: formatter.format(widget.accountBalance),
    );

    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;
    final hintColor = Theme.of(context).hintColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final inputFillColor = isDarkMode
        ? Theme.of(context).inputDecorationTheme.fillColor
        : Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Convert Balance',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Text(
            "Amount",
            style: textTheme.labelMedium,
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _fromCurrency,
                    items: _allCurrencies.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _fromCurrency = newValue;
                        });
                      }
                    },
                    iconEnabledColor: hintColor,
                  ),
                ),
              ),
              hintText: "Enter amount",
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildResults(textTheme, primaryColor, hintColor),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResults(TextTheme textTheme, Color primaryColor, Color? hintColor) {
    final viewModel = context.watch<MainViewModel>();
    final rates = viewModel.allConversionRates;

    if (rates.isEmpty && viewModel.isCalculatingTotal) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (rates.isEmpty && viewModel.calculationError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${viewModel.calculationError}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final String cleanAmountText =
    _amountController.text.replaceAll('.', '').replaceAll(',', '');
    final double amount = double.tryParse(cleanAmountText) ?? 0.0;

    final (String baseSymbol, int baseDecimals) =
        _currencyFormatInfo[_fromCurrency] ?? (_fromCurrency, 2);

    final String formattedBaseAmount = NumberFormat.currency(
      symbol: baseSymbol,
      decimalDigits: baseDecimals,
      locale: 'id_ID',
    ).format(amount);

    final double? fromRate = (_fromCurrency == 'IDR') ? 1.0 : rates[_fromCurrency];

    if (fromRate == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: Rate for $_fromCurrency not found in cache.',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$formattedBaseAmount is worth:',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView(
            shrinkWrap: true,
            children: _targetCurrencies.map((currencyCode) {
              final double? toRate = (currencyCode == 'IDR') ? 1.0 : rates[currencyCode];
              if (toRate == null) return const SizedBox.shrink();

              final double crossRate = toRate / fromRate;
              final double convertedAmount = amount * crossRate;

              final (String symbol, int decimals) =
                  _currencyFormatInfo[currencyCode] ?? (currencyCode, 2);

              final NumberFormat foreignFormatter = NumberFormat.currency(
                locale: 'en_US',
                symbol: symbol,
                decimalDigits: decimals,
              );

              final oneUnitRate = NumberFormat.currency(
                locale: 'en_US',
                symbol: symbol,
                decimalDigits: 6,
              ).format(crossRate);

              return ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                title: Text(
                  foreignFormatter.format(convertedAmount),
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                leading: SizedBox(
                  width: 40,
                  child: Text(
                    currencyCode,
                    style: textTheme.bodyLarge?.copyWith(
                      color: textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                subtitle: Text(
                  '1 $_fromCurrency = $oneUnitRate',
                  style: textTheme.bodySmall
                      ?.copyWith(color: hintColor),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  List<String> get _targetCurrencies {
    return _allCurrencies.where((c) => c != _fromCurrency).toList();
  }
}