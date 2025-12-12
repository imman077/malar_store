import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreditFormState {
  final String customerName;
  final String phoneNumber;
  final String items;
  final String totalAmount;
  final String amountPaid;
  final String paymentInput; // For "Add Payment" dialog
  final String itemInput; // For "Items Purchased" chip input

  CreditFormState({
    this.customerName = '',
    this.phoneNumber = '',
    this.items = '',
    this.totalAmount = '',
    this.amountPaid = '0',
    this.paymentInput = '',
    this.itemInput = '',
  });

  CreditFormState copyWith({
    String? customerName,
    String? phoneNumber,
    String? items,
    String? totalAmount,
    String? amountPaid,
    String? paymentInput,
    String? itemInput,
  }) {
    return CreditFormState(
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentInput: paymentInput ?? this.paymentInput,
      itemInput: itemInput ?? this.itemInput,
    );
  }
}

class CreditFormNotifier extends StateNotifier<CreditFormState> {
  CreditFormNotifier() : super(CreditFormState());

  void updateCustomerName(String value) {
    state = state.copyWith(customerName: value);
  }

  void updatePhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  void updateItems(String value) {
    state = state.copyWith(items: value);
  }

  void updateTotalAmount(String value) {
    state = state.copyWith(totalAmount: value);
  }

  void updateAmountPaid(String value) {
    state = state.copyWith(amountPaid: value);
  }

  void updatePaymentInput(String value) {
    state = state.copyWith(paymentInput: value);
  }

  void updateItemInput(String value) {
    state = state.copyWith(itemInput: value);
  }

  void reset() {
    state = CreditFormState();
  }
  
  void resetPaymentInput() {
    state = state.copyWith(paymentInput: '');
  }
}

final creditFormProvider =
    StateNotifierProvider<CreditFormNotifier, CreditFormState>((ref) {
  return CreditFormNotifier();
});
