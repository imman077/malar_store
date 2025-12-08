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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: imageBytes != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.hindMadurai(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Helpers.formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 15,
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
            ),
          ],
        ),
      ),
    );
  }
}
