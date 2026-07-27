import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../data/local_database.dart';
import '../data/catalog_seeder.dart';
import '../providers/auth_provider.dart';
import '../utils/id_generator.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/notification_service.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  State<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends State<FarmSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _farmNameController = TextEditingController(); // OPCIONAL
  final _comarcaController = TextEditingController();

  // Catálogos cargados desde SQLite
  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _municipios = [];
  List<Map<String, dynamic>> _comarcas = [];

  // Selecciones actuales
  Map<String, dynamic>? _selectedDepartamento;
  Map<String, dynamic>? _selectedMunicipio;
  Map<String, dynamic>? _selectedComarca;

  bool _isGettingLocation = false;
  bool _isSaving = false;
  bool _isLoadingCatalogs = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    _comarcaController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    setState(() => _isLoadingCatalogs = true);
    final authProvider = context.read<AuthProvider>();
    final authNombre = authProvider.nombre;
    final token = authProvider.token;

    // Conectarse al servidor para descargar los catálogos maestros actualizados
    await CatalogSyncService.downloadAndCache(token);
    await CatalogSyncService.ensureBaseCatalogs();

    final deptos = await LocalDatabase.instance.getAll('departamentos');
    
    if (authNombre != null && authNombre.isNotEmpty) {
      _fullNameController.text = authNombre;
    }
    
    setState(() {
      _departamentos = deptos;
      _isLoadingCatalogs = false;
    });
  }

  Future<void> _onDepartamentoSelected(Map<String, dynamic>? depto) async {
    setState(() {
      _selectedDepartamento = depto;
      _selectedMunicipio = null;
      _selectedComarca = null;
      _municipios = [];
      _comarcas = [];
    });
    if (depto != null) {
      final munis = await LocalDatabase.instance
          .getMunicipiosByDepartamento(depto['id'] as String);
      setState(() => _municipios = munis);
    }
  }

  Future<void> _onMunicipioSelected(Map<String, dynamic>? muni) async {
    setState(() {
      _selectedMunicipio = muni;
      _selectedComarca = null;
      _comarcas = [];
    });
    if (muni != null) {
      final coms = await LocalDatabase.instance
          .getComarcasByMunicipio(muni['id'] as String);
      setState(() => _comarcas = coms);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Servicios de ubicación deshabilitados.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveOnboardingAndFarm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMunicipio == null) {
      AppNotificationService.warning(context,
        'Municipio requerido',
        subtitle: 'Selecciona el municipio de tu finca para continuar',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final comarcaText = _selectedComarca?['nombre'] as String? ?? _comarcaController.text.trim();
      final municipioId = _selectedMunicipio!['id'] as String;

      // 1. Si no estaba autenticado, registrar usuario
      if (!authProvider.isAuthenticated) {
        final registered = await authProvider.register(
          nombre: _fullNameController.text.trim(),
          telefono: _phoneController.text.trim(),
          clave: _passwordController.text.trim(),
          municipioId: municipioId,
          comarca: comarcaText,
        );

        if (!registered) {
          await authProvider.setLocalSession(
            nombre: _fullNameController.text.trim(),
            telefono: _phoneController.text.trim(),
          );
        }
      }

      // 2. Definir Nombre de Finca (OPCIONAL: si no lo ingresa, se usa por defecto)
      String farmName = _farmNameController.text.trim();
      if (farmName.isEmpty) {
        final nameOwner = _fullNameController.text.trim();
        farmName = nameOwner.isNotEmpty ? 'Finca de $nameOwner' : 'Finca Principal';
      }

      final fincaId = IdGenerator.forFinca(authProvider.usuarioId!, farmName);

      // 3. Insertar Finca en SQLite local
      await LocalDatabase.instance.insertFinca({
        'id': fincaId,
        'nombre': farmName,
        'municipio_id': municipioId,
        'comarca': comarcaText,
        'latitud': _currentPosition?.latitude ?? 0.0,
        'longitud': _currentPosition?.longitude ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'is_deleted': 0,
        'is_synced': 0,
      });

      if (mounted) {
        AppNotificationService.success(context,
          'Finca registrada exitosamente',
          subtitle: '$farmName está lista para operar',
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        AppNotificationService.error(context,
          'Error al guardar',
          subtitle: e.toString().length > 60 ? '${e.toString().substring(0, 60)}...' : e.toString(),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: _isLoadingCatalogs
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registro de Cuenta y Finca',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa tus datos personales y los de tu propiedad para comenzar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // --- Sección 1: Datos Personales del Ganadero ---
                      _buildCard(
                        title: '1. Datos Personales',
                        children: [
                          _buildLabel('Nombre Completo *'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Juan Pérez Castellón',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre completo' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Número de Teléfono *'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Ej: 88889999',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Ingresa tu teléfono';
                              final clean = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
                              if (clean.length < 8 || !RegExp(r'^\d+$').hasMatch(clean)) {
                                return 'Ingresa un número telefónico válido (mínimo 8 dígitos)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (!authProvider.isAuthenticated) ...[
                            _buildLabel('Contraseña *'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Crea una contraseña segura',
                                prefixIcon: Icon(Icons.lock),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa una contraseña';
                                if (v.trim().length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- Sección 2: Ubicación Geográfica ---
                      _buildCard(
                        title: '2. Ubicación Geográfica',
                        children: [
                          // Departamento
                          _buildLabel('Departamento *'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            key: ValueKey('depto_${_selectedDepartamento?['id'] ?? 'none'}'),
                            isExpanded: true,
                            initialValue: _selectedDepartamento,
                            hint: const Text(
                              'Selecciona departamento',
                              overflow: TextOverflow.ellipsis,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.map),
                            ),
                            items: _departamentos
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d['nombre'] as String,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: _onDepartamentoSelected,
                            validator: (v) => v == null ? 'Selecciona un departamento' : null,
                          ),
                          const SizedBox(height: 16),

                          // Municipio
                          _buildLabel('Municipio *'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            key: ValueKey('muni_${_selectedMunicipio?['id'] ?? 'none'}'),
                            isExpanded: true,
                            initialValue: _selectedMunicipio,
                            hint: Text(
                              _selectedDepartamento == null
                                  ? 'Selecciona departamento primero'
                                  : 'Selecciona un municipio',
                              overflow: TextOverflow.ellipsis,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            items: _municipios
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m['nombre'] as String,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: _selectedDepartamento == null
                                ? null
                                : _onMunicipioSelected,
                            validator: (v) => v == null ? 'Selecciona un municipio' : null,
                          ),
                          const SizedBox(height: 16),

                          // Comarca
                          _buildLabel('Comarca *'),
                          const SizedBox(height: 8),
                          if (_comarcas.isNotEmpty) ...[
                            DropdownButtonFormField<Map<String, dynamic>>(
                              key: ValueKey('comarca_${_selectedComarca?['id'] ?? 'none'}'),
                              isExpanded: true,
                              initialValue: _selectedComarca,
                              hint: const Text(
                                'Selecciona una comarca',
                                overflow: TextOverflow.ellipsis,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.place),
                              ),
                              items: _comarcas
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c['nombre'] as String,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedComarca = v),
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _comarcaController,
                              decoration: const InputDecoration(
                                hintText: 'Ej: Comarca San Antonio',
                                prefixIcon: Icon(Icons.place),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- Sección 3: Datos de la Finca (Nombre Opcional) ---
                      _buildCard(
                        title: '3. Información de la Finca',
                        children: [
                          _buildLabel('Nombre de la Finca (Opcional)'),
                          const SizedBox(height: 4),
                          Text(
                            'Si lo dejas en blanco, se asignará un nombre predeterminado.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _farmNameController,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Finca San José (Opcional)',
                              prefixIcon: Icon(Icons.agriculture),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- Sección 4: Ubicación GPS ---
                      _buildCard(
                        title: '4. Coordenadas GPS',
                        children: [
                          Text(
                            'Captura la posición GPS de tu finca para el registro cartográfico.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isGettingLocation ? null : _captureLocation,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(_isGettingLocation
                                ? 'Capturando Coordenadas...'
                                : 'Capturar Ubicación GPS'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _currentPosition != null
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentPosition != null
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _currentPosition != null
                                      ? Icons.check_circle
                                      : Icons.location_off,
                                  color: _currentPosition != null
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _currentPosition != null
                                        ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}'
                                        : 'Ubicación GPS no capturada aún (opcional)',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: ElevatedButton.icon(
          onPressed: (_isSaving || _isLoadingCatalogs) ? null : _saveOnboardingAndFarm,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle),
          label: Text(_isSaving ? 'Guardando...' : 'Completar y Entrar'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
