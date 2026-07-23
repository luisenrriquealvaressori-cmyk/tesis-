import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/local_database.dart';
import '../data/catalog_seeder.dart'; // CatalogSyncService
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _statusText = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Pequeño delay visual
    Future.delayed(const Duration(milliseconds: 500), _runStartupSequence);
  }

  Future<void> _runStartupSequence() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Si no está autenticado, redirigir directo al login
    if (!authProvider.isAuthenticated) {
      if (mounted) context.go('/login');
      return;
    }

    // Si está autenticado, descargar catálogos con su token
    _setStatus('Actualizando catálogos...');
    await CatalogSyncService.downloadAndCache(authProvider.token!);

    // Verificar si el usuario ya configuró su finca
    _setStatus('Verificando configuración...');
    final finca = await LocalDatabase.instance.getFinca();

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (finca != null) {
      // Usuario regresando → ir al dashboard
      context.go('/dashboard');
    } else {
      // Primera vez → configurar la finca
      context.go('/setup');
    }
  }

  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.agriculture,
                        size: 80,
                        color: colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Agro-UX Cattle',
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestión Ganadera Profesional',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                          strokeWidth: 6,
                        ),
                        Icon(Icons.sync, size: 32, color: colorScheme.onPrimary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey<String>(_statusText),
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'SISTEMA OPERATIVO INSTITUCIONAL',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
