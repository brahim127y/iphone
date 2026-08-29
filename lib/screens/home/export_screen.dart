import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/theme.dart';
import '../../services/database_service.dart';

const months = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

class ExportScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const ExportScreen({super.key, this.onProfileTap});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen>
    with SingleTickerProviderStateMixin {
  final now = DateTime.now();
  String mode = 'month';
  late int selectedMonth;
  late int selectedYear;
  bool loading = false;

  // Stats preview
  double previewRevenue = 0;
  int previewSalesCount = 0;
  bool loadingPreview = false;
  bool previewLoaded = false;

  late TabController _tabController;

  List<int> get years => List.generate(5, (i) => now.year - i);

  @override
  void initState() {
    super.initState();
    selectedMonth = now.month - 1;
    selectedYear = now.year;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadPreview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    setState(() { loadingPreview = true; previewLoaded = false; });
    try {
      final start = mode == 'month'
          ? DateTime(selectedYear, selectedMonth + 1, 1)
          : DateTime(selectedYear, 1, 1);
      final end = mode == 'month'
          ? DateTime(selectedYear, selectedMonth + 2, 1)
          : DateTime(selectedYear + 1, 1, 1);

      final db = await DatabaseService.database;
      final salesRes = await db.rawQuery(
        'SELECT total FROM sales WHERE created_at >= ? AND created_at < ?',
        [start.toIso8601String(), end.toIso8601String()],
      );

      setState(() {
        previewRevenue = salesRes.fold(0.0, (s, r) => s + (r['total'] as num));
        previewSalesCount = salesRes.length;
        loadingPreview = false;
        previewLoaded = true;
      });
    } catch (_) {
      setState(() => loadingPreview = false);
    }
  }

  Future<void> generatePdf() async {
    setState(() => loading = true);
    try {
      final start = mode == 'month'
          ? DateTime(selectedYear, selectedMonth + 1, 1)
          : DateTime(selectedYear, 1, 1);
      final end = mode == 'month'
          ? DateTime(selectedYear, selectedMonth + 2, 1)
          : DateTime(selectedYear + 1, 1, 1);

      final db = await DatabaseService.database;
      final salesList = await db.rawQuery(
        'SELECT s.id, s.total, s.payment_method, s.created_at, s.customer_name FROM sales s WHERE s.created_at >= ? AND s.created_at < ? ORDER BY s.created_at',
        [start.toIso8601String(), end.toIso8601String()],
      );
      final saleItems = await db.rawQuery(
        '''SELECT si.sale_id, si.product_name, si.quantity, si.price FROM sale_items si
           JOIN sales s ON s.id = si.sale_id
           WHERE s.created_at >= ? AND s.created_at < ?''',
        [start.toIso8601String(), end.toIso8601String()],
      );

      final totalRevenue = salesList.fold<double>(0, (s, r) => s + (r['total'] as num));
      final avgSale = salesList.isEmpty ? 0 : totalRevenue / salesList.length;

      final Map<String, Map<String, num>> productTotals = {};
      final Map<String, num> paymentMethodCounts = {};

      for (final sale in salesList) {
        final pm = sale['payment_method'] as String? ?? 'Inconnu';
        paymentMethodCounts[pm] = (paymentMethodCounts[pm] ?? 0) + 1;
      }

      for (final item in saleItems) {
        final pname = item['product_name'] as String? ?? 'Produit supprimé';
        productTotals.putIfAbsent(pname, () => {'qty': 0, 'revenue': 0});
        productTotals[pname]!['qty'] = productTotals[pname]!['qty']! + (item['quantity'] as num);
        productTotals[pname]!['revenue'] = productTotals[pname]!['revenue']! +
            (item['quantity'] as num) * (item['price'] as num);
      }

      final topProducts = productTotals.entries.toList()
        ..sort((a, b) => b.value['revenue']!.compareTo(a.value['revenue']!));
      final top10 = topProducts.take(10).toList();
      final periodLabel = mode == 'month' ? '${months[selectedMonth]} $selectedYear' : 'Année $selectedYear';
      final profile = await DatabaseService.getShopProfile();
      final shopName = (profile['name'] ?? 'TEMBS').toUpperCase();


      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // En-tête
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.486, 0.227, 0.929), // violet
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(shopName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('Rapport de ventes', style: const pw.TextStyle(fontSize: 14, color: PdfColors.white)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text('Période : $periodLabel', style: const pw.TextStyle(fontSize: 12, color: PdfColors.white)),
                    pw.Text('Généré le ${now.day}/${now.month}/${now.year}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Résumé
            pw.Text('Résumé', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.063, 0.2))),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              _summaryCard('Chiffre d\'affaires', formatFCFA(totalRevenue), PdfColors.purple50),
              pw.SizedBox(width: 12),
              _summaryCard('Nombre de ventes', '${salesList.length}', PdfColors.blue50),
              pw.SizedBox(width: 12),
              _summaryCard('Panier moyen', formatFCFA(avgSale), PdfColors.green50),
            ]),
            pw.SizedBox(height: 20),

            // Méthodes de paiement
            if (paymentMethodCounts.isNotEmpty) ...[
              pw.Text('Méthodes de paiement', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.063, 0.2))),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 8,
                children: paymentMethodCounts.entries.map((e) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text('${e.key}: ${e.value}x', style: const pw.TextStyle(fontSize: 11)),
                )).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // Top produits
            pw.Text('Top 10 produits vendus', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.063, 0.71, 0.506))),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(horizontalInside: const pw.BorderSide(color: PdfColors.grey200)),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Produit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Revenu', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.right)),
                  ],
                ),
                if (top10.isEmpty)
                  pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Aucune vente sur cette période.')), pw.SizedBox(), pw.SizedBox()])
                else
                  ...top10.asMap().entries.map((entry) {
                    final e = entry.value;
                    final isEven = entry.key.isEven;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 11))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${e.value['qty']}', style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(formatFCFA(e.value['revenue']!), style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
              ],
            ),
            pw.SizedBox(height: 24),

            // Détail des ventes
            pw.Text('Détail des ventes', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.063, 0.71, 0.506))),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(horizontalInside: const pw.BorderSide(color: PdfColors.grey200)),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Paiement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.right)),
                  ],
                ),
                if (salesList.isEmpty)
                  pw.TableRow(children: [pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Aucune vente sur cette période.')), pw.SizedBox(), pw.SizedBox(), pw.SizedBox()])
                else
                  ...salesList.asMap().entries.map((entry) {
                    final s = entry.value;
                    final isEven = entry.key.isEven;
                    final date = DateTime.parse(s['created_at'] as String);
                    final custName = s['customer_name'] as String?;
                    final payMethod = s['payment_method'] as String? ?? 'Espèces';
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey50),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${date.day}/${date.month}/${date.year}', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(custName != null && custName.isNotEmpty ? custName : 'Client de passage', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(payMethod, style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(formatFCFA(s['total'] as num), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Text(
                '— Document généré par Tembs — tembs.app —',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'tembs_contrat_${periodLabel.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'export : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  pw.Widget _summaryCard(String label, String value, PdfColor bg) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.063, 0.2))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodLabel = mode == 'month'
        ? '${months[selectedMonth]} $selectedYear'
        : 'Année $selectedYear';
    final topPadding = MediaQuery.of(context).padding.top + 16;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // AppBar personnalisée
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, topPadding, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppGradients.authHero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exporter PDF', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            Text('Contrats et analyses', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sélecteur Par mois / Par année
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _headerToggle('Par mois', mode == 'month', () {
                          setState(() => mode = 'month');
                          _loadPreview();
                        }),
                        _headerToggle('Par année', mode == 'year', () {
                          setState(() => mode = 'year');
                          _loadPreview();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Sélecteur mois
                if (mode == 'month') ...[
                  Text('Choisir le mois', style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (i) => _monthChip(months[i], selectedMonth == i, () {
                      setState(() => selectedMonth = i);
                      _loadPreview();
                    })),
                  ),
                  const SizedBox(height: 20),
                ],

                // Sélecteur année
                Text('Choisir l\'année', style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: years.map((y) => _yearChip('$y', selectedYear == y, () {
                    setState(() => selectedYear = y);
                    _loadPreview();
                  })).toList(),
                ),

                const SizedBox(height: 24),

                // Carte aperçu
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Aperçu — $periodLabel',
                            style: GoogleFonts.outfit(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (loadingPreview)
                        const Center(child: CircularProgressIndicator())
                      else if (previewLoaded) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _previewStat(
                                'Chiffre d\'affaires',
                                formatFCFA(previewRevenue),
                                Icons.trending_up_rounded,
                                AppColors.cardViolet,
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _previewStat(
                                'Nombre de ventes',
                                '$previewSalesCount vente${previewSalesCount > 1 ? 's' : ''}',
                                Icons.receipt_rounded,
                                AppColors.cardEmerald,
                                AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _previewStat(
                          'Panier moyen',
                          previewSalesCount > 0 ? formatFCFA(previewRevenue / previewSalesCount) : '—',
                          Icons.shopping_bag_rounded,
                          AppColors.cardAmber,
                          AppColors.warning,
                        ),
                      ] else
                        Text('Aucune donnée', style: GoogleFonts.outfit(color: AppColors.textMuted)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton générer
                GradientButton(
                  label: loading ? 'Génération...' : '📄 Générer et partager le PDF',
                  onPressed: loading ? null : generatePdf,
                  loading: loading,
                  icon: Icons.picture_as_pdf_rounded,
                ),

                const SizedBox(height: 12),

                // Bouton aperçu rapide
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: loadingPreview ? null : _loadPreview,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Rafraîchir l\'aperçu', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerToggle(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primary : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _yearChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.accent : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _previewStat(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.outfit(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
