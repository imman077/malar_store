import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/credit_note.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CreditCard extends StatelessWidget {
  final CreditNote credit;
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onShowQR;
  final VoidCallback? onGenerateReceipt; // NEW
  final String locale;

  const CreditCard({
    super.key,
    required this.credit,
    this.onMarkPaid,
    required this.onDelete,
    this.onEdit,
    this.onShowQR,
    this.onGenerateReceipt, // NEW
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
                    if (credit.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 14, color: AppColors.gray),
                          SizedBox(width: 4),
                          Text(
                            credit.phoneNumber,
                            style: TextStyle(fontSize: 13, color: AppColors.gray),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (onGenerateReceipt != null)
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: onGenerateReceipt,
                  tooltip: locale == 'ta' ? 'ரசீது' : 'Receipt',
                  color: AppColors.primary,
                ),

              if (onEdit != null && !credit.isPaid)
                IconButton(
                  icon: const Icon(LucideIcons.edit2),
                  onPressed: onEdit,
                  color: AppColors.primary,
                ),

              IconButton(
                icon: const Icon(LucideIcons.trash2),
                onPressed: onDelete,
                color: AppColors.red,
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            credit.items,
            style: TextStyle(fontSize: 13, color: AppColors.gray),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 12),
          Divider(),
          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locale == 'ta' ? 'மொத்த தொகை' : 'Total Amount',
                      style: TextStyle(fontSize: 12, color: AppColors.gray)),
                  Text(
                    Helpers.formatCurrency(credit.totalAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              if (!credit.isPaid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(locale == 'ta' ? 'நிலுவை தொகை' : 'Pending',
                        style: TextStyle(fontSize: 12, color: AppColors.gray)),
                    Text(
                      Helpers.formatCurrency(credit.pendingAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (!credit.isPaid) ...[
            SizedBox(height: 12),

            Row(
              children: [
                if (onShowQR != null)
                  IconButton(
                    onPressed: onShowQR,
                    icon: const Icon(LucideIcons.qrCode),
                    color: AppColors.primary,
                  ),

                Expanded(
                  child: ElevatedButton(
                    onPressed: onMarkPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      locale == 'ta' ? 'முழுவதும் செலுத்தப்பட்டது' : 'Mark as Fully Paid',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          ],

          if (credit.isPaid)
            Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, size: 16, color: AppColors.green),
                  SizedBox(width: 6),
                  Text(
                    locale == 'ta' ? 'செலுத்தப்பட்டது' : 'Paid',
                    style: TextStyle(fontSize: 13, color: AppColors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
