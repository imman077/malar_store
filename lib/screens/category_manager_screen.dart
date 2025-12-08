import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CategoryManagerScreen extends ConsumerStatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  ConsumerState<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends ConsumerState<CategoryManagerScreen> {
  final _formKey = GlobalKey<FormState>();

  void _showAddEditDialog([Category? category]) {
    final isEditing = category != null;
    final nameEnController = TextEditingController(text: category?.nameEn ?? '');
    final nameTaController = TextEditingController(text: category?.nameTa ?? '');

    showDialog(
      context: context,
      builder: (context) {
        final locale = ref.read(languageProvider);
        String t(String key) => TranslationService.translate(key, locale);
        
        return AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameEnController,
                  decoration: const InputDecoration(labelText: 'Name (English)'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameTaController,
                  decoration: const InputDecoration(labelText: 'Name (Tamil)'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newCategory = Category(
                    id: category?.id ?? Helpers.generateId(),
                    nameEn: nameEnController.text.trim(),
                    nameTa: nameTaController.text.trim(),
                  );
                  
                  if (isEditing) {
                    ref.read(categoryProvider.notifier).updateCategory(newCategory);
                  } else {
                    ref.read(categoryProvider.notifier).addCategory(newCategory);
                  }
                  
                  Navigator.pop(context);
                }
              },
              child: Text(t('save')),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) {
        final locale = ref.read(languageProvider);
        String t(String key) => TranslationService.translate(key, locale);
        return AlertDialog(
          title: Text(t('delete')),
          content: Text("${t('deleteConfirm')} ${locale == 'ta' ? category.nameTa : category.nameEn}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () {
                ref.read(categoryProvider.notifier).deleteCategory(category.id);
                Navigator.pop(context);
              },
              child: Text(t('delete'), style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);
    final locale = ref.watch(languageProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Categories', 
          style: GoogleFonts.hindMadurai(fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                locale == 'ta' ? category.nameTa : category.nameEn,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                locale == 'ta' ? category.nameEn : category.nameTa, // Show other language as subtitle
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.edit, color: AppColors.primary),
                    onPressed: () => _showAddEditDialog(category),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: AppColors.red),
                    onPressed: () => _deleteCategory(category),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
