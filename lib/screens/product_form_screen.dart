import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../models/product.dart';
import '../providers/store_provider.dart';
import '../providers/product_form_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/app_router.dart';
import '../widgets/image_picker_widget.dart';
import 'barcode_scanner_screen.dart';

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
    // Initialize provider with product data or reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productFormProvider.notifier).setProduct(widget.product);
    });
  }

  Future<void> _scanBarcode() async {
    final scannedBarcode = await AppRouter.navigateToBarcodeScanner(context);

    if (scannedBarcode != null) {
      ref.read(productFormProvider.notifier).updateBarcode(scannedBarcode);
    }
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
       // Should be handled by validators, but double check
       if (ref.read(productFormProvider).category.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('category') + ' required')),
          );
       }
       return;
    }

    if (widget.product == null) {
      ref.read(storeProvider.notifier).addProduct(product);
    } else {
      ref.read(storeProvider.notifier).updateProduct(product);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    final locale = ref.watch(languageProvider);
    
    String t(String key) => TranslationService.translate(key, locale);
    
    final categories = locale == 'ta' 
        ? ProductCategories.categoriesTamil 
        : ProductCategories.categories;

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

            // Scan Button
            ElevatedButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(t('scan')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
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
              value: state.category.isNotEmpty ? state.category : null,
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

            // Barcode
            TextFormField(
              key: ValueKey('barcode_${state.barcode}'), // Key forces rebuild on external change
              initialValue: state.barcode,
              decoration: InputDecoration(
                labelText: t('barcode'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              onChanged: notifier.updateBarcode,
            ),
            const SizedBox(height: 16),

            // MRP, Cost, Selling Price
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.mrp,
                    decoration: InputDecoration(
                      labelText: t('mrp'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateMrp,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: state.costPrice,
                    decoration: InputDecoration(
                      labelText: t('costPrice'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateCostPrice,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: state.sellingPrice,
                    decoration: InputDecoration(
                      labelText: t('sellingPrice'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateSellingPrice,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
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
                ),
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
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              initialValue: state.notes,
              decoration: InputDecoration(
                labelText: t('notes'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              maxLines: 3,
              onChanged: notifier.updateNotes,
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
