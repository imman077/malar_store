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
import '../providers/category_provider.dart';
import '../models/category.dart';

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
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    var initialDate = state.expiryDate ?? now.add(const Duration(days: 30));
    // Ensure initialDate is not before firstDate (tomorrow)
    if (initialDate.isBefore(tomorrow)) {
      initialDate = tomorrow;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 3650)),
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
       return;
    }

    if (widget.product == null) {
      ref.read(storeProvider.notifier).addProduct(product);
      
      // Schedule expiry reminders
      NotificationService.scheduleExpiryReminders(product);
      
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
      
      // Schedule expiry reminders
      NotificationService.scheduleExpiryReminders(product);
      
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

  Widget _unitButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
  textCapitalization: TextCapitalization.sentences,
  decoration: InputDecoration(
    labelText: t('productName'),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: AppColors.white,
  ),
  onChanged: (value) {
    if (value.isEmpty) {
      notifier.updateName(value);
      return;
    }

    // Auto-capitalize only first character
    final formatted = value[0].toUpperCase() + value.substring(1);

    // Update state only if changed
    if (formatted != value) {
      notifier.updateName(formatted);
    } else {
      notifier.updateName(value);
    }
  },
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: () {
                if (state.category.isEmpty) return null;
                
                final allCats = ref.read(categoryProvider);
                
                // Try to find if state.category matches any En or Ta name
                for (var cat in allCats) {
                  if (cat.nameEn == state.category || cat.nameTa == state.category) {
                    // Return English name for consistency
                    return cat.nameEn;
                  }
                }
                
                // Return stored value if not found, ONLY if it exists in the list (this shouldn't happen usually)
                // But to be safe against crashes:
                return null;
              }(),
              
              decoration: InputDecoration(
                labelText: t('category'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              items: () {
                 final cats = ref.watch(categoryProvider);
                 // Sort categories: Other/மற்றவை always last, rest alphabetically
                 final sortedCats = List<Category>.from(cats);
                 sortedCats.sort((a, b) {
                   final aIsOther = a.nameEn == 'Other' || a.nameTa == 'மற்றவை';
                   final bIsOther = b.nameEn == 'Other' || b.nameTa == 'மற்றவை';
                   
                   if (aIsOther && !bIsOther) return 1;
                   if (!aIsOther && bIsOther) return -1;
                   
                   return a.nameEn.compareTo(b.nameEn);
                 });
                 
                 return sortedCats.map((cat) {
                   return DropdownMenuItem<String>(
                     value: cat.nameEn,
                     child: Text(locale == 'ta' ? cat.nameTa : cat.nameEn),
                   );
                 }).toList();
              }(),
              onChanged: (val) {
                if (val != null) {
                  notifier.updateCategory(val);
                }
              },
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

            // Quantity, Unit & Count
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit selector row
                Row(
                  children: [
                    Text(
                      t('unit') + ':',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _unitButton(t('kg'), state.unit == 'kg', () => notifier.updateUnit('kg')),
                            Container(width: 1, color: Colors.grey),
                            _unitButton(t('g'), state.unit == 'g', () => notifier.updateUnit('g')),
                            Container(width: 1, color: Colors.grey),
                            _unitButton(t('pcs'), state.unit == 'pcs', () => notifier.updateUnit('pcs')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Quantity and Count fields
                if (state.unit != 'pcs') ...[
                  // Show both Quantity and Count for kg/g
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: state.quantity,
                          decoration: InputDecoration(
                            labelText: t('quantity') + ' (${state.unit})',
                            hintText: locale == 'ta' ? 'எ.கா: 250' : 'e.g: 250',
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: state.count,
                          decoration: InputDecoration(
                            labelText: t('count'),
                            hintText: locale == 'ta' ? 'எ.கா: 5' : 'e.g: 5',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: notifier.updateCount,
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Show only Count for pieces
                  TextFormField(
                    initialValue: state.count,
                    decoration: InputDecoration(
                      labelText: t('count'),
                      hintText: locale == 'ta' ? 'எ.கா: 5' : 'e.g: 5',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateCount,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ],
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
