import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_notification.dart';
import '../providers/language_provider.dart';
import '../models/product.dart';
import '../providers/store_provider.dart';
import '../providers/product_form_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/app_router.dart';
import '../widgets/image_picker_widget.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({
    super.key,
    this.product,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid modifying provider during build
    Future.microtask(() {
      ref.read(productFormProvider.notifier).setProduct(widget.product);
    });
  }

  Future<void> _selectDate() async {
    final state = ref.read(productFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      ref.read(productFormProvider.notifier).updateExpiryDate(picked);
    }
  }

  void _saveProduct() {
    final locale = ref.read(languageProvider);
    String t(String key) => TranslationService.translate(key, locale);

    if (!_formKey.currentState!.validate()) return;
    
    final notifier = ref.read(productFormProvider.notifier);
    final product = notifier.getProduct();

    if (product == null) {
       if (ref.read(productFormProvider).category.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('category') + ' required')),
          );
       }
       return;
    }

    if (widget.product == null) {
      ref.read(storeProvider.notifier).addProduct(product);
      
      // Mobile notification
      final notificationTitle = t('productAdded');
      final notificationBody = product.name;
      NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notificationTitle,
        body: notificationBody,
      );
      
      // Add to notification history
      ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: Helpers.generateId(),
          title: notificationTitle,
          body: notificationBody,
          timestamp: DateTime.now(),
          type: 'product_add',
        ),
      );
    } else {
      ref.read(storeProvider.notifier).updateProduct(product);
      
      // Mobile notification
      final notificationTitle = t('productUpdated');
      final notificationBody = product.name;
      NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notificationTitle,
        body: notificationBody,
      );
      
      // Add to notification history
      ref.read(notificationProvider.notifier).addNotification(
        AppNotification(
          id: Helpers.generateId(),
          title: notificationTitle,
          body: notificationBody,
          timestamp: DateTime.now(),
          type: 'product_edit',
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    final locale = ref.watch(languageProvider);
    
    String t(String key) => TranslationService.translate(key, locale);
    
    // Check if we are editing a product but the state hasn't been populated yet
    if (widget.product != null && state.id != widget.product!.id) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            t('editProduct'),
            style: GoogleFonts.hindMadurai(fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: AppColors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final categories = locale == 'ta' 
        ? ProductCategories.categoriesTamil 
        : ProductCategories.categories;

    final isOtherCategory = state.category == 'Other' || state.category == 'மற்றவை';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.product == null ? t('addProduct') : t('editProduct'),
          style: GoogleFonts.hindMadurai(
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            ImagePickerWidget(
              initialBase64: state.imageBase64,
              onImageSelected: notifier.updateImage,
              uploadText: t('uploadPhoto'),
            ),
            const SizedBox(height: 16),

            // Product Name
            TextFormField(
              initialValue: state.name,
              decoration: InputDecoration(
                labelText: t('productName'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              onChanged: notifier.updateName,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: () {
                // Normalize category to match current language
                if (state.category.isEmpty) return null;
                
                // Check if category exists in current language list
                if (categories.contains(state.category)) {
                  return state.category;
                }
                
                // Map between English and Tamil categories
                final categoryMap = {
                  'Vegetables': 'காய்கறிகள்',
                  'காய்கறிகள்': 'Vegetables',
                  'Masala': 'மசாலா',
                  'மசாலா': 'Masala',
                  'Other': 'மற்றவை',
                  'மற்றவை': 'Other',
                };
                
                // Try to find mapped category
                final mappedCategory = categoryMap[state.category];
                if (mappedCategory != null && categories.contains(mappedCategory)) {
                  // Update the state with the correct language category
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notifier.updateCategory(mappedCategory);
                  });
                  return mappedCategory;
                }
                
                // If it's a custom category, return 'Other' in current language
                return locale == 'ta' ? 'மற்றவை' : 'Other';
              }(),
              decoration: InputDecoration(
                labelText: t('category'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: notifier.updateCategory,
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Custom Category Input (shown only when "Other" is selected)
            if (isOtherCategory) ...[
              TextFormField(
                initialValue: state.customCategory,
                decoration: InputDecoration(
                  labelText: locale == 'ta' ? 'வகை பெயர்' : 'Category Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                onChanged: notifier.updateCustomCategory,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
            ],

            // Price
            TextFormField(
              initialValue: state.price,
              decoration: InputDecoration(
                labelText: t('price'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: notifier.updatePrice,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              initialValue: state.quantity,
              decoration: InputDecoration(
                labelText: t('quantity'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              keyboardType: TextInputType.number,
              onChanged: notifier.updateQuantity,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Expiry Date
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t('expiryDate'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.expiryDate != null
                          ? Helpers.formatDate(state.expiryDate!)
                          : 'Select date',
                      style: TextStyle(
                        color: state.expiryDate != null ? AppColors.black : AppColors.gray,
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t('save'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
