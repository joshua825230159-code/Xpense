import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'currency_formatter_service.dart';

class ExportService {

  List<List<dynamic>> _generateLedger(
      Account account, List<Transaction> transactions, bool forCsv) {

    double openingBalance = account.balance;
    for (var transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        openingBalance -= transaction.amount;
      } else {
        openingBalance += transaction.amount;
      }
    }

    final List<Transaction> reversedTransactions = transactions.reversed.toList();
    double runningBalance = openingBalance;
    final List<List<dynamic>> rows = [];

    final String openingDate = transactions.isNotEmpty
        ? DateFormat.yMMMd().format(reversedTransactions.first.date)
        : DateFormat.yMMMd().format(DateTime.now());

    rows.add([
      openingDate,
      'Opening Balance',
      '',
      '',
      '',
      forCsv ? openingBalance : CurrencyFormatterService.format(openingBalance, account.currencyCode)
    ]);

    for (var transaction in reversedTransactions) {

      if (transaction.type == TransactionType.income) {
        runningBalance += transaction.amount;
      } else {
        runningBalance -= transaction.amount;
      }

      rows.add([
        DateFormat.yMMMd().format(transaction.date),
        transaction.description,
        transaction.category ?? 'Uncategorized',
        transaction.type.toString().split('.').last,
        forCsv ? transaction.amount : CurrencyFormatterService.format(transaction.amount, account.currencyCode),
        forCsv ? runningBalance : CurrencyFormatterService.format(runningBalance, account.currencyCode)
      ]);
    }

    return rows;
  }

  Future<void> exportToCsv(Account account, List<Transaction> transactions, String period) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Date', 'Description', 'Category', 'Type', 'Amount', 'Balance']);

    final ledgerRows = _generateLedger(account, transactions, true);
    rows.addAll(ledgerRows);

    String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv.codeUnits, 'transactions-$period.csv', 'text/csv');
  }

  Future<void> exportToPdf(Account account, List<Transaction> transactions, String period) async {
    final pdf = pw.Document();
    final String currencyCode = account.currencyCode;

    final double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    final List<List<String>> tableData = _generateLedger(account, transactions, false)
        .map((row) => row.map((cell) => cell.toString()).toList())
        .toList();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Transaction Report - $period',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
          ),
          pw.Paragraph(
            text: 'Total Income for this period: ${CurrencyFormatterService.format(totalIncome, currencyCode)}',
          ),
          pw.Paragraph(
            text: 'Total Expenses for this period: ${CurrencyFormatterService.format(totalExpenses, currencyCode)}',
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Description', 'Category', 'Type', 'Amount', 'Balance'],
            data: tableData,
          ),
        ],
      ),
    );

    await _saveAndShareFile((await pdf.save()), 'transactions-$period.pdf', 'application/pdf');
  }

  Future<void> _saveAndShareFile(List<int> bytes, String fileName, String mimeType) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path, mimeType: mimeType)]);
  }
}