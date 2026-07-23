import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../widgets/bottom_nav_bar.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final _dosisController = TextEditingController();
  final _uuid = const Uuid();

  // Catálogos desde SQLite
  List<Map<String, dynamic>> _animales = [];
  List<Map<String, dynamic>> _enfermedades = [];
  List<Map<String, dynamic>> _sintomasDisponibles = [];
  List<Map<String, dynamic>> _medicamentos = [];
  List<Map<String, dynamic>> _medicamentosSugeridos = [];

  // Selecciones
  Map<String, dynamic>? _selectedAnimal;
  Map<String, dynamic>? _selectedEnfermedad;
  Map<String, dynamic>? _selectedMedicamento;
  final Set<String> _sintomasSeleccionados = {};

  bool _isLoading = true;
  bool _isLoadingSintomas = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _dosisController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    // Obtener la finca primero para filtrar animales
    final finca = await LocalDatabase.instance.getFinca();
    final enfermedades = await LocalDatabase.instance.getEnfermedades();
    final medicamentos = await LocalDatabase.instance.getMedicamentos();

    List<Map<String, dynamic>> animales = [];
    if (finca != null) {
      animales = await LocalDatabase.instance
          .getAnimalesByFinca(finca['id'] as String);
    }

    setState(() {
      _animales = animales;
      _enfermedades = enfermedades;
      _medicamentos = medicamentos;
      _isLoading = false;
    });
  }

  Future<void> _onEnfermedadSelected(Map<String, dynamic>? enfermedad) async {
    setState(() {
      _selectedEnfermedad = enfermedad;
      _sintomasDisponibles = [];
      _sintomasSeleccionados.clear();
    });

    if (enfermedad != null) {
      setState(() => _isLoadingSintomas = true);
      final enfermedadId = enfermedad['id'] as String;
      final sintomas = await LocalDatabase.instance.getSintomasByEnfermedad(enfermedadId);
      final sugeridos = await LocalDatabase.instance.getMedicamentosSugeridos(enfermedadId);
      setState(() {
        _sintomasDisponibles = sintomas;
        _medicamentosSugeridos = sugeridos;
        _isLoadingSintomas = false;
      });
    }
  }

  Future<void> _saveRegistroSalud() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnimal == null) {
      _showError('Selecciona un animal');
      return;
    }
    if (_selectedEnfermedad == null) {
      _showError('Selecciona una enfermedad/diagnóstico');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final registroId = _uuid.v4();
      final dosis = double.tryParse(_dosisController.text) ?? 0.0;

      // Preparar lista de tratamientos
      final List<Map<String, dynamic>> tratamientos = [];
      if (_selectedMedicamento != null) {
        tratamientos.add({
          'id': _uuid.v4(),
          'registro_salud_id': registroId,
          'medicamento_id': _selectedMedicamento!['id'],
          'dosis_aplicada': dosis,
          'created_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
        });
      }

      await LocalDatabase.instance.insertRegistroSalud(
        {
          'id': registroId,
          'animal_id': _selectedAnimal!['id'],
          'enfermedad_id': _selectedEnfermedad!['id'],
          'fecha_deteccion': DateTime.now().toIso8601String(),
          'observaciones': _observacionesController.text.trim().isEmpty
              ? null
              : _observacionesController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'is_deleted': 0,
          'is_synced': 0,
        },
        _sintomasSeleccionados.toList(),
        tratamientos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Registro médico guardado para ${_selectedAnimal!['identificacion']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Registro de Sanidad',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingrese los datos médicos del animal.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animal
                          _buildLabel('Animal afectado *'),
                          const SizedBox(height: 8),
                          _animales.isEmpty
                              ? _buildWarning(
                                  'No hay animales registrados. Registra un animal primero.')
                              : DropdownSearch<Map<String, dynamic>>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: const TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: 'Buscar por arete...',
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                  ),
                                  items: _animales,
                                  itemAsString: (a) =>
                                      '${a['identificacion']} — ${a['sexo'] == 2 ? '♀' : '♂'}',
                                  dropdownDecoratorProps:
                                      const DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      hintText: 'Seleccione animal...',
                                      prefixIcon: Icon(Icons.pets),
                                    ),
                                  ),
                                  onChanged: (v) =>
                                      setState(() => _selectedAnimal = v),
                                  selectedItem: _selectedAnimal,
                                ),
                          const SizedBox(height: 16),

                          // Enfermedad
                          _buildLabel('Enfermedad / Diagnóstico *'),
                          const SizedBox(height: 8),
                          DropdownSearch<Map<String, dynamic>>(
                            popupProps: const PopupProps.menu(
                                showSearchBox: true),
                            items: _enfermedades,
                            itemAsString: (e) {
                              final obligatoria =
                                  (e['notificacion_obligatoria'] as int) == 1;
                              return '${e['nombre']}${obligatoria ? ' ⚠️' : ''}';
                            },
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: 'Seleccione diagnóstico...',
                                prefixIcon: Icon(Icons.medical_information),
                              ),
                            ),
                            onChanged: _onEnfermedadSelected,
                            selectedItem: _selectedEnfermedad,
                          ),

                          // Advertencia enfermedad de notificación obligatoria
                          if (_selectedEnfermedad != null &&
                              (_selectedEnfermedad!['notificacion_obligatoria']
                                      as int) ==
                                  1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildWarning(
                                '⚠️ Esta enfermedad es de NOTIFICACIÓN OBLIGATORIA. Reportar a MAGFOR.',
                                color: Colors.red,
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Síntomas dinámicos
                          _buildLabel('Síntomas observados'),
                          const SizedBox(height: 8),
                          if (_selectedEnfermedad == null)
                            Text(
                              'Selecciona una enfermedad para ver los síntomas.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            )
                          else if (_isLoadingSintomas)
                            const Center(
                                child: CircularProgressIndicator(strokeWidth: 2))
                          else if (_sintomasDisponibles.isEmpty)
                            Text(
                              'No hay síntomas registrados para esta enfermedad.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sintomasDisponibles.map((sintoma) {
                                final id = sintoma['id'] as String;
                                final isSelected =
                                    _sintomasSeleccionados.contains(id);
                                return FilterChip(
                                  label: Text(sintoma['nombre'] as String),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _sintomasSeleccionados.add(id);
                                      } else {
                                        _sintomasSeleccionados.remove(id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 16),

                          // Medicamento
                          _buildLabel('Medicamento aplicado'),
                          const SizedBox(height: 8),
                          
                          if (_medicamentosSugeridos.isNotEmpty) ...[
                            Text(
                              'Sugerencias según el historial médico:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: _medicamentosSugeridos.map((m) {
                                return ActionChip(
                                  avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                                  label: Text(m['nombre_comercial'] as String),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  onPressed: () {
                                    final medCompleto = _medicamentos.firstWhere(
                                      (med) => med['id'] == m['id'],
                                      orElse: () => m,
                                    );
                                    setState(() => _selectedMedicamento = medCompleto);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          DropdownSearch<Map<String, dynamic>>(
                            popupProps: const PopupProps.menu(
                                showSearchBox: true),
                            items: _medicamentos,
                            itemAsString: (m) =>
                                '${m['nombre_comercial']} (${m['via_administracion']})',
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: 'Seleccione fármaco...',
                                prefixIcon: Icon(Icons.vaccines),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _selectedMedicamento = v),
                            selectedItem: _selectedMedicamento,
                          ),

                          // Retiro de leche
                          if (_selectedMedicamento != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.water_drop,
                                        color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Retiro de leche: ${_selectedMedicamento!['dias_retiro_leche']} días',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Dosis
                          if (_selectedMedicamento != null) ...[
                            _buildLabel('Dosis aplicada (ml/cc)'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _dosisController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0.0',
                                suffixText: 'ml',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Observaciones
                          _buildLabel('Observaciones (opcional)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _observacionesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Notas adicionales sobre el estado del animal...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveRegistroSalud,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.vaccines),
                      label: Text(_isSaving
                          ? 'Guardando...'
                          : 'Guardar Registro Médico'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/ganado');
        },
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

  Widget _buildWarning(String text, {Color color = Colors.orange}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
