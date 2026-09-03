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

class SalesScreenState extends State<SalesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

  Future<void> openSaleTicket(Sale s) async {
    final items = await DatabaseService.getSaleItems(s.id);
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun article sur cette vente.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final profile = await DatabaseService.getShopProfile();
    if (!mounted) return;
    TicketGenerator.showTicket(
      context: context,
      lines: items.map(TicketLine.fromSaleItem).toList(),
      total: s.total,
      paymentMethod: s.paymentMethod,
      shopName: profile['name'] ?? 'Ma Boutique',
      shopPhone: profile['phone'],
      shopAddress: profile['address'],
      customerName: s.customerName,
      createdAt: s.createdAt,
      receiptNo: s.id.length > 6 ? s.id.substring(s.id.length - 6) : s.id,
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
    super.build(context);
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
                                        return GestureDetector(
                                          onTap: () => openSaleTicket(s),
                                          child: Container(
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
                                              const SizedBox(width: 6),
                                              const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.textMuted),
                                            ],
                                          ),
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
                                return GestureDetector(
                                  onTap: () => openSaleTicket(s),
                                  child: Container(
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
                                                      const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textMuted),
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
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                      ],
                                    ),
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

  List<Product> get filteredProducts {
    final q = productSearch.toLowerCase();
    final list = widget.products.where((p) => p.name.toLowerCase().contains(q)).toList();
    list.sort((a, b) {
      if (a.quantity <= 0 && b.quantity > 0) return 1;
      if (a.quantity > 0 && b.quantity <= 0) return -1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  int _inCartQty(String productId) {
    for (final line in cart) {
      if (line.product.id == productId) return line.quantity;
    }
    return 0;
  }

  int _available(Product p) => p.quantity - _inCartQty(p.id);

  void _stockDenied(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void addToCart(Product p) {
    if (p.quantity <= 0) {
      _stockDenied('${p.name} est en rupture de stock. Vente refusée.');
      return;
    }
    if (_available(p) <= 0) {
      _stockDenied('Stock insuffisant pour ${p.name} (disponible : ${p.quantity}).');
      return;
    }
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
    final line = cart.firstWhere((l) => l.product.id == productId);
    if (delta > 0 && line.quantity + delta > line.product.quantity) {
      _stockDenied(
        'Stock insuffisant pour ${line.product.name} (disponible : ${line.product.quantity}).',
      );
      return;
    }
    setState(() {
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
    for (final line in cart) {
      if (line.product.quantity <= 0) {
        _stockDenied('${line.product.name} est en rupture de stock. Vente refusée.');
        return;
      }
      if (line.quantity > line.product.quantity) {
        _stockDenied(
          'Stock insuffisant pour ${line.product.name} (disponible : ${line.product.quantity}).',
        );
        return;
      }
    }

    setState(() => saving = true);

    final lines = cart.map(TicketLine.fromCart).toList();
    final saleTotal = total;
    final method = paymentMethod;
    final customer = selectedCustomer;

    try {
      final sale = await DatabaseService.insertSale(
        customerId: customer?.id,
        customerName: customer?.name,
        customerPhone: customer?.phone,
        total: saleTotal,
        paymentMethod: method,
        cartLines: cart,
      );

      widget.onSaved();

      final profile = await DatabaseService.getShopProfile();

      if (!mounted) return;
      Navigator.pop(context);
      TicketGenerator.showTicket(
        context: context,
        lines: lines,
        total: saleTotal,
        paymentMethod: method,
        shopName: profile['name'] ?? 'Ma Boutique',
        shopPhone: profile['phone'],
        shopAddress: profile['address'],
        customerName: customer?.name,
        createdAt: sale.createdAt,
        receiptNo: sale.id.length > 6 ? sale.id.substring(sale.id.length - 6) : sale.id,
        justCreated: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        _stockDenied(e.toString().replaceFirst('Exception: ', ''));
      }
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
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      fillColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Liste produits (scrollable horizontalement)
                  SizedBox(
                    height: 176,
                    child: filteredProducts.isEmpty
                        ? Center(child: Text('Aucun produit', style: GoogleFonts.outfit(color: AppColors.textMuted)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, i) {
                              final p = filteredProducts[i];
                              final inCart = cart.any((l) => l.product.id == p.id);
                              final outOfStock = p.quantity <= 0;
                              return GestureDetector(
                                onTap: () => addToCart(p),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: outOfStock
                                        ? AppColors.dangerLight
                                        : inCart
                                            ? AppColors.cardViolet
                                            : AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: outOfStock
                                          ? AppColors.danger
                                          : inCart
                                              ? AppColors.primary
                                              : AppColors.border,
                                      width: inCart || outOfStock ? 2 : 1,
                                    ),
                                    boxShadow: inCart
                                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8)]
                                        : [],
                                  ),
                                  child: Opacity(
                                    opacity: outOfStock ? 0.55 : 1,
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
                                      Text(
                                        outOfStock ? 'Rupture' : 'Stock : ${p.quantity}',
                                        style: GoogleFonts.outfit(
                                          color: outOfStock
                                              ? AppColors.danger
                                              : p.quantity <= 3
                                                  ? AppColors.warning
                                                  : AppColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                onTap: l.quantity >= l.product.quantity
                                    ? null
                                    : () => changeQuantity(l.product.id, 1),
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    gradient: l.quantity >= l.product.quantity
                                        ? null
                                        : AppGradients.primary,
                                    color: l.quantity >= l.product.quantity
                                        ? AppColors.surfaceAlt
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: l.quantity >= l.product.quantity
                                        ? AppColors.textMuted
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),

                  const SizedBox(height: 20),

                  // Client
                  Row(
                    children: [
                      Expanded(child: _sectionLabel('Client (optionnel)')),
                      if (widget.customers.isNotEmpty)
                        GestureDetector(
                          onTap: _openCustomerPickerModal,
                          child: Text(
                            'Rechercher (${widget.customers.length})',
                            style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.customers.isEmpty)
                    _customerChip(null, selectedCustomer == null)
                  else
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _customerChip(null, selectedCustomer == null),
                          if (selectedCustomer != null && !widget.customers.take(4).any((c) => c.id == selectedCustomer!.id))
                            _customerChip(selectedCustomer, true),
                          ...widget.customers.take(4).map((c) => _customerChip(c, selectedCustomer?.id == c.id)),
                          if (widget.customers.length > 4)
                            GestureDetector(
                              onTap: _openCustomerPickerModal,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${widget.customers.length - 4} autres',
                                      style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                    child: Text('Annuler', style: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
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

  void _openCustomerPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerPickerSheet(
        customers: widget.customers,
        selectedCustomer: selectedCustomer,
        onSelect: (c) {
          setState(() => selectedCustomer = c);
        },
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

class CustomerPickerSheet extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final Function(Customer?) onSelect;

  const CustomerPickerSheet({
    super.key,
    required this.customers,
    required this.selectedCustomer,
    required this.onSelect,
  });

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  String search = '';

  List<Customer> get filtered {
    final q = search.toLowerCase().trim();
    if (q.isEmpty) return widget.customers;
    return widget.customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(q);
      final phoneMatch = (c.phone ?? '').contains(q);
      return nameMatch || phoneMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Sélectionner un client', style: GoogleFonts.outfit(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => search = v),
            style: GoogleFonts.outfit(color: AppColors.text),
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom ou numéro...',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text('Client de passage (Anonyme)', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.text)),
            trailing: widget.selectedCustomer == null ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
            onTap: () {
              widget.onSelect(null);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Aucun client trouvé', style: GoogleFonts.outfit(color: AppColors.textMuted)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final isSelected = widget.selectedCustomer?.id == c.id;
                      return ListTile(
                        title: Text(c.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.text)),
                        subtitle: c.phone != null ? Text(c.phone!, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)) : null,
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () {
                          widget.onSelect(c);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
