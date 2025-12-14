import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../services/translation_service.dart';
import '../utils/constants.dart';

class WeightLiquidCalculatorScreen extends ConsumerStatefulWidget {
  const WeightLiquidCalculatorScreen({super.key});

  @override
  ConsumerState<WeightLiquidCalculatorScreen> createState() =>
      _WeightLiquidCalculatorScreenState();
}

class _WeightLiquidCalculatorScreenState
    extends ConsumerState<WeightLiquidCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isWeightMode = true; // true = Weight, false = Liquid
  String _selectedUnit = 'g'; // kg, g, L, ml - default to grams
  double _totalPrice = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController.forward();

    _priceController.addListener(_calculateTotal);
    _quantityController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;

    double actualQuantity = quantity;

    // Convert to base unit (kg or L)
    if (_selectedUnit == 'g') {
      actualQuantity = quantity / 1000; // Convert grams to kg
    } else if (_selectedUnit == 'ml') {
      actualQuantity = quantity / 1000; // Convert ml to L
    }

    setState(() {
      _totalPrice = price * actualQuantity;
    });
  }

  void _clearAll() {
    setState(() {
      _priceController.clear();
      _quantityController.clear();
      _totalPrice = 0.0;
    });
  }

  void _toggleMode() {
    setState(() {
      _isWeightMode = !_isWeightMode;
      _selectedUnit = _isWeightMode ? 'g' : 'ml'; // Default to smaller units
      _clearAll();
    });
  }

  void _changeUnit(String unit) {
    setState(() {
      _selectedUnit = unit;
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    String t(String key) => TranslationService.translate(key, locale);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('weightLiquidCalculator')),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode Toggle Card
              _buildModeToggleCard(t),
              const SizedBox(height: 20),

              // Input Fields Card
              _buildInputCard(t),
              const SizedBox(height: 20),

              // Result Card
              _buildResultCard(t),
              const SizedBox(height: 20),

              // Clear Button
              _buildClearButton(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggleCard(String Function(String) t) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: t('weight'),
              icon: LucideIcons.scale,
              isSelected: _isWeightMode,
              onTap: () {
                if (!_isWeightMode) _toggleMode();
              },
            ),
          ),
          Expanded(
            child: _buildModeButton(
              label: t('liquid'),
              icon: LucideIcons.droplet,
              isSelected: !_isWeightMode,
              onTap: () {
                if (_isWeightMode) _toggleMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.gray,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.hindMadurai(
                color: isSelected ? AppColors.white : AppColors.gray,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
          // Price per unit field
          Text(
            t('pricePerUnit'),
            style: GoogleFonts.hindMadurai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              hintText: '${t('enter')} ${t('price')}',
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

          // Quantity field with unit selector
          Text(
            t('quantity'),
            style: GoogleFonts.hindMadurai(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: '${t('enter')} ${t('quantity')}',
                    prefixIcon: Icon(
                      _isWeightMode ? LucideIcons.scale : LucideIcons.droplet,
                      size: 20,
                    ),
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitSelector(t),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(String Function(String) t) {
    final units = _isWeightMode ? ['kg', 'g'] : ['L', 'ml'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: units.map((unit) {
          final isSelected = _selectedUnit == unit;
          return InkWell(
            onTap: () => _changeUnit(unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  unit,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.gray,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultCard(String Function(String) t) {
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
          Text(
            t('totalPrice'),
            style: GoogleFonts.hindMadurai(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withOpacity(0.9),
            ),
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
                _totalPrice.toStringAsFixed(2),
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
