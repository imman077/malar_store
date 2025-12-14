
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/app_notification.dart';
import '../models/credit_note.dart';
import '../providers/credit_form_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/store_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AddCreditDialog extends ConsumerStatefulWidget {
  final String Function(String) t;

  const AddCreditDialog({super.key, required this.t});

  @override
  ConsumerState<AddCreditDialog> createState() => _AddCreditDialogState();
}

class _AddCreditDialogState extends ConsumerState<AddCreditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    // Reset the provider state when the dialog opens to avoid shared state issues
    // Using Future.microtask to avoid modifying provider during build/init cycle if triggered
    Future.microtask(() => ref.read(creditFormProvider.notifier).reset());
  }

  void _addItem(String val) {
    if (val.trim().isNotEmpty) {
      final formState = ref.read(creditFormProvider);
      final currentItems = formState.items.isEmpty 
          ? <String>[] 
          : formState.items.split(', ');
      currentItems.add(val.trim());
      ref.read(creditFormProvider.notifier).updateItems(currentItems.join(', '));
      ref.read(creditFormProvider.notifier).updateItemInput('');
    }
  }

  void _removeItem(String item) {
    final formState = ref.read(creditFormProvider);
    final currentItems = formState.items.split(', ');
    currentItems.remove(item);
    ref.read(creditFormProvider.notifier).updateItems(currentItems.join(', '));
  }

  bool _canSave(CreditFormState formState) {
    if (formState.customerName.trim().isEmpty) return false;
    // Check if there are items OR if there's text in the input that can be added
    if (formState.items.trim().isEmpty && formState.itemInput.trim().isEmpty) return false;
    if (formState.totalAmount.trim().isEmpty) return false;
    if (formState.amountPaid.trim().isEmpty) return false;

    if (formState.phoneNumber.isNotEmpty &&
        !RegExp(r'^[0-9]{10}$').hasMatch(formState.phoneNumber)) {
      return false;
    }

    final totalAmount = double.tryParse(formState.totalAmount);
    final amountPaid = double.tryParse(formState.amountPaid);

    if (totalAmount == null || totalAmount <= 0) return false;
    if (amountPaid == null || amountPaid < 0) return false;
    if (amountPaid > totalAmount) return false;

    return true;
  }

  void _handleSave() {
    // Check for pending item input and add it first
    final currentState = ref.read(creditFormProvider);
    if (currentState.itemInput.trim().isNotEmpty) {
      _addItem(currentState.itemInput);
    }

    // Get updated state
    final formState = ref.read(creditFormProvider);
    
    if (!_canSave(formState)) {
       setState(() {
        _showValidationErrors = true;
      });
      _formKey.currentState?.validate();
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;

    final totalAmountVal = double.tryParse(formState.totalAmount) ?? 0.0;
    final amountPaidVal = double.tryParse(formState.amountPaid) ?? 0.0;

    final credit = CreditNote(
      id: Helpers.generateId(),
      customerName: formState.customerName,
      phoneNumber: formState.phoneNumber,
      items: formState.items,
      totalAmount: totalAmountVal,
      amountPaid: amountPaidVal,
      isPaid: amountPaidVal >= totalAmountVal,
      date: Helpers.formatDateForStorage(DateTime.now()),
    );

    ref.read(storeProvider.notifier).addCredit(credit);

    // Mobile notification
    final notificationTitle = widget.t('creditAdded');
    final notificationBody =
        '${credit.customerName} - ${Helpers.formatCurrency(credit.totalAmount)}';
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(creditFormProvider);
    final notifier = ref.read(creditFormProvider.notifier);

    return AlertDialog(
      title: Text(widget.t('addCredit')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidationErrors
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Customer Name
              TextFormField(
                initialValue: formState.customerName,
                onChanged: notifier.updateCustomerName,
                decoration: InputDecoration(
                  labelText: widget.t('customerName'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? widget.t('customerNameRequired')
                    : null,
              ),
              const SizedBox(height: 10),

              // Phone Number
              TextFormField(
                initialValue: formState.phoneNumber,
                onChanged: notifier.updatePhoneNumber,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: widget.t('phoneNumber'),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != null &&
                      val.isNotEmpty &&
                      !RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                    return widget.t('invalidPhone');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Items Purchased (Chip Input)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          // Key helps to rebuild/clear the field when itemInput changes externally (though less likely here)
                          key: ValueKey('item_field_${formState.items.length}'), 
                          initialValue: formState.itemInput,
                          decoration: InputDecoration(
                            labelText: widget.t('itemsPurchased'),
                            hintText: widget.t('typeItemHint'),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: notifier.updateItemInput,
                          onFieldSubmitted: (val) => _addItem(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: formState.itemInput.trim().isNotEmpty
                            ? () => _addItem(formState.itemInput)
                            : null,
                        icon: const Icon(LucideIcons.plusCircle,
                            size: 30, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (formState.items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: formState.items.split(', ').map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _removeItem(item),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (formState.items.trim().isEmpty && _showValidationErrors)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        widget.t('itemsPurchasedRequired'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Total Amount
              TextFormField(
                initialValue: formState.totalAmount,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*$'),
                  ),
                ],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.updateTotalAmount,
                decoration: InputDecoration(
                  labelText: widget.t('totalAmount'),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return widget.t('required');
                  final amount = double.tryParse(val);
                  if (amount == null || amount <= 0) return widget.t('validAmount');
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Amount Paid
              TextFormField(
                initialValue: formState.amountPaid,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*$'),
                  ),
                ],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.updateAmountPaid,
                decoration: InputDecoration(
                  labelText: widget.t('amountPaid'),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return widget.t('required');
                  final amount = double.tryParse(val);
                  if (amount == null || amount < 0) return widget.t('validPositiveAmount');
                  
                  final totalStr = formState.totalAmount;
                  if (totalStr.trim().isNotEmpty) {
                    final total = double.tryParse(totalStr);
                    if (total != null && amount > total) return widget.t('amountExceedsTotal');
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
          child: Text(widget.t('cancel')),
        ),
        TextButton(
          onPressed: _handleSave,
          child: Text(
            widget.t('save'),
            style: TextStyle(
              color: _canSave(formState) 
                  ? AppColors.primary 
                  : AppColors.primary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
