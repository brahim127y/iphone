import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../models/models.dart';

class TicketGenerator {
  static Future<Uint8List> buildPdfBytes({
    required List<TicketLine> lines,
    required double total,
    required String paymentMethod,
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    String? customerName,
    DateTime? createdAt,
    String? receiptNo,
  }) async {
    final when = createdAt ?? DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(when);
    final no = receiptNo ?? when.millisecondsSinceEpoch.toString().substring(7);
    final displayShopName = shopName.trim().isEmpty ? 'Ma Boutique' : shopName;

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header Boutique (sans mention TEMBS)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.486, 0.227, 0.929),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    displayShopName.toUpperCase(),
                    style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (shopAddress != null && shopAddress.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      shopAddress,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                  if (shopPhone != null && shopPhone.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Tél : $shopPhone',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'TICKET DE CAISSE',
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor(0.1, 0.063, 0.2),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'N° $no  •  $dateStr',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            if (customerName != null && customerName.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'Client : $customerName',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey300),

            // Articles
            ...lines.map((line) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          line.productName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        'x${line.quantity}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        _formatFCFA(line.lineTotal),
                        style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                )),

            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),

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
                  pw.Text(
                    'TOTAL',
                    style: const pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor(0.486, 0.227, 0.929),
                    ),
                  ),
                  pw.Text(
                    _formatFCFA(total),
                    style: const pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor(0.486, 0.227, 0.929),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),

            // Mode de paiement
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Mode de paiement : ',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    paymentMethod.toUpperCase(),
                    style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.grey200),
            pw.SizedBox(height: 6),

            // Message de fin (sans mention Tembs)
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Merci pour votre confiance !',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor(0.1, 0.063, 0.2),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Ticket émis par $displayShopName',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static Future<void> downloadPdf({
    required BuildContext context,
    required List<TicketLine> lines,
    required double total,
    required String paymentMethod,
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    String? customerName,
    DateTime? createdAt,
    String? receiptNo,
  }) async {
    final when = createdAt ?? DateTime.now();
    final no = receiptNo ?? when.millisecondsSinceEpoch.toString().substring(7);
    final bytes = await buildPdfBytes(
      lines: lines,
      total: total,
      paymentMethod: paymentMethod,
      shopName: shopName,
      shopPhone: shopPhone,
      shopAddress: shopAddress,
      customerName: customerName,
      createdAt: when,
      receiptNo: no,
    );

    final sanitizedShopName = shopName.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = 'ticket_${sanitizedShopName.toLowerCase()}_$no.pdf';

    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final androidDownloadDir = Directory('/storage/emulated/0/Download');
        if (await androidDownloadDir.exists()) {
          targetDir = androidDownloadDir;
        }
      }
      targetDir ??= await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();

      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (context.mounted) {
        showTopDownloadNotification(context, file.path);
      }
    } catch (e) {
      if (context.mounted) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    }
  }

  static void showTopDownloadNotification(BuildContext context, String path) {
    final isIOS = Platform.isIOS || Platform.isMacOS;
    final hintLocation = isIOS
        ? 'Application Fichiers > Sur mon iPhone'
        : path;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 24,
          left: 16,
          right: 16,
        ),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ticket téléchargé avec succès !', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('Emplacement : $hintLocation', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> sharePdf({
    required BuildContext context,
    required List<TicketLine> lines,
    required double total,
    required String paymentMethod,
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    String? customerName,
    DateTime? createdAt,
    String? receiptNo,
  }) async {
    final when = createdAt ?? DateTime.now();
    final no = receiptNo ?? when.millisecondsSinceEpoch.toString().substring(7);
    final bytes = await buildPdfBytes(
      lines: lines,
      total: total,
      paymentMethod: paymentMethod,
      shopName: shopName,
      shopPhone: shopPhone,
      shopAddress: shopAddress,
      customerName: customerName,
      createdAt: when,
      receiptNo: no,
    );

    final sanitizedShopName = shopName.trim().replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = 'ticket_${sanitizedShopName.toLowerCase()}_$no.pdf';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Ticket $shopName n° $no',
      );
    } catch (_) {
      if (context.mounted) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    }
  }

  static void showTicket({
    required BuildContext context,
    required List<TicketLine> lines,
    required double total,
    required String paymentMethod,
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    String? customerName,
    DateTime? createdAt,
    String? receiptNo,
    bool justCreated = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TicketPreviewSheet(
        lines: lines,
        total: total,
        paymentMethod: paymentMethod,
        shopName: shopName,
        shopPhone: shopPhone,
        shopAddress: shopAddress,
        customerName: customerName,
        createdAt: createdAt ?? DateTime.now(),
        receiptNo: receiptNo ?? DateTime.now().millisecondsSinceEpoch.toString().substring(7),
        justCreated: justCreated,
      ),
    );
  }


  static String _formatFCFA(num amount) {
    final formatter = NumberFormat.decimalPattern('fr_FR');
    return '${formatter.format(amount.round())} FCFA';
  }
}

class TicketPreviewSheet extends StatelessWidget {
  final List<TicketLine> lines;
  final double total;
  final String paymentMethod;
  final String shopName;
  final String? shopPhone;
  final String? shopAddress;
  final String? customerName;
  final DateTime createdAt;
  final String receiptNo;
  final bool justCreated;

  const TicketPreviewSheet({
    super.key,
    required this.lines,
    required this.total,
    required this.paymentMethod,
    required this.shopName,
    this.shopPhone,
    this.shopAddress,
    this.customerName,
    required this.createdAt,
    required this.receiptNo,
    this.justCreated = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    final displayShopName = shopName.trim().isEmpty ? 'Ma Boutique' : shopName;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        justCreated ? 'Vente enregistrée' : 'Ticket de caisse',
                        style: GoogleFonts.outfit(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Ticket avec les vraies infos de la boutique (Sans mot TEMBS)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            displayShopName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (shopAddress != null && shopAddress!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                Flex(
                                  direction: Axis.horizontal,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      shopAddress!,
                                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          if (shopPhone != null && shopPhone!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_rounded, color: Colors.white70, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  shopPhone!,
                                  style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TICKET DE CAISSE',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'N° $receiptNo  •  $dateStr',
                      style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (customerName != null && customerName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Client : $customerName',
                        style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.border),
                    ...lines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                line.productName,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'x${line.quantity}',
                              style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formatFCFA(line.lineTotal),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardViolet,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text('TOTAL', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                          const Spacer(),
                          Text(formatFCFA(total), style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Paiement : ${paymentMethod.toUpperCase()}',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSubtle),
                    ),
                    const SizedBox(height: 18),
                    Text('Merci pour votre confiance !', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Ticket émis par $displayShopName', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: 'Télécharger',
                    icon: Icons.download_rounded,
                    onPressed: () => TicketGenerator.downloadPdf(
                      context: context,
                      lines: lines,
                      total: total,
                      paymentMethod: paymentMethod,
                      shopName: shopName,
                      shopPhone: shopPhone,
                      shopAddress: shopAddress,
                      customerName: customerName,
                      createdAt: createdAt,
                      receiptNo: receiptNo,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => TicketGenerator.sharePdf(
                        context: context,
                        lines: lines,
                        total: total,
                        paymentMethod: paymentMethod,
                        shopName: shopName,
                        shopPhone: shopPhone,
                        shopAddress: shopAddress,
                        customerName: customerName,
                        createdAt: createdAt,
                        receiptNo: receiptNo,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
                      label: Text(
                        'Envoyer...',
                        style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
