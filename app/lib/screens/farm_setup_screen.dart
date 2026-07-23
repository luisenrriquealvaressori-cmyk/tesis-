import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../widgets/custom_app_bar.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({super.key});

  @override
  State<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends State<FarmSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uuid = const Uuid();

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
    _loadDepartamentos();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartamentos() async {
    setState(() => _isLoadingCatalogs = true);
    final deptos = await LocalDatabase.instance.getAll('departamentos');
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
        throw Exception('Permisos denegados permanentemente.');
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

  Future<void> _saveFinca() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMunicipio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un municipio'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final fincaId = _uuid.v4();
      final comarca = _selectedComarca?['nombre'] as String? ?? '';

      await LocalDatabase.instance.insertFinca({
        'id': fincaId,
        'nombre': _nameController.text.trim(),
        'municipio_id': _selectedMunicipio!['id'],
        'comarca': comarca,
        'latitud': _currentPosition?.latitude ?? 0.0,
        'longitud': _currentPosition?.longitude ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'is_deleted': 0,
        'is_synced': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Finca guardada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        'Configuración de Finca',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa los datos de tu propiedad para comenzar a operar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // --- Sección datos de la finca ---
                      _buildCard(
                        children: [
                          _buildLabel('Nombre de la finca *'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Finca San José',
                              prefixIcon: Icon(Icons.home_work),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                          ),
                          const SizedBox(height: 16),

                          // Departamento
                          _buildLabel('Departamento *'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            key: ValueKey(_selectedDepartamento),
                            initialValue: _selectedDepartamento,
                            hint: const Text('Selecciona un departamento'),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.map),
                            ),
                            items: _departamentos
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d['nombre'] as String),
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
                            key: ValueKey(_selectedMunicipio),
                            initialValue: _selectedMunicipio,
                            hint: Text(
                              _selectedDepartamento == null
                                  ? 'Selecciona departamento primero'
                                  : 'Selecciona un municipio',
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            items: _municipios
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m['nombre'] as String),
                                    ))
                                .toList(),
                            onChanged: _selectedDepartamento == null
                                ? null
                                : _onMunicipioSelected,
                            validator: (v) => v == null ? 'Selecciona un municipio' : null,
                          ),
                          const SizedBox(height: 16),

                          // Comarca
                          _buildLabel('Comarca (opcional)'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            key: ValueKey(_selectedComarca),
                            initialValue: _selectedComarca,
                            hint: Text(
                              _selectedMunicipio == null
                                  ? 'Selecciona municipio primero'
                                  : _comarcas.isEmpty
                                      ? 'No hay comarcas registradas'
                                      : 'Selecciona una comarca',
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.place),
                            ),
                            items: _comarcas
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c['nombre'] as String),
                                    ))
                                .toList(),
                            onChanged:
                                _selectedMunicipio == null || _comarcas.isEmpty
                                    ? null
                                    : (v) => setState(() => _selectedComarca = v),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // --- Sección ubicación GPS ---
                      _buildCard(
                        children: [
                          _buildLabel('Ubicación GPS'),
                          const SizedBox(height: 8),
                          Text(
                            'Captura las coordenadas de tu finca para registros satelitales.',
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
                                ? 'Capturando...'
                                : 'Capturar ubicación satelital'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
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
                                        : 'Ubicación no capturada (opcional)',
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
          onPressed: (_isSaving || _isLoadingCatalogs) ? null : _saveFinca,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Guardando...' : 'Guardar y Empezar'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
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
