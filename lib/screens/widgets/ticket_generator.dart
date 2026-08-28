import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/models.dart';

class TicketGenerator {
  /// Génère un ticket de caisse PDF stylisé et le partage
  static Future<void> generateAndShare({
    required BuildContext context,
    required List<CartLine> cartLines,
    required double total,
    required String paymentMethod,
    required String shopName,
    Customer? customer,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final receiptNo = now.millisecondsSinceEpoch.toString().substring(7);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 8 * PdfPageFormat.mm),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // En-tête TEMBS
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.486, 0.227, 0.929),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(children: [
                pw.Text('TEMBS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                pw.SizedBox(height: 2),
                pw.Text(shopName, style: const pw.TextStyle(fontSize: 11, color: PdfColors.white)),
              ]),
            ),

            pw.SizedBox(height: 12),

            // Info ticket
            pw.Text('TICKET DE CAISSE', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.063, 0.2))),
            pw.SizedBox(height: 4),
            pw.Text('N° $receiptNo  •  $dateStr', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            if (customer != null)
              pw.Text('Client : ${customer.name}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),

            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),

            // Articles
            ...cartLines.map((line) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(line.product.name, style: const pw.TextStyle(fontSize: 11)),
                  ),
                  pw.Text('x${line.quantity}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  pw.SizedBox(width: 8),
                  pw.Text(_formatFCFA(line.lineTotal), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            )),

            pw.Divider(color: PdfColors.grey300),

            // Total
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.purple50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.486, 0.227, 0.929))),
                  pw.Text(_formatFCFA(total), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.486, 0.227, 0.929))),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('Paiement : ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(paymentMethod.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey200),
            pw.SizedBox(height: 8),

            pw.Center(
              child: pw.Column(children: [
                pw.Text('Merci pour votre achat ! 🙏', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.063, 0.2))),
                pw.SizedBox(height: 4),
                pw.Text('Powered by Tembs', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
              ]),
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();

    if (context.mounted) {
      await Printing.sharePdf(bytes: bytes, filename: 'ticket_tembs_$receiptNo.pdf');
    }
  }

  static String _formatFCFA(num amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }
}
