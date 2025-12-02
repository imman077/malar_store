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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('addCredit')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: t('customerName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: t('phoneNumber'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemsController,
                decoration: InputDecoration(
                  labelText: t('itemsPurchased'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController,
                decoration: InputDecoration(
                  labelText: t('totalAmount'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: paidController,
                decoration: InputDecoration(
                  labelText: t('amountPaid'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  itemsController.text.isEmpty ||
                  totalController.text.isEmpty) {
                return;
              }

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
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }
}
