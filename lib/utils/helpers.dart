import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  static String formatDate(DateTime date) {
    return DateFormat(DateFormats.display).format(date);
  }

  static String formatDateForStorage(DateTime date) {
    return DateFormat(DateFormats.storage).format(date);
  }

  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateFormat(DateFormats.storage).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // NEW — required for Receipt generation
  static String formatDateDisplay(String storedDate) {
    try {
      final d = parseDate(storedDate)!;
      return "${d.day}-${d.month}-${d.year}";
    } catch (_) {
      return storedDate;
    }
  }

  static ExpiryStatus getExpiryStatus(String? expiryDateString) {
    if (expiryDateString == null || expiryDateString.isEmpty) {
      return ExpiryStatus.fresh;
    }

    final expiryDate = parseDate(expiryDateString);
    if (expiryDate == null) return ExpiryStatus.fresh;

    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (difference < 0) return ExpiryStatus.expired;
    if (difference <= 30) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.fresh;
  }

  static String? encodeImageToBase64(Uint8List? imageBytes) {
    if (imageBytes == null) return null;
    return base64Encode(imageBytes);
  }

  static Uint8List? decodeBase64ToImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
