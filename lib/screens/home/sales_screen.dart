import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../widgets/ticket_generator.dart';
import '../widgets/screen_header.dart';
import '../widgets/product_image_view.dart';

const paymentMethods = ['Espèces', 'Mobile Money', 'Carte', 'Crédit'];

class SalesScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const SalesScreen({super.key, this.onProfileTap});

  @override
  State<SalesScreen> createState() => SalesScreenState();
}

class SalesScreenState extends State<SalesScreen> {
  List<Sale> sales = [];
  List<Product> products = [];
  List<Customer> customers = [];
  bool loading = true;
  bool groupByDay = false;

  Map<String, List<Sale>> get groupedSales {
    final groups = <String, List<Sale>>{};
    for (final s in sales) {
      final dateKey = '${s.createdAt.day.toString().padLeft(2, '0')}/${s.createdAt.month.toString().padLeft(2, '0')}/${s.createdAt.year}';
      groups.putIfAbsent(dateKey, () => []).add(s);
    }
    return groups;
  }

  double dayTotal(List<Sale> daySales) {
    return daySales.fold(0.0, (sum, s) => sum + s.total);
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    final salesList = await DatabaseService.getSales();
    final prodList = await DatabaseService.getProducts();
    final custList = await DatabaseService.getCustomers();
    setState(() {
      sales = salesList;
      products = prodList;
      customers = custList;
      loading = false;
    });
  }

