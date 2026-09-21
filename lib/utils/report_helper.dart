import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../model/expense_model.dart';
import 'category_helper.dart';

class ReportHelper {
  const ReportHelper._();

  /// Generates a CSV report string from a list of expenses.
  static String generateCsvReport(List<Expense> expenses) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Title / Contact,Category,Amount,Reason,Phone');

    for (final expense in expenses) {
      final categoryReason = parseCategoryAndReason(expense.reason);
      final category = categoryReason.category ?? 'Uncategorized';
      final cleanReason = categoryReason.cleanReason;
      final titleOrContact = expense.contactName ?? expense.title;

      final row = [
        _escapeCsv(expense.date),
        _escapeCsv(expense.type),
        _escapeCsv(titleOrContact),
        _escapeCsv(category),
        expense.amount.toStringAsFixed(2),
        _escapeCsv(cleanReason),
        _escapeCsv(expense.phoneNumber ?? ''),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Generates a high-quality PDF financial statement document as raw bytes.
  static Future<Uint8List> generatePdfReport(
    List<Expense> expenses, {
    required String currencySymbol,
    required String currencyCode,
  }) async {
    final pdf = pw.Document();

    pw.Font? baseFont;
    pw.Font? boldFont;
    final fontFallback = <pw.Font>[];
    bool hasUnicodeFont = false;

    try {
      baseFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();

      // Devanagari font provides glyphs for Indian Rupee symbol (₹) and international currencies
      final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
      final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();
      if (devanagari.fontName != 'Helvetica') {
        fontFallback.add(devanagari);
        fontFallback.add(devanagariBold);
        hasUnicodeFont = true;
      }
    } catch (_) {
      baseFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      hasUnicodeFont = false;
    }

    // Determine the cleanest, safest currency symbol for PDF rendering.
    // If standard Helvetica fallback is used (offline), non-ASCII glyphs like '₹' (U+20B9)
    // are replaced with 'Rs.' to ensure readable, professional statements.
    String displaySymbol;
    if (hasUnicodeFont) {
      displaySymbol = currencySymbol;
    } else {
      if (currencySymbol == '₹' || currencyCode.toUpperCase() == 'INR') {
        displaySymbol = 'Rs. ';
      } else if (currencySymbol.codeUnits.any((c) => c > 127)) {
        displaySymbol = '$currencyCode ';
      } else {
        displaySymbol = currencySymbol;
      }
    }

    final numberFormat = NumberFormat('#,##0.00');
    String formatAmount(double amount, {String prefix = ''}) {
      return '$prefix$displaySymbol${numberFormat.format(amount)}';
    }

    double totalIncome = 0;
    double totalExpense = 0;
    double totalLent = 0;
    double totalBorrowed = 0;

    for (final e in expenses) {
      switch (e.type.toLowerCase()) {
        case 'income':
          totalIncome += e.amount;
          break;
        case 'expense':
          totalExpense += e.amount;
          break;
        case 'lent':
          totalLent += e.amount;
          break;
        case 'borrowed':
        case 'borrow':
          totalBorrowed += e.amount;
          break;
      }
    }

    final netBalance = totalIncome - totalExpense;
    final nowFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          fontFallback: fontFallback,
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LenDen',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.Text(
                      'Personal Finance & Lending Statement',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated: $nowFormatted | Currency: $currencyCode (${displaySymbol.trim()})',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.grey300, thickness: 1),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'LenDen Mobile App - Financial Summary',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (context) => [
          // KPI Grid
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildKpiItem('Income', formatAmount(totalIncome, prefix: '+'), PdfColors.green800),
                _buildKpiItem('Expense', formatAmount(totalExpense, prefix: '-'), PdfColors.red800),
                _buildKpiItem('Net Balance', formatAmount(netBalance.abs(), prefix: netBalance < 0 ? '-' : ''), PdfColors.blue800),
                _buildKpiItem('Lent', formatAmount(totalLent), PdfColors.orange800),
                _buildKpiItem('Borrowed', formatAmount(totalBorrowed), PdfColors.purple800),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Transactions (${expenses.length} Records)',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),

          // Transaction Table
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.symmetric(
              inside: const pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              outside: const pw.BorderSide(color: PdfColors.grey300, width: 0.8),
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            headerHeight: 24,
            cellHeight: 20,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: ['Date', 'Type', 'Title / Contact', 'Category', 'Reason / Notes', 'Amount ($currencyCode)'],
            data: expenses.map((e) {
              final cr = parseCategoryAndReason(e.reason);
              final category = cr.category ?? 'General';
              final titleOrContact = e.contactName ?? e.title;
              final isPositive = e.type.toLowerCase() == 'income' || e.type.toLowerCase() == 'borrowed';
              final prefix = isPositive ? '+' : '-';
              return [
                e.date,
                e.type,
                titleOrContact,
                category,
                cr.cleanReason,
                formatAmount(e.amount, prefix: prefix),
              ];
            }).toList(),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
}
