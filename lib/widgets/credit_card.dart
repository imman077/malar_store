import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/credit_note.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../services/translation_service.dart';

class CreditCard extends StatelessWidget {
  final CreditNote credit;
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShowQR;
  final VoidCallback? onGenerateReceipt;
  final String locale;

  const CreditCard({
    super.key,
    required this.credit,
    this.onMarkPaid,
    required this.onDelete,
    this.onEdit,
    this.onShowQR,
    this.onGenerateReceipt,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    String t(String key) => TranslationService.translate(key, locale);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Increased margin
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray, width: 1), // Added border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Customer Name & Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05), // Subtle header background
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    credit.customerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credit.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                      if (credit.phoneNumber.isNotEmpty)
                        Text(
                          credit.phoneNumber,
                          style: const TextStyle(fontSize: 12, color: AppColors.gray),
                        ),
                    ],
                  ),
                ),
                // Actions
                if (onGenerateReceipt != null)
                  IconButton(
                    icon: const Icon(Icons.receipt_long, size: 20),
                    onPressed: onGenerateReceipt,
                    tooltip: t('receipt'),
                    color: AppColors.primary,
                  ),
                if (onEdit != null && !credit.isPaid)
                  IconButton(
                    icon: const Icon(LucideIcons.edit2, size: 20),
                    onPressed: onEdit,
                    color: AppColors.primary,
                  ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 20),
                  onPressed: onDelete,
                  color: AppColors.red,
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.lightGray),

          // 2. Items Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                   t('itemsPurchased'),
                   style: const TextStyle(
                     fontSize: 12, 
                     color: AppColors.gray,
                     fontWeight: FontWeight.w600,
                     letterSpacing: 0.5,
                   ),
                 ),
                 const SizedBox(height: 6),
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: AppColors.background,
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Text(
                     credit.items,
                     style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.4),
                   ),
                 ),
              ],
            ),
          ),

          // 3. Financial Summary Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(t('totalAmount'), 
                             style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Helpers.formatCurrency(credit.totalAmount),
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.black
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Paid
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centered
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(t('paid'), 
                             style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Helpers.formatCurrency(credit.amountPaid),
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.green
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pending
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(credit.isPaid ? t('status') : t('pending'), 
                             style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ),
                      FittedBox(
                         fit: BoxFit.scaleDown,
                         child: credit.isPaid
                            ? const Text(
                                "PAID",
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold, 
                                  color: AppColors.green
                                ),
                              )
                            : Text(
                                Helpers.formatCurrency(credit.pendingAmount),
                                style: const TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold, 
                                  color: AppColors.red
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Footer Action (Mark Paid)
          if (!credit.isPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (onShowQR != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: onShowQR,
                        icon: const Icon(LucideIcons.qrCode),
                        color: AppColors.primary,
                        tooltip: "QR Code",
                      ),
                    ),
                  Expanded(
                    child: SizedBox(
                      height: 40, // Fixed height for button
                      child: ElevatedButton.icon(
                        onPressed: onMarkPaid,
                        icon: const Icon(LucideIcons.checkCircle, size: 18),
                        label: FittedBox(child: Text(t('markAsPaid'))), // FittedBox for label
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          if (credit.isPaid)
             Padding(
               padding: const EdgeInsets.only(bottom: 16),
               child: Center(
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                   decoration: BoxDecoration(
                     color: AppColors.green.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                        const Icon(LucideIcons.check, size: 14, color: AppColors.green),
                        const SizedBox(width: 4),
                        Text(
                          t('paid').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: AppColors.green
                          ),
                        ),
                     ],
                   ),
                 ),
               ),
             ),
        ],
      ),
    );
  }
}
