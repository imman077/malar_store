import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ShopProductCard extends StatelessWidget {
  final Product product;
  final String displayName; // Passed translated name
  final VoidCallback onTap;

  const ShopProductCard({
    super.key,
    required this.product,
    required this.displayName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List? imageBytes = Helpers.decodeBase64ToImage(product.imageBase64);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.lightGray, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area (Expanded)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                ),
                child: imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(
                        LucideIcons.package,
                        size: 40,
                        color: AppColors.gray,
                      ),
              ),
            ),
            
            // Details Area
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.hindMadurai(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Helpers.formatCurrency(product.price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      // Small Add Icon
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
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
  }
}
