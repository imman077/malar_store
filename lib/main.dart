import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'models/category.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/constants.dart';
import 'utils/app_router.dart';
import 'screens/splash_screen.dart';
import 'widgets/in_app_notification.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      Hive.registerAdapter(CategoryAdapter());
      await StorageService.init();
      await NotificationService.init();
    } catch (e, stack) {
      debugPrint('Initialization Error: $e\n$stack');
      runApp(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Startup Error',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Global Error: $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InAppNotificationOverlay(
      key: InAppNotificationOverlay.globalKey,
      child: Builder(
        builder: (context) {


          return MaterialApp(
            title: 'Malar Stores',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
              ),
              scaffoldBackgroundColor: AppColors.background,
              useMaterial3: true,
              textTheme: const TextTheme(
                bodyMedium: TextStyle(fontFamily: 'Inter'),
                bodyLarge: TextStyle(fontFamily: 'Inter'),
                labelLarge: TextStyle(fontFamily: 'Inter'),
                titleMedium: TextStyle(fontFamily: 'Inter'),
                titleSmall: TextStyle(fontFamily: 'Inter'),
                headlineSmall: TextStyle(fontFamily: 'Inter'),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                centerTitle: false,
                titleTextStyle: TextStyle(
                  fontFamily: 'HindMadurai',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                labelStyle: const TextStyle(color: AppColors.gray),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 4,
              ),
            ),
            home: const SplashScreen(),
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