  void openNewSaleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewSaleSheet(
        products: products,
        customers: customers,
        onSaved: loadData,
      ),
    );
  }

  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'espèces': return AppColors.success;
      case 'mobile money': return AppColors.primary;
      case 'carte': return const Color(0xFF06B6D4);
      case 'crédit': return AppColors.warning;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Ventes',
          subtitle: '${sales.length} vente${sales.length > 1 ? 's' : ''} enregistrée${sales.length > 1 ? 's' : ''}',
          icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
          actions: [
            GestureDetector(
              onTap: openNewSaleSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => groupByDay = !groupByDay),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  groupByDay ? Icons.grid_view_rounded : Icons.view_stream_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            if (widget.onProfileTap != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : sales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Aucune vente enregistrée.', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 15)),
                          const SizedBox(height: 16),
                          GradientButton(label: '+ Nouvelle vente', onPressed: openNewSaleSheet, icon: Icons.add_shopping_cart_rounded),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadData,
                      color: AppColors.primary,
                      child: groupByDay
                          ? ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: groupedSales.keys.length,
                              itemBuilder: (context, i) {
                                final dateKey = groupedSales.keys.elementAt(i);
                                final daySales = groupedSales[dateKey]!;
                                final total = dayTotal(daySales);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      title: Text(
                                        dateKey,
                                        style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      subtitle: Text(
                                        '${daySales.length} vente${daySales.length > 1 ? 's' : ''} • Total : ${formatFCFA(total)}',
                                        style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      leading: Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.cardViolet,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                                      ),
                                      childrenPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      children: daySales.map((s) {
                                        final pmColor = _paymentColor(s.paymentMethod);
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s.customerName ?? 'Client de passage',
                                                      style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: pmColor.withValues(alpha: 0.10),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            s.paymentMethod,
                                                            style: GoogleFonts.outfit(color: pmColor, fontSize: 9, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                formatFCFA(s.total),
                                                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: sales.length,
                              itemBuilder: (context, i) {
                                final s = sales[i];
                                final pmColor = _paymentColor(s.paymentMethod);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(
                                            color: AppColors.cardViolet,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.customerName ?? 'Client de passage',
                                                style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}',
                                                        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: pmColor.withValues(alpha: 0.10),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      s.paymentMethod,
                                                      style: GoogleFonts.outfit(color: pmColor, fontSize: 10, fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          formatFCFA(s.total),
                                          style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}

// =============================================
// Sheet : Nouvelle vente
// =============================================
class NewSaleSheet extends StatefulWidget {
  final List<Product> products;
  final List<Customer> customers;
  final VoidCallback onSaved;

  const NewSaleSheet({
    super.key,
    required this.products,
    required this.customers,
    required this.onSaved,
  });

  @override
  State<NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends State<NewSaleSheet> {
  List<CartLine> cart = [];
  Customer? selectedCustomer;
  String paymentMethod = paymentMethods[0];
  bool saving = false;
  String productSearch = '';

  double get total => cart.fold(0, (sum, l) => sum + l.lineTotal);

  List<Product> get filteredProducts => widget.products
      .where((p) => p.name.toLowerCase().contains(productSearch.toLowerCase()))
      .toList();

  void addToCart(Product p) {
    setState(() {
      final existing = cart.where((l) => l.product.id == p.id).toList();
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        cart.add(CartLine(product: p));
      }
    });
  }

  void changeQuantity(String productId, int delta) {
    setState(() {
      final line = cart.firstWhere((l) => l.product.id == productId);
      line.quantity += delta;
      if (line.quantity <= 0) cart.removeWhere((l) => l.product.id == productId);
    });
  }

  Future<void> save() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un produit.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => saving = true);

    await DatabaseService.insertSale(
      customerId: selectedCustomer?.id,
      customerName: selectedCustomer?.name,
      customerPhone: selectedCustomer?.phone,
      total: total,
      paymentMethod: paymentMethod,
      cartLines: cart,
    );

    setState(() => saving = false);
    widget.onSaved();

    final profile = await DatabaseService.getShopProfile();
    final shopName = profile['name'] ?? 'Tembs';

    if (mounted) {
      Navigator.pop(context);
      TicketGenerator.generateAndShare(
        context: context,
        cartLines: cart,
        total: total,
        paymentMethod: paymentMethod,
        shopName: shopName,
        customer: selectedCustomer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      height: MediaQuery.of(context).size.height * 0.92,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + titre
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text('Nouvelle vente', style: GoogleFonts.outfit(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text(formatFCFA(total), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recherche produits
                  _sectionLabel('Produits disponibles'),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => productSearch = v),
                    style: GoogleFonts.outfit(color: AppColors.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Liste produits (scrollable horizontalement)
                  SizedBox(
                    height: 160,
                    child: filteredProducts.isEmpty
                        ? Center(child: Text('Aucun produit', style: GoogleFonts.outfit(color: AppColors.textMuted)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, i) {
                              final p = filteredProducts[i];
                              final inCart = cart.any((l) => l.product.id == p.id);
                              return GestureDetector(
                                onTap: () => addToCart(p),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: inCart ? AppColors.cardViolet : AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: inCart ? AppColors.primary : AppColors.border,
                                      width: inCart ? 2 : 1,
                                    ),
                                    boxShadow: inCart ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8)] : [],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: ProductImageView(
                                          imageUrl: p.imageUrl,
                                          height: 60,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          iconSize: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(p.name, style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(formatFCFA(p.price), style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Panier
                  _sectionLabel('Panier (${cart.length} article${cart.length > 1 ? 's' : ''})'),
                  const SizedBox(height: 8),
                  if (cart.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(child: Text('Touche un produit pour l\'ajouter au panier', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13))),
                    )
                  else
                    ...cart.map((l) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.product.name, style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600)),
                                Text(formatFCFA(l.lineTotal), style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => changeQuantity(l.product.id, -1),
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                                  child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.textMuted),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('${l.quantity}', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
                              ),
                              GestureDetector(
                                onTap: () => changeQuantity(l.product.id, 1),
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),

                  const SizedBox(height: 20),

                  // Client
                  _sectionLabel('Client (optionnel)'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _customerChip(null, selectedCustomer == null),
                        ...widget.customers.map((c) => _customerChip(c, selectedCustomer?.id == c.id)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mode de paiement
                  _sectionLabel('Mode de paiement'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: paymentMethods.map((m) {
                      final selected = paymentMethod == m;
                      return GestureDetector(
                        onTap: () => setState(() => paymentMethod = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(m, style: GoogleFonts.outfit(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bouton valider
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    label: saving ? 'Enregistrement...' : 'Valider la vente',
                    onPressed: saving ? null : save,
                    loading: saving,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
  );

  Widget _customerChip(Customer? c, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => selectedCustomer = c),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          c?.name ?? 'De passage',
          style: GoogleFonts.outfit(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
