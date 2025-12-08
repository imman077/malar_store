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
                    'assets/images/qr_code.png',
                    width: 500,
                    height: 500,
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
  Widget _buildReceiptContent(
      CreditNote credit, String Function(String) t) {
    DateTime? parsed = Helpers.parseDate(credit.date);
    String dateStr = parsed == null
        ? credit.date
        : "${parsed.day}-${parsed.month}-${parsed.year}";

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    t('receipt').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Customer Details Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('customerName'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  credit.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (credit.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        credit.phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Items Section
          Text(
            t('itemsPurchased'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              credit.items,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),
          
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.grey[300]!, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payment Summary
          _receiptRow(
            t('totalAmount'),
            Helpers.formatCurrency(credit.totalAmount),
            fontSize: 15,
          ),
          const SizedBox(height: 8),
          _receiptRow(
            t('paid'),
            Helpers.formatCurrency(credit.amountPaid),
            color: AppColors.primary,
            fontSize: 15,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: credit.pendingAmount > 0 
                  ? const Color(0xFFFFF3F3) 
                  : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: credit.pendingAmount > 0 
                    ? const Color(0xFFFFE0E0) 
                    : const Color(0xFFD0E7FF),
              ),
            ),
            child: _receiptRow(
              t('pending'),
              Helpers.formatCurrency(credit.pendingAmount),
              color: credit.pendingAmount > 0 ? const Color(0xFFDC2626) : AppColors.primary,
              bold: true,
              fontSize: 16,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {bool bold = false, Color? color, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[700],
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
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

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/receipt.png");
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Receipt",
    );
  }


  // ---------------------------------------------------------
  // ADD CREDIT DIALOG (Same as your version)
  // ---------------------------------------------------------
  void _showAddCreditDialog(
      BuildContext context, String locale, String Function(String) t) {
    // Reset form state
    ref.read(creditFormProvider.notifier).reset();
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t('addCredit')),
        content: Consumer(
          builder: (context, ref, child) {
            final formState = ref.watch(creditFormProvider);
            final notifier = ref.read(creditFormProvider.notifier);
            
            return SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    _field(
                      initialValue: formState.customerName,
                      onChanged: notifier.updateCustomerName,
                      label: t('customerName'),
                    ),
                    const SizedBox(height: 10),
                    _field(
                      initialValue: formState.phoneNumber,
                      onChanged: notifier.updatePhoneNumber,
                      label: t('phoneNumber'),
                      keyboard: TextInputType.phone, 
                      required: false,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && !RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                          return 'Enter valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(
                      initialValue: formState.items,
                      onChanged: notifier.updateItems,
                      label: t('itemsPurchased'), 
                      maxLines: 2
                    ),
                    const SizedBox(height: 10),
                    _field(
                      initialValue: formState.totalAmount,
                      onChanged: notifier.updateTotalAmount,
                      label: t('totalAmount'),
                      keyboard: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        final amount = double.tryParse(val);
                        if (amount == null || amount <= 0) return 'Enter valid amount > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(
                      initialValue: formState.amountPaid,
                      onChanged: notifier.updateAmountPaid,
                      label: t('amountPaid'),
                      keyboard: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        final amount = double.tryParse(val);
                        if (amount == null || amount < 0) return 'Enter valid amount >= 0';
                        final total = double.tryParse(formState.totalAmount) ?? 0.0;
                        if (amount > total) return 'Cannot exceed total amount';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t('cancel'))),
          Consumer(
            builder: (context, ref, child) {
              return TextButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  
                  final formState = ref.read(creditFormProvider);
                  final totalAmount = double.tryParse(formState.totalAmount) ?? 0.0;
                  final amountPaid = double.tryParse(formState.amountPaid) ?? 0.0;

                  final credit = CreditNote(
                    id: Helpers.generateId(),
                    customerName: formState.customerName,
                    phoneNumber: formState.phoneNumber,
                    items: formState.items,
                    totalAmount: totalAmount,
                    amountPaid: amountPaid,
                    isPaid: amountPaid >= totalAmount,
                    date: Helpers.formatDateForStorage(DateTime.now()),
                  );

                  ref.read(storeProvider.notifier).addCredit(credit);
                  
                  // Mobile notification
                  final notificationTitle = t('creditAdded');
                  final notificationBody = '${credit.customerName} - ${Helpers.formatCurrency(credit.totalAmount)}';
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
                      type: 'credit_add',
                    ),
                  );
                  
                  Navigator.pop(dialogContext);
                },
                child: Text(t('save')),
              );
            },
          )
        ],
      ),
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
      validator: validator ?? (v) => required && (v == null || v.isEmpty) ? "Required" : null,
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
              child: TextFormField(
                initialValue: ref.watch(creditFormProvider).paymentInput,
                onChanged: ref.read(creditFormProvider.notifier).updatePaymentInput,
                decoration: InputDecoration(labelText: t('amountPaid')),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return t('required');
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'Enter valid amount > 0';
                  if (amount > credit.pendingAmount) return 'Cannot exceed pending amount';
                  return null;
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t('cancel'))),
          Consumer(
            builder: (context, ref, child) {
              return TextButton(
                onPressed: () {
                  if (!key.currentState!.validate()) return;
                  
                  final paymentInput = ref.read(creditFormProvider).paymentInput;
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
                },
                child: Text(t('save')),
              );
            },
          ),
        ],
      ),
    );
  }
}
