import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/credit_note.dart';
import '../providers/store_provider.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/credit_card.dart';

class CreditManagerScreen extends ConsumerStatefulWidget {
  const CreditManagerScreen({super.key});

  @override
  ConsumerState<CreditManagerScreen> createState() => _CreditManagerScreenState();
}

class _CreditManagerScreenState extends ConsumerState<CreditManagerScreen> {
  String _filterStatus = 'all'; // all, pending, paid

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final allCredits = ref.watch(creditNotesProvider);
    
    String t(String key) => TranslationService.translate(key, locale);

    // Filter credits
    var filteredCredits = allCredits.where((credit) {
      if (_filterStatus == 'pending' && credit.isPaid) return false;
      if (_filterStatus == 'paid' && !credit.isPaid) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(child: _buildFilterTab(t('pending'), 'pending')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterTab(t('paid'), 'paid')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterTab(t('all'), 'all')),
              ],
            ),
          ),

          // Credit List
          Expanded(
            child: filteredCredits.isEmpty
                ? Center(
                    child: Text(
                      t('noCredits'),
                      style: TextStyle(
                        color: AppColors.gray,
                        fontSize: 14,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(storeProvider.notifier).refresh();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCredits.length,
                      itemBuilder: (context, index) {
                        final credit = filteredCredits[index];
                        return CreditCard(
                          credit: credit,
                          locale: locale,
                          onMarkPaid: credit.isPaid
                              ? null
                              : () {
                                  ref.read(storeProvider.notifier).markCreditAsPaid(credit.id);
                                },
                          onEdit: () {
                            _showEditCreditDialog(context, credit, locale, t);
                          },
                          onShowQR: () {
                            _showQRDialog(context, t);
                          },
                          onDelete: () {
                            _showDeleteDialog(context, credit.id, t);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCreditDialog(context, locale, t);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.plus, color: AppColors.white),
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String creditId,
    String Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(storeProvider.notifier).deleteCredit(creditId);
              Navigator.pop(context);
            },
            child: Text(
              t('delete'),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCreditDialog(
    BuildContext context,
    String locale,
    String Function(String) t,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final itemsController = TextEditingController();
    final totalController = TextEditingController();
    final paidController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('addCredit')),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: t('customerName'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('required');
                    }
                    // Regex: Allow letters and spaces
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return t('invalidName');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: t('phoneNumber'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      // Regex: Allow 10 digits
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return t('invalidPhone');
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: itemsController,
                  decoration: InputDecoration(
                    labelText: t('itemsPurchased'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: totalController,
                  decoration: InputDecoration(
                    labelText: t('totalAmount'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('required');
                    }
                    // Regex: Allow numbers and optional decimal
                    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                      return t('invalidAmount');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: paidController,
                  decoration: InputDecoration(
                    labelText: t('amountPaid'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('required');
                    }
                    // Regex: Allow numbers and optional decimal
                    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                      return t('invalidAmount');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final total = double.parse(totalController.text);
                final paid = double.parse(paidController.text);

                final credit = CreditNote(
                  id: Helpers.generateId(),
                  customerName: nameController.text,
                  phoneNumber: phoneController.text,
                  items: itemsController.text,
                  totalAmount: total,
                  amountPaid: paid,
                  isPaid: paid >= total,
                  date: Helpers.formatDateForStorage(DateTime.now()),
                );

                ref.read(storeProvider.notifier).addCredit(credit);
                Navigator.pop(context);
              }
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }

  void _showEditCreditDialog(
    BuildContext context,
    CreditNote credit,
    String locale,
    String Function(String) t,
  ) {
    final paidController = TextEditingController(text: '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('editCredit')),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      _buildBillRow(t('totalAmount'), Helpers.formatCurrency(credit.totalAmount)),
                      const SizedBox(height: 8),
                      _buildBillRow(t('paid'), Helpers.formatCurrency(credit.amountPaid), color: AppColors.green),
                      const Divider(),
                      _buildBillRow(t('pending'), Helpers.formatCurrency(credit.pendingAmount), color: AppColors.red, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t('addPayment'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: paidController,
                  decoration: InputDecoration(
                    labelText: t('amountPaid'),
                    hintText: t('enterAmount'),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('required');
                    }
                    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
                      return t('invalidAmount');
                    }
                    final newPayment = double.parse(value);
                    if (newPayment > credit.pendingAmount) {
                      return t('amountExceedsPending');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newPayment = double.parse(paidController.text);
                final updatedPaid = credit.amountPaid + newPayment;
                
                final updatedCredit = credit.copyWith(
                  amountPaid: updatedPaid,
                  isPaid: updatedPaid >= credit.totalAmount,
                );

                ref.read(storeProvider.notifier).updateCredit(updatedCredit);
                Navigator.pop(context);
              }
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? AppColors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showQRDialog(BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('scanToPay'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/qr_code.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.lightGray,
                  child: const Center(
                    child: Icon(LucideIcons.qrCode, size: 50, color: AppColors.gray),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('close')),
            ),
          ],
        ),
      ),
    );
  }
}
