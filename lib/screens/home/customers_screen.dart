import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../widgets/screen_header.dart';

class CustomersScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const CustomersScreen({super.key, this.onProfileTap});

  @override
  State<CustomersScreen> createState() => CustomersScreenState();
}

class CustomersScreenState extends State<CustomersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Customer> customers = [];

  bool loading = true;
  String searchQuery = '';

  List<Customer> get filtered => customers
      .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    final res = await DatabaseService.getCustomers();
    setState(() {
      customers = res;
      loading = false;
    });
  }

  void openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomerSheet(onSaved: loadData),
    );
  }

  void openEditSheet(Customer c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomerSheet(onSaved: loadData, customer: c),
    );
  }

  Future<void> _openWhatsApp(String phone, {String message = ''}) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final number = cleaned.startsWith('+') ? cleaned : '+223$cleaned';
    final encodedMsg = Uri.encodeComponent(message);
    final uri = Uri.parse('https://api.whatsapp.com/send?phone=$number&text=$encodedMsg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp non disponible pour ce numéro.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Color _avatarColor(String name) {
    final colors = [
      AppColors.primary, AppColors.accent, AppColors.success,
      AppColors.warning, const Color(0xFF06B6D4), const Color(0xFFF472B6),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(

      children: [
        ScreenHeader(
          title: 'Clients',
          subtitle: '${customers.length} client${customers.length > 1 ? 's' : ''} enregistré${customers.length > 1 ? 's' : ''}',
          icon: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
          actions: [
            GestureDetector(
              onTap: openAddSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
              ),
            ),
            if (widget.onProfileTap != null) ...[
              const SizedBox(width: 8),
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
          bottom: TextField(
            onChanged: (v) => setState(() => searchQuery = v),
            style: GoogleFonts.outfit(color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white, width: 2)),
            ),
          ),
        ),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(customers.isEmpty ? 'Aucun client pour l\'instant.' : 'Aucun résultat.',
                              style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 15)),
                          if (customers.isEmpty) ...[
                            const SizedBox(height: 16),
                            GradientButton(label: '+ Ajouter un client', onPressed: openAddSheet, icon: Icons.person_add_rounded),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadData,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final avatarColor = _avatarColor(c.name);
                          return GestureDetector(
                            onTap: () => openEditSheet(c),
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
                                    // Avatar
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: avatarColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                          style: GoogleFonts.outfit(color: avatarColor, fontWeight: FontWeight.w800, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Infos
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.name, style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
                                          if (c.phone != null && c.phone!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Text(c.phone!, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                          if (c.address != null && c.address!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                                                const SizedBox(width: 4),
                                                Expanded(child: Text(c.address!, style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Boutons actions
                                    if (c.phone != null && c.phone!.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => _openWhatsApp(c.phone!, message: 'Bonjour ${c.name} ! 👋'),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
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
        ),
      ],
    );
  }
}

// =============================================
// Sheet : Ajouter un client
// =============================================
class AddCustomerSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Customer? customer;

  const AddCustomerSheet({
    super.key,
    required this.onSaved,
    this.customer,
  });

  @override
  State<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<AddCustomerSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      final c = widget.customer!;
      nameController.text = c.name;
      phoneController.text = c.phone ?? '';
      addressController.text = c.address ?? '';
      notesController.text = c.notes ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        title: Text('Supprimer le client', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Text('Es-tu sûr de vouloir supprimer "${widget.customer!.name}" ?', style: GoogleFonts.outfit(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => saving = true);
      try {
        await DatabaseService.deleteCustomer(widget.customer!.id);
        setState(() => saving = false);
        widget.onSaved();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() => saving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de suppression : $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseigne le nom du client.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => saving = true);
    final data = {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      'address': addressController.text.trim().isEmpty ? null : addressController.text.trim(),
      'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    };

    try {
      if (widget.customer != null) {
        await DatabaseService.updateCustomer(widget.customer!.id, data);
      } else {
        await DatabaseService.insertCustomer(data);
      }
      setState(() => saving = false);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement : $e'), backgroundColor: AppColors.danger),
        );
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer != null ? 'Modifier le client' : 'Nouveau client',
                        style: GoogleFonts.outfit(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.customer != null ? 'Modifie les infos du client' : 'Remplis les infos de ton client',
                        style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (widget.customer != null)
                  IconButton(
                    onPressed: deleteCustomer,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            _label('Nom complet *'),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Mamadou Diallo', prefixIcon: Icon(Icons.badge_rounded, size: 20)),
            ),

            const SizedBox(height: 16),

            _label('WhatsApp / Téléphone'),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: '+223 XXX XXX XXX', prefixIcon: Icon(Icons.chat_rounded, size: 20)),
            ),

            const SizedBox(height: 16),

            _label('Adresse (optionnel)'),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Quartier, ville...', prefixIcon: Icon(Icons.location_on_rounded, size: 20)),
            ),

            const SizedBox(height: 16),

            _label('Notes (optionnel)'),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Préférences, historique...', prefixIcon: Icon(Icons.note_alt_rounded, size: 20)),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler', style: GoogleFonts.outfit(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(
                    label: saving ? 'Enregistrement...' : 'Enregistrer',
                    onPressed: saving ? null : save,
                    loading: saving,
                    icon: Icons.check_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 13, fontWeight: FontWeight.w600),
  );
}
