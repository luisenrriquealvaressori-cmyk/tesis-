import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _telefonoController = TextEditingController();
  final _claveController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _claveController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _telefonoController.text.trim(), 
      _claveController.text.trim()
    );

    if (!mounted) return;

    if (success) {
      context.go('/'); // Ir a splash para validar finca e inicializar catálogos
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.lastError ?? 'Error de inicio de sesión'),
          backgroundColor: Theme.of(context).colorScheme.error,
        )
      );
    }
  }

  void _handleGoogleSignIn() {
    // Opción para iniciar sesión o registrarse con Google
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Iniciando vinculación con Google...'),
        duration: Duration(seconds: 2),
      ),
    );
    // Redirigir directamente al formulario de datos de finca/perfil
    context.go('/setup');
  }

  void _navigateToCreateAccountForm() {
    // Ir directamente al formulario de perfil/finca
    context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.agriculture,
                  size: 72,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'AgroStats',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sistema Integrado de Gestión Ganadera',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Selector de pestañas: Iniciar Sesión / Crear Cuenta
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: colorScheme.primary,
                    ),
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    tabs: const [
                      Tab(text: 'Iniciar Sesión'),
                      Tab(text: 'Crear Cuenta'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña 1: Iniciar Sesión
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Ingresa tu teléfono' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _claveController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                            ),
                            const SizedBox(height: 24),
                            
                            Consumer<AuthProvider>(
                              builder: (context, auth, child) {
                                return FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: auth.isLoading ? null : _handleLogin,
                                  child: auth.isLoading 
                                    ? const SizedBox(
                                        width: 24, 
                                        height: 24, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      )
                                    : const Text('Ingresar', style: TextStyle(fontSize: 18)),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            OutlinedButton.icon(
                              onPressed: _handleGoogleSignIn,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Iniciar sesión con Google'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pestaña 2: Crear Cuenta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Crea tu cuenta para comenzar a registrar tu finca y ganado.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          
                          FilledButton.icon(
                            onPressed: _navigateToCreateAccountForm,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Completar Formulario de Registro', style: TextStyle(fontSize: 16)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          OutlinedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Vincular con Cuenta Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Al crear tu cuenta podrás registrar tu Departamento, Municipio, Comarca, Datos de contacto y Coordenadas GPS de tu finca.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
