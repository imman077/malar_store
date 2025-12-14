import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';

class DiscountCalculatorScreen extends ConsumerStatefulWidget {
  const DiscountCalculatorScreen({super.key});

  @override
  ConsumerState<DiscountCalculatorScreen> createState() =>
      _DiscountCalculatorScreenState();
}

class _DiscountCalculatorScreenState
    extends ConsumerState<DiscountCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _originalPriceController = TextEditingController();
  final _discountController = TextEditingController();

  double _discountAmount = 0.0;
  double _finalPrice = 0.0;
  double _savingsPercentage = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _originalPriceController.addListener(_calculateDiscount);
    _discountController.addListener(_calculateDiscount);
  }

  @override
  void dispose() {
    _originalPriceController.dispose();
    _discountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    final originalPrice = double.tryParse(_originalPriceController.text) ?? 0.0;
    final discountPercentage = double.tryParse(_discountController.text) ?? 0.0;

    // Limit discount percentage to 100%
    final validDiscount = discountPercentage > 100 ? 100 : discountPercentage;

    setState(() {
      _discountAmount = (originalPrice * validDiscount) / 100;
      _finalPrice = originalPrice - _discountAmount;
      _savingsPercentage = validDiscount.toDouble();
    });
  }

  void _clearAll() {
    setState(() {
      _originalPriceController.clear();
      _discountController.clear();
      _discountAmount = 0.0;
      _finalPrice = 0.0;
      _savingsPercentage = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    String t(String key) => TranslationService.translate(key, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('discountCalculator')),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Fields Card
              _buildInputCard(t),
              const SizedBox(height: 20),

              // Results Section
              _buildResultsSection(t),
              const SizedBox(height: 20),

              // Clear Button
              _buildClearButton(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original Price field
          Text(
            t('originalPrice'),
            style: GoogleFonts.hindMadurai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _originalPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: '${t('enter')} ${t('originalPrice')}',
              prefixIcon: const Icon(LucideIcons.indianRupee, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Discount Percentage field
          Text(
            t('discountPercentage'),
            style: GoogleFonts.hindMadurai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _discountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: '${t('enter')} ${t('discount')} %',
              prefixIcon: const Icon(LucideIcons.percent, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(String Function(String) t) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          // Final Price Card (Main Result)
          _buildFinalPriceCard(t),
          const SizedBox(height: 12),

          // Breakdown Cards
          Row(
            children: [
              Expanded(
                child: _buildBreakdownCard(
                  label: t('discountAmount'),
                  value: _discountAmount,
                  icon: LucideIcons.tag,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBreakdownCard(
                  label: t('savings'),
                  value: _savingsPercentage,
                  icon: LucideIcons.trendingDown,
                  color: AppColors.green,
                  isPercentage: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPriceCard(String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.checkCircle,
                color: AppColors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t('finalPrice'),
                style: GoogleFonts.hindMadurai(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.indianRupee,
                color: AppColors.white,
                size: 32,
              ),
              const SizedBox(width: 4),
              Text(
                _finalPrice.toStringAsFixed(2),
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.hindMadurai(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (!isPercentage)
                const Icon(
                  LucideIcons.indianRupee,
                  color: AppColors.black,
                  size: 16,
                ),
              Expanded(
                child: Text(
                  isPercentage
                      ? '${value.toStringAsFixed(1)}%'
                      : value.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton(String Function(String) t) {
    return ElevatedButton.icon(
      onPressed: _clearAll,
      icon: const Icon(LucideIcons.rotateCcw, size: 20),
      label: Text(
        t('clear'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
