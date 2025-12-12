
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/credit_note.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ReceiptCard extends StatelessWidget {
  final CreditNote credit;
  final String Function(String) t;

  const ReceiptCard({
    super.key,
    required this.credit,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? parsed = Helpers.parseDate(credit.date);
    String dateStr = parsed == null
        ? credit.date
        : "${parsed.day}-${parsed.month}-${parsed.year}";

    return Container(
      width: 350, // Fixed width for better receipt look
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Smooth rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --------------------------
          // HEADER SECTION
          // --------------------------
          Container(
            padding: const EdgeInsets.only(top: 24, bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            width: double.infinity,
            child: Column(
              children: [
                // Receipt Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1), // Light teal/green similar to image
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t('receipt').toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // --------------------------
          // CUSTOMER SECTION
          // --------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('customerName'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      credit.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (credit.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 8),
                         Row(
                        children: [
                          Icon(LucideIcons.phone, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text(
                            credit.phoneNumber,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------
          // ITEMS SECTION
          // --------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('itemsPurchased'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                     color: const Color(0xFFFAFAFA), // Very light grey bg
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Text(
                    credit.items,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------
          // DIVIDER
          // --------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.grey[200], height: 1),
          ),

          const SizedBox(height: 24),

          // --------------------------
          // TOTALS SECTION
          // --------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildRow(
                  t('totalAmount'),
                  Helpers.formatCurrency(credit.totalAmount),
                  isBold: true,
                ),
                const SizedBox(height: 12),
                _buildRow(
                  t('paid'),
                  Helpers.formatCurrency(credit.amountPaid),
                  color: const Color(0xFF00BFA5), // Teal color
                  isBold: true,
                ),
                const SizedBox(height: 16),
                
                // Pending Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0), // Light red bg
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('pending'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        Helpers.formatCurrency(credit.pendingAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF5350), // Red text
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
