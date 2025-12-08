import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import '../models/cart_item.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareList() async {
    final cartItems = ref.read(cartProvider);
    final total = ref.read(cartProvider.notifier).totalAmount;
    final locale = ref.read(languageProvider);

    // Simple textual share for now
    StringBuffer sb = StringBuffer();
    sb.writeln(locale == 'ta' ? 'மலர் ஸ்டோர் - ஷாப்பிங் பட்டியல்' : 'Malar Store - Shopping List');
    sb.writeln('--------------------------------');
    for (var item in cartItems) {
      sb.writeln('${item.product.name} - ${item.quantity}${item.unit} - ${Helpers.formatCurrency(item.totalPrice)}');
    }
    sb.writeln('--------------------------------');
    sb.writeln('${locale == 'ta' ? 'மொத்தம்' : 'Total'}: ${Helpers.formatCurrency(total)}');

    await Share.share(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final locale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
         title: Text('Cart', style: GoogleFonts.hindMadurai(fontWeight: FontWeight.bold)),
         backgroundColor: AppColors.primary,
         foregroundColor: Colors.white,
         actions: [
             if (cartItems.isNotEmpty)
               IconButton(
                   icon: const Icon(LucideIcons.trash2),
                   onPressed: () {
                       // Confirm clear
                       ref.read(cartProvider.notifier).clearCaer();
                   }, 
               )
         ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shoppingBag, size: 64, color: AppColors.gray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: AppColors.gray),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Product Image Thumbnail
                            Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    color: AppColors.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.product.imageBase64 != null 
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                            Helpers.decodeBase64ToImage(item.product.imageBase64)!,
                                            fit: BoxFit.cover,
                                        ),
                                    )
                                    : const Icon(LucideIcons.package),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Text(
                                            item.product.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                            '${item.quantity} ${item.unit} x ${Helpers.formatCurrency(item.product.price)}/${item.unit}',
                                            style: TextStyle(color: AppColors.gray, fontSize: 13),
                                        ),
                                    ],
                                ),
                            ),
                            // Total for item
                            Text(
                                Helpers.formatCurrency(item.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                            ),
                            // Remove Button
                            IconButton(
                                icon: const Icon(LucideIcons.x, color: Colors.grey),
                                onPressed: () {
                                    ref.read(cartProvider.notifier).removeItem(item);
                                },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Footer
                Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                            ),
                        ],
                    ),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text(
                                        Helpers.formatCurrency(ref.read(cartProvider.notifier).totalAmount),
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                    onPressed: _shareList,
                                    icon: const Icon(LucideIcons.share2),
                                    label: const Text('Share Order'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
              ],
            ),
    );
  }
}
