import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class ExportService {
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> exportToCsv(List<Transaction> transactions, String period) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Date', 'Description', 'Category', 'Type', 'Amount']);

    for (var transaction in transactions) {
      rows.add([
        DateFormat.yMMMd().format(transaction.date),
        transaction.description,
        transaction.category,
        transaction.type.toString().split('.').last,
        transaction.amount,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv.codeUnits, 'transactions-$period.csv', 'text/csv');
  }

  Future<void> exportToPdf(List<Transaction> transactions, String period) async {
    final pdf = pw.Document();

    final double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Transaction Report - $period',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
          ),
          pw.Paragraph(
            text: 'Total Income for this period: ${currencyFormatter.format(totalIncome)}',
          ),
          pw.Paragraph(
            text: 'Total Expenses for this period: ${currencyFormatter.format(totalExpenses)}',
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Description', 'Category', 'Type', 'Amount'],
            data: transactions
                .map((t) => [
                      DateFormat.yMMMd().format(t.date),
                      t.description,
                      t.category ?? 'Uncategorized',
                      t.type.name[0].toUpperCase() + t.type.name.substring(1),
                      currencyFormatter.format(t.amount)
                    ])
                .toList(),
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
