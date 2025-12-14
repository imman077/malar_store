import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/app_notification.dart';
import '../models/credit_note.dart';
import '../providers/notification_provider.dart';
import '../providers/store_provider.dart';
import '../providers/language_provider.dart';
import '../providers/credit_form_provider.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/credit_card.dart';
import '../widgets/add_credit_dialog.dart';
import '../widgets/receipt_card.dart';

class CreditManagerScreen extends ConsumerStatefulWidget {
  const CreditManagerScreen({super.key});

  @override
  ConsumerState<CreditManagerScreen> createState() =>
      _CreditManagerScreenState();
}

class _CreditManagerScreenState extends ConsumerState<CreditManagerScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final allCredits = ref.watch(creditNotesProvider);
    String t(String key) => TranslationService.translate(key, locale);

    final filteredCredits = allCredits.where((credit) {
      if (_filterStatus == 'pending' && credit.isPaid) return false;
      if (_filterStatus == 'paid' && !credit.isPaid) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildFilterTabs(t),
          Expanded(
            child: filteredCredits.isEmpty
                ? Center(
                    child: Text(
                      t('noCredits'),
                      style: const TextStyle(color: AppColors.gray),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async =>
                        await ref.read(storeProvider.notifier).refresh(),
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
                              : () => ref
                                  .read(storeProvider.notifier)
                                  .markCreditAsPaid(credit.id),

                          // QR icon
                          onShowQR: () => _showQRDialog(context, t),

                          // Receipt icon
                          onGenerateReceipt: () =>
                              _showReceiptDialog(context, credit, t),

                          onEdit: () =>
                              _showEditCreditDialog(context, credit, locale, t),

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

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => _showAddCreditDialog(context, locale, t),
      //   backgroundColor: AppColors.primary,
      //   child: const Icon(LucideIcons.plus, color: Colors.white),
      // ),
    );
  }

  // ---------------------------------------------------------
  // FILTER TABS
  // ---------------------------------------------------------
  Widget _buildFilterTabs(String Function(String) t) {
    return Container(
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
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final selected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.lightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.black,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // DELETE CONFIRMATION
  // ---------------------------------------------------------
  void _showDeleteDialog(
      BuildContext context, String id, String Function(String) t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          TextButton(
            onPressed: () {
              // Get credit object before deleting
              final credit = ref.read(creditNotesProvider).firstWhere((c) => c.id == id);
              
              // Mobile notification
              final notificationTitle = t('creditDeleted');
              final notificationBody = credit.customerName;
              NotificationService.showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: notificationTitle,
                body: notificationBody,
              );
              
              // Add to notification history
              ref.read(notificationProvider.notifier).addNotification(
                AppNotification(
                  id: Helpers.generateId(),
                  title: notificationTitle,
                  body: notificationBody,
                  timestamp: DateTime.now(),
                  type: 'credit_delete',
                ),
              );
              
              ref.read(storeProvider.notifier).deleteCredit(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // QR DIALOG
  // ---------------------------------------------------------
  void _showQRDialog(BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t('pay'),
                  textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/images/store_qr_code.jpg',
                    width: 450,
                    height: 450,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.close, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // RECEIPT SCREEN (NO QR)
  // ---------------------------------------------------------
  void _showReceiptDialog(
      BuildContext context, CreditNote credit, String Function(String) t) {
    final GlobalKey key = GlobalKey();

    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: RepaintBoundary(
                          key: key,
                          child: _buildReceiptContent(credit, t),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SHARE BUTTON - Circular, Right Aligned
                    Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton(
                        onPressed: () => _shareReceipt(key),
                        backgroundColor: AppColors.primary,
                        child: const Icon(Icons.share, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 16,
              top: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // RECEIPT CONTENT UI (ENHANCED)
  // ---------------------------------------------------------
  // ---------------------------------------------------------
  // RECEIPT CONTENT UI (ENHANCED)
  // ---------------------------------------------------------
  Widget _buildReceiptContent(
      CreditNote credit, String Function(String) t) {
    return ReceiptCard(credit: credit, t: t);
  }

  // ---------------------------------------------------------
  // CAPTURE RECEIPT
  // ---------------------------------------------------------
  Future<Uint8List> _captureReceipt(GlobalKey key) async {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);

    return data!.buffer.asUint8List();
  }

  // ---------------------------------------------------------
  // SHARE RECEIPT IMAGE (WhatsApp, Gmail, Telegram, etc.)
  // ---------------------------------------------------------
  Future<void> _shareReceipt(GlobalKey key) async {
    final Uint8List bytes = await _captureReceipt(key);

    // Use XFile.fromData which works on Web, Android, and iOS
    final xFile = XFile.fromData(
      bytes,
      mimeType: 'image/png',
      name: 'receipt.png',
    );

    await Share.shareXFiles(
      [xFile],
      text: "Receipt",
    );
  }


// ---------------------------------------------------------
// ADD CREDIT DIALOG
// ---------------------------------------------------------
void _showAddCreditDialog(
    BuildContext context, String locale, String Function(String) t) {
  showDialog(
    context: context,
    builder: (context) => AddCreditDialog(t: t),
  );
}


Widget _field({
  required String initialValue,
  required ValueChanged<String> onChanged,
  required String label,
  int maxLines = 1,
  TextInputType? keyboard,
  bool required = true,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    initialValue: initialValue,
    onChanged: onChanged,
    maxLines: maxLines,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: validator ?? (v) {
      if (required && (v == null || v.trim().isEmpty)) {
        return "Required";
      }
      return null;
    },
  );
}



  // ---------------------------------------------------------
  // EDIT PAYMENT DIALOG (kept minimal)
  // ---------------------------------------------------------
  void _showEditCreditDialog(
      BuildContext context, CreditNote credit, String locale, String Function(String) t) {
    // Reset payment input
    ref.read(creditFormProvider.notifier).resetPaymentInput();
    
    final key = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('addPayment')),
        content: Consumer(
          builder: (context, ref, child) {
            return Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('pending'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          Helpers.formatCurrency(credit.pendingAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    initialValue: ref.watch(creditFormProvider).paymentInput,
                    onChanged: ref.read(creditFormProvider.notifier).updatePaymentInput,
                    decoration: InputDecoration(
                      labelText: t('amountPaid'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return t('required');
                      final amount = double.tryParse(v);
                      if (amount == null || amount <= 0) return 'Enter valid amount > 0';
                      if (amount > credit.pendingAmount) return 'Cannot exceed pending amount';
                      return null;
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t('cancel'))),
          Consumer(
            builder: (context, ref, child) {
              final paymentInput = ref.watch(creditFormProvider).paymentInput;
              
              bool isValid = true;
              final amount = double.tryParse(paymentInput);
              
              if (amount == null || amount <= 0) isValid = false;
              if (amount != null && amount > credit.pendingAmount) isValid = false;

              return TextButton(
                onPressed: isValid ? () {
                  if (!key.currentState!.validate()) return;
                  
                  final added = double.tryParse(paymentInput) ?? 0.0;
                  
                  final updated = credit.copyWith(
                    amountPaid: credit.amountPaid + added,
                    isPaid: (credit.amountPaid + added) >= credit.totalAmount,
                  );

                  ref.read(storeProvider.notifier).updateCredit(updated);
                  Navigator.pop(dialogContext);
                  
                  // Mobile notification with pending amount
                  final notificationTitle = t('paymentUpdated');
                  final notificationBody = updated.isPaid 
                      ? '${credit.customerName} - ${t('paid')}'
                      : '${credit.customerName} - ${t('pending')}: ${Helpers.formatCurrency(updated.pendingAmount)}';
                  
                  NotificationService.showNotification(
                    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    title: notificationTitle,
                    body: notificationBody,
                  );
                  
                  // Add to notification history
                  ref.read(notificationProvider.notifier).addNotification(
                    AppNotification(
                      id: Helpers.generateId(),
                      title: notificationTitle,
                      body: notificationBody,
                      timestamp: DateTime.now(),
                      type: 'credit_edit',
                    ),
                  );
                } : null,
                child: Text(
                  t('save'),
                  style: TextStyle(
                    color: isValid ? AppColors.primary : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
