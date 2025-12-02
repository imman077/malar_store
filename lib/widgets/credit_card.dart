import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/credit_note.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class CreditCard extends StatelessWidget {
  final CreditNote credit;
  final VoidCallback? onMarkPaid;
  final VoidCallback onDelete;
  final String locale;

  const CreditCard({
    super.key,
    required this.credit,
    this.onMarkPaid,
    required this.onDelete,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 14,
                          color: AppColors.gray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          credit.phoneNumber,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 20),
                onPressed: onDelete,
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            credit.items,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'ta' ? 'மொத்த தொகை' : 'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray,
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(credit.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              if (!credit.isPaid)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      locale == 'ta' ? 'நிலுவை தொகை' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray,
                      ),
                    ),
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
          if (!credit.isPaid && onMarkPaid != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMarkPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  locale == 'ta' ? 'முடிந்தது' : 'Mark as Paid',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (credit.isPaid)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 16,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    locale == 'ta' ? 'செலுத்தப்பட்டது' : 'Paid',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.green,
                      fontWeight: FontWeight.w600,
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
