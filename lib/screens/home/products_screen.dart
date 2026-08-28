import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../widgets/screen_header.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const ProductsScreen({super.key, this.onProfileTap});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  List<Category> categories = [];
  bool loading = true;
  String searchQuery = '';
  String? filterCategoryId;

  List<Product> get filtered => products.where((p) {
    final matchSearch = p.name.toLowerCase().contains(searchQuery.toLowerCase());
    final matchCat = filterCategoryId == null || p.categoryId == filterCategoryId;
    return matchSearch && matchCat;
  }).toList();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);
    try {
      final prodRes = await supabase.from('products').select().order('created_at', ascending: false);
      final catRes = await supabase.from('categories').select().order('name');
      setState(() {
        products = (prodRes as List).map((e) => Product.fromJson(e)).toList();
        categories = (catRes as List).map((e) => Category.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  String categoryName(String? id) {
    if (id == null) return 'Sans catégorie';
    return categories.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: 'Sans catégorie')).name;
  }

  Color _stockColor(int qty) {
    if (qty <= 0) return AppColors.danger;
    if (qty <= 3) return AppColors.warning;
    return AppColors.success;
  }

  void openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(categories: categories, onSaved: loadData),
    );
  }

  void openEditSheet(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(categories: categories, onSaved: loadData, product: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Produits',
          subtitle: '${products.length} produit${products.length > 1 ? 's' : ''} au catalogue',
          icon: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24),
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
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recherche
              TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                style: GoogleFonts.outfit(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white, width: 2)),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 14),
                // Filtre par catégorie
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _catChip(null, filterCategoryId == null, 'Tous'),
                      ...categories.map((c) => _catChip(c.id, filterCategoryId == c.id, c.name)),
                    ],
                  ),
                ),
              ],
            ],
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
                          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(products.isEmpty ? 'Aucun produit.' : 'Aucun résultat.',
                              style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 15)),
                          if (products.isEmpty) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: GradientButton(label: '+ Ajouter un produit', onPressed: openAddSheet, icon: Icons.add_box_rounded),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadData,
                      color: AppColors.primary,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final stockColor = _stockColor(p.quantity);
                          return GestureDetector(
                            onTap: () => openEditSheet(p),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                                    child: p.imageUrl != null
                                        ? Image.network(p.imageUrl!, height: 100, width: double.infinity, fit: BoxFit.cover)
                                        : Container(
                                            height: 100,
                                            color: AppColors.surfaceAlt,
                                            child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 36)),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Catégorie
                                        if (p.categoryId != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.cardViolet,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(categoryName(p.categoryId), style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w600)),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(p.name, style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(formatFCFA(p.price), style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                                        const SizedBox(height: 6),
                                        // Badge stock
                                        Row(
                                          children: [
                                            Container(
                                              width: 8, height: 8,
                                              decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              p.quantity <= 0 ? 'Rupture' : '${p.quantity} en stock',
                                              style: GoogleFonts.outfit(color: stockColor, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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

  Widget _catChip(String? id, bool selected, String label) {
    return GestureDetector(
      onTap: () => setState(() => filterCategoryId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// =============================================
// Sheet : Ajouter un produit
// =============================================
class AddProductSheet extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onSaved;
  final Product? product;

  const AddProductSheet({
    super.key,
    required this.categories,
    required this.onSaved,
    this.product,
  });

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final newCategoryController = TextEditingController();

  String? categoryId;
  File? imageFile;
  String? imageUrlOverride;
  bool saving = false;
  bool addingCategory = false;
  late List<Category> categories;

  @override
  void initState() {
    super.initState();
    categories = List.from(widget.categories);
    if (widget.product != null) {
      final p = widget.product!;
      nameController.text = p.name;
      descController.text = p.description ?? '';
      priceController.text = p.price.toString();
      quantityController.text = p.quantity.toString();
      categoryId = p.categoryId;
      imageUrlOverride = p.imageUrl;
    }
  }

  Future<void> deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
        title: Text('Supprimer le produit', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
        content: Text('Es-tu sûr de vouloir supprimer "${widget.product!.name}" ?', style: GoogleFonts.outfit(color: AppColors.textMuted)),
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
        await supabase.from('products').delete().eq('id', widget.product!.id);
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

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    quantityController.dispose();
    newCategoryController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
    
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ajouter une image', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            if (!isDesktop) ...[
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.cardViolet, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: Text('Galerie photos', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.cardEmerald, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.success),
                ),
                title: Text('Appareil photo', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
            ] else ...[
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.cardViolet, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.folder_open_rounded, color: AppColors.primary),
                ),
                title: Text('Fichier local', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
            ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.link_rounded, color: AppColors.textMuted),
              ),
              title: Text('URL de l\'image', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, 'url'),
            ),
          ],
        ),
      ),
    );

    if (action == 'gallery' || action == 'camera') {
      try {
        final source = action == 'gallery' ? ImageSource.gallery : ImageSource.camera;
        final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
        if (picked != null) {
          setState(() {
            imageFile = File(picked.path);
            imageUrlOverride = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible de lire l\'image : $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    } else if (action == 'url') {
      if (!mounted) return;
      final url = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController(text: imageUrlOverride ?? '');
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
            title: Text('URL de l\'image', style: GoogleFonts.outfit(color: AppColors.text, fontWeight: FontWeight.w700)),
            content: TextField(
              controller: controller,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'https://...', prefixIcon: Icon(Icons.link_rounded, size: 20)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Valider')),
            ],
          );
        },
      );
      if (url != null && url.isNotEmpty) {
        setState(() {
          imageUrlOverride = url;
          imageFile = null;
        });
      }
    }
  }

  Future<void> addCategory() async {
    final name = newCategoryController.text.trim();
    if (name.isEmpty) return;
    setState(() => addingCategory = true);
    try {
      final userId = AuthService.currentUserId;
      // On n'envoie PAS de champ 'color' pour éviter des erreurs si la colonne n'existe pas
      final res = await supabase.from('categories').insert({
        'name': name,
        'user_id': userId,
      }).select().single();
      setState(() {
        categories.add(Category.fromJson(res));
        categoryId = res['id'];
        newCategoryController.clear();
        addingCategory = false;
      });
    } catch (e) {
      setState(() => addingCategory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur catégorie : $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<String?> uploadImage(String userId) async {
    if (imageUrlOverride != null && imageUrlOverride!.isNotEmpty) return imageUrlOverride;
    if (imageFile == null) return null;
    try {
      final ext = imageFile!.path.split('.').last;
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('product-images').upload(path, imageFile!);
      return supabase.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du téléchargement de l\'image : $e'), backgroundColor: AppColors.warning),
        );
      }
      return null;
    }
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom et le prix sont obligatoires.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => saving = true);
    final userId = AuthService.currentUserId;
    final imageUrl = await uploadImage(userId);

    final data = {
      'user_id': userId,
      'name': nameController.text.trim(),
      'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
      'price': double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0,
      'quantity': int.tryParse(quantityController.text) ?? 1,
      'category_id': categoryId,
      'image_url': imageUrl,
    };

    try {
      if (widget.product != null) {
        await supabase.from('products').update(data).eq('id', widget.product!.id);
      } else {
        await supabase.from('products').insert(data);
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
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.product != null ? 'Modifier le produit' : 'Nouveau produit',
                  style: GoogleFonts.outfit(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                if (widget.product != null)
                  IconButton(
                    onPressed: deleteProduct,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Zone image
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(),
              ),
            ),

            const SizedBox(height: 20),

            _label('Nom du produit *'),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Ex: Robe imprimée', prefixIcon: Icon(Icons.label_rounded, size: 20)),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Prix (FCFA) *'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: AppColors.text),
                        decoration: const InputDecoration(hintText: '0', prefixIcon: Icon(Icons.payments_rounded, size: 20)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Stock'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: AppColors.text),
                        decoration: const InputDecoration(hintText: '1', prefixIcon: Icon(Icons.inventory_2_rounded, size: 20)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _label('Description (optionnel)'),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 2,
              style: GoogleFonts.outfit(color: AppColors.text),
              decoration: const InputDecoration(hintText: 'Détails du produit...', prefixIcon: Icon(Icons.notes_rounded, size: 20)),
            ),

            const SizedBox(height: 16),

            _label('Catégorie'),
            const SizedBox(height: 8),

            if (categories.isNotEmpty)
              Wrap(
                spacing: 8, runSpacing: 8,
                children: categories.map((c) {
                  final selected = categoryId == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => categoryId = selected ? null : c.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(c.name, style: GoogleFonts.outfit(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 10),

            // Ajouter catégorie
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newCategoryController,
                    style: GoogleFonts.outfit(color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: '+ Nouvelle catégorie',
                      prefixIcon: Icon(Icons.category_rounded, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: addingCategory ? null : addCategory,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
                    child: addingCategory
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Row(
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

  Widget _buildImagePreview() {
    if (imageFile != null) {
      return Image.file(imageFile!, fit: BoxFit.cover, width: double.infinity);
    }
    if (imageUrlOverride != null && imageUrlOverride!.isNotEmpty) {
      return Image.network(imageUrlOverride!, fit: BoxFit.cover, width: double.infinity);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          Platform.isLinux || Platform.isWindows || Platform.isMacOS ? 'Fichier local / URL d\'image' : 'Galerie / Appareil photo',
          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.outfit(color: AppColors.textSubtle, fontSize: 13, fontWeight: FontWeight.w600),
  );
}
