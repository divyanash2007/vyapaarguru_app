import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/add_product_screen.dart';
import 'screens/send_bill_screen.dart';
import 'screens/dealer_order_screen.dart';
import 'screens/ai_suggestions_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/supplier_management_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const VyapaarGuruApp(),
    ),
  );
}

class VyapaarGuruApp extends StatelessWidget {
  const VyapaarGuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'VyapaarGuru',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.mode,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
        '/add-product': (_) => const AddProductScreen(),
        '/send-bill': (_) => const SendBillScreen(),
        '/dealer': (_) => const DealerOrderScreen(),
        '/ai': (_) => const AiSuggestionsScreen(),
        '/orders': (_) => const OrderHistoryScreen(),
        '/suppliers': (_) => const SupplierManagementScreen(),
      },
    );
  }
}
