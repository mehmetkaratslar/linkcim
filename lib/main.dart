// Dosya Konumu: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linkcim/services/database_service.dart';
import 'package:linkcim/screens/home_screen.dart';
import 'package:linkcim/screens/splash_screen.dart';

void main() async {
  // Flutter framework'ün başlatılmasını bekle
  WidgetsFlutterBinding.ensureInitialized();

  // Sistem UI ayarları
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Sadece portrait modunda çalışacak şekilde ayarla
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Veritabanını başlat
    await DatabaseService().initDB();
    print('✅ Veritabanı başarıyla başlatıldı');
  } catch (e) {
    print('❌ Veritabanı başlatma hatası: $e');
  }

  // Uygulamayı başlat
  runApp(LinkciApp());
}

class LinkciApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linkcim',
      debugShowCheckedModeBanner: false,

      // Tema ayarları
      theme: ThemeData(
        // Ana renkler
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[600],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),

        // AppBar teması
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // Floating Action Button teması
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // Card teması
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),

        // Input teması
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Chip teması
        chipTheme: ChipThemeData(
          backgroundColor: Colors.blue[50],
          selectedColor: Colors.blue[100],
          secondarySelectedColor: Colors.blue[200],
          labelStyle: TextStyle(color: Colors.blue[800]),
          secondaryLabelStyle: TextStyle(color: Colors.blue[900]),
          brightness: Brightness.light,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),

        // Button temaları
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue[600],
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Colors.blue[600]!),
          ),
        ),

        // Snackbar teması
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentTextStyle: TextStyle(fontSize: 14),
        ),

        // Visual density
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Platform brightness
        brightness: Brightness.light,

        // Splash factory
        splashFactory: InkRipple.splashFactory,
      ),

      // Başlangıç sayfası
      home: SplashScreen(),

      // Route generator (gelecekte deep linking için)
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => HomeScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => HomeScreen());
          default:
            return MaterialPageRoute(builder: (_) => HomeScreen());
        }
      },
    );
  }
}

// Global error handler
class GlobalErrorHandler {
  static void setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter Hatası: ${details.exception}');
      print('Stack Trace: ${details.stack}');
    };
  }
}
