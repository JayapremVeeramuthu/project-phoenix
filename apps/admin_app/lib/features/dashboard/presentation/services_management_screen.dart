import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'services_notifier.dart';

class ServicesManagementScreen extends ConsumerStatefulWidget {
  const ServicesManagementScreen({super.key});

  @override
  ConsumerState<ServicesManagementScreen> createState() => _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends ConsumerState<ServicesManagementScreen> {
  ServiceCategoryDto? _selectedCategory;

  void _showCategoryDialog({ServiceCategoryDto? category}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }

  void _showItemDialog(String categoryId, {ServiceItemDto? item}) {
    showDialog(
      context: context,
      builder: (context) => _ItemDialog(categoryId: categoryId, item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Catalog Manager',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage categories, edit pricing, update descriptions, and service durations.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCategoryDialog(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Categories List
                  Expanded(
                    flex: 2,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListView.builder(
                        itemCount: state.categories.length,
                        itemBuilder: (context, index) {
                          final category = state.categories[index];
                          final isSelected = _selectedCategory?.id == category.id;
                          return ListTile(
                            selected: isSelected,
                            leading: Icon(
                              _getIconData(category.icon),
                              color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                            ),
                            title: Text(category.nameEn, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(category.nameTa),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showCategoryDialog(category: category),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  onPressed: () => ref.read(servicesProvider.notifier).deleteCategory(category.id),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right column: Items List under selected category
                  Expanded(
                    flex: 3,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: _selectedCategory == null
                          ? const Center(
                              child: Text('Select a category to view service catalog items.'),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_selectedCategory!.nameEn} Items',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTealDark),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _showItemDialog(_selectedCategory!.id),
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        label: const Text('Add Item'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryTeal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _selectedCategory!.items?.length ?? 0,
                                      itemBuilder: (context, index) {
                                        final item = _selectedCategory!.items![index];
                                        return ListTile(
                                          title: Text(item.nameEn, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          subtitle: Text('${item.durationMinutes} mins • ₹${item.basePrice.toStringAsFixed(2)}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18),
                                                onPressed: () => _showItemDialog(_selectedCategory!.id, item: item),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                                onPressed: () => ref.read(servicesProvider.notifier).deleteItem(item.id),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'home_repair_service':
      case 'home':
        return Icons.home_repair_service_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      case 'yard':
        return Icons.yard_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  final ServiceCategoryDto? category;
  const _CategoryDialog({this.category});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late TextEditingController _idController;
  late TextEditingController _nameEnController;
  late TextEditingController _nameTaController;
  late TextEditingController _iconController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.category?.id ?? '');
    _nameEnController = TextEditingController(text: widget.category?.nameEn ?? '');
    _nameTaController = TextEditingController(text: widget.category?.nameTa ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? 'home_repair_service');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameEnController.dispose();
    _nameTaController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return AlertDialog(
      title: Text(isEdit ? 'Update Category' : 'Create Category'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEdit)
              TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Unique Category ID')),
            const SizedBox(height: 12),
            TextField(controller: _nameEnController, decoration: const InputDecoration(labelText: 'Category Name (English)')),
            const SizedBox(height: 12),
            TextField(controller: _nameTaController, decoration: const InputDecoration(labelText: 'Category Name (Tamil)')),
            const SizedBox(height: 12),
            TextField(controller: _iconController, decoration: const InputDecoration(labelText: 'Icon Key (e.g. handyman)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
          onPressed: () async {
            Navigator.pop(context);
            final success = isEdit
                ? await ref.read(servicesProvider.notifier).updateCategory(
                      widget.category!.id,
                      nameEn: _nameEnController.text,
                      nameTa: _nameTaController.text,
                      icon: _iconController.text,
                    )
                : await ref.read(servicesProvider.notifier).createCategory(
                      id: _idController.text,
                      nameEn: _nameEnController.text,
                      nameTa: _nameTaController.text,
                      icon: _iconController.text,
                    );
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category settings saved.')),
              );
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _ItemDialog extends ConsumerStatefulWidget {
  final String categoryId;
  final ServiceItemDto? item;
  const _ItemDialog({required this.categoryId, this.item});

  @override
  ConsumerState<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends ConsumerState<_ItemDialog> {
  late TextEditingController _idController;
  late TextEditingController _nameEnController;
  late TextEditingController _nameTaController;
  late TextEditingController _descEnController;
  late TextEditingController _descTaController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.item?.id ?? '');
    _nameEnController = TextEditingController(text: widget.item?.nameEn ?? '');
    _nameTaController = TextEditingController(text: widget.item?.nameTa ?? '');
    _descEnController = TextEditingController(text: widget.item?.descriptionEn ?? '');
    _descTaController = TextEditingController(text: widget.item?.descriptionTa ?? '');
    _priceController = TextEditingController(text: widget.item?.basePrice.toString() ?? '199');
    _durationController = TextEditingController(text: widget.item?.durationMinutes.toString() ?? '60');
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameEnController.dispose();
    _nameTaController.dispose();
    _descEnController.dispose();
    _descTaController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return AlertDialog(
      title: Text(isEdit ? 'Update Service Item' : 'Create Service Item'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEdit)
                TextField(controller: _idController, decoration: const InputDecoration(labelText: 'Unique Item ID')),
              const SizedBox(height: 12),
              TextField(controller: _nameEnController, decoration: const InputDecoration(labelText: 'Item Name (English)')),
              const SizedBox(height: 12),
              TextField(controller: _nameTaController, decoration: const InputDecoration(labelText: 'Item Name (Tamil)')),
              const SizedBox(height: 12),
              TextField(controller: _descEnController, decoration: const InputDecoration(labelText: 'Description (English)')),
              const SizedBox(height: 12),
              TextField(controller: _descTaController, decoration: const InputDecoration(labelText: 'Description (Tamil)')),
              const SizedBox(height: 12),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Base Price (₹)')),
              const SizedBox(height: 12),
              TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Duration (Minutes)')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
          onPressed: () async {
            Navigator.pop(context);
            final success = isEdit
                ? await ref.read(servicesProvider.notifier).updateItem(
                      widget.item!.id,
                      categoryId: widget.categoryId,
                      nameEn: _nameEnController.text,
                      nameTa: _nameTaController.text,
                      descriptionEn: _descEnController.text,
                      descriptionTa: _descTaController.text,
                      basePrice: double.tryParse(_priceController.text) ?? 199.0,
                      durationMinutes: int.tryParse(_durationController.text) ?? 60,
                    )
                : await ref.read(servicesProvider.notifier).createItem(
                      id: _idController.text,
                      categoryId: widget.categoryId,
                      nameEn: _nameEnController.text,
                      nameTa: _nameTaController.text,
                      descriptionEn: _descEnController.text,
                      descriptionTa: _descTaController.text,
                      basePrice: double.tryParse(_priceController.text) ?? 199.0,
                      durationMinutes: int.tryParse(_durationController.text) ?? 60,
                    );
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Service Catalog item saved.')),
              );
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
