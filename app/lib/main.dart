import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/farm_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/health_record_screen.dart';
import 'screens/animal_registration_screen.dart';
import 'screens/milking_registration_screen.dart';
import 'screens/sync_center_screen.dart';
import 'screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.initAuth(); // Cargar token desde SharedPreferences

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: const AgroUxApp(),
    ),
  );
}


final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const FarmSetupScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/health_record',
      builder: (context, state) => const HealthRecordScreen(),
    ),
    GoRoute(
      path: '/register_animal',
      builder: (context, state) => const AnimalRegistrationScreen(),
    ),
    GoRoute(
      path: '/milking',
      builder: (context, state) => const MilkingRegistrationScreen(),
    ),
    GoRoute(
      path: '/sync',
      builder: (context, state) => const SyncCenterScreen(),
    ),
    GoRoute(
      path: '/ganado',
      builder: (context, state) => const GanadoScreen(),
    ),
  ],
);

class AgroUxApp extends StatelessWidget {
  const AgroUxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Agro-UX Cattle',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
