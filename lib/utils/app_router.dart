import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/main_layout.dart';
import '../screens/dashboard_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/credit_manager_screen.dart';
import '../screens/barcode_scanner_screen.dart';
import '../models/product.dart';

class AppRouter {
  // Route names
  static const String splash = '/';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit';
  static const String creditManager = '/credit-manager';
  static const String barcodeScanner = '/barcode-scanner';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainLayout(),
        );

      case dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );

      case products:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProductListScreen(),
        );

      case addProduct:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProductFormScreen(),
        );

      case editProduct:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProductFormScreen(
            product: args?['product'] as Product?,
          ),
        );

      case creditManager:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreditManagerScreen(),
        );

      case barcodeScanner:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BarcodeScannerScreen(),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Navigation helpers
  static void navigateToHome(BuildContext context) =>
      Navigator.pushReplacementNamed(context, home);

  static void navigateToDashboard(BuildContext context) =>
      Navigator.pushNamed(context, dashboard);

  static void navigateToProducts(BuildContext context) =>
      Navigator.pushNamed(context, products);

  static void navigateToAddProduct(BuildContext context) =>
      Navigator.pushNamed(context, addProduct);

  static void navigateToEditProduct(BuildContext context, Product product) =>
      Navigator.pushNamed(
        context,
        editProduct,
        arguments: {'product': product},
      );

  static void navigateToCreditManager(BuildContext context) =>
      Navigator.pushNamed(context, creditManager);

  static Future<String?> navigateToBarcodeScanner(BuildContext context) =>
      Navigator.pushNamed<String>(context, barcodeScanner);
}
