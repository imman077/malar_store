class CreditNote {
  final String id;
  final String customerName;
  final String phoneNumber;
  final String items;
  final double totalAmount;
  final double amountPaid;
  final bool isPaid;
  final String date; // YYYY-MM-DD format

  CreditNote({
    required this.id,
    required this.customerName,
    required this.phoneNumber,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    required this.isPaid,
    required this.date,
  });

  // Calculate pending amount
  double get pendingAmount => totalAmount - amountPaid;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'items': items,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'isPaid': isPaid,
      'date': date,
    };
  }

  // Create from JSON
  factory CreditNote.fromJson(Map<String, dynamic> json) {
    return CreditNote(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      items: json['items'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
      date: json['date'] as String,
    );
  }

  // Copy with method for updates
  CreditNote copyWith({
    String? id,
    String? customerName,
    String? phoneNumber,
    String? items,
    double? totalAmount,
    double? amountPaid,
    bool? isPaid,
    String? date,
  }) {
    return CreditNote(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      isPaid: isPaid ?? this.isPaid,
      date: date ?? this.date,
    );
  }
}
