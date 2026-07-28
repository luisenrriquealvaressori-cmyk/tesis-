import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../widgets/bottom_nav_bar.dart';

class ReproductiveRecordScreen extends StatefulWidget {
  const ReproductiveRecordScreen({super.key});

  @override
  State<ReproductiveRecordScreen> createState() => _ReproductiveRecordScreenState();
}

class _ReproductiveRecordScreenState extends State<ReproductiveRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  final _uuid = const Uuid();

  // Catálogos desde SQLite
  List<Map<String, dynamic>> _vacas = [];
  List<Map<String, dynamic>> _toros = [];
  
  final List<String> _tiposEvento = [
    'Celo',
    'Inseminación',
    'Monta',
    'Preñez',
    'Parto',
    'Aborto'
  ];

  // Selecciones
  Map<String, dynamic>? _selectedVaca;
  Map<String, dynamic>? _selectedToro;
  String? _selectedTipoEvento;
  DateTime _fechaEvento = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    final finca = await LocalDatabase.instance.getFinca();
    List<Map<String, dynamic>> animales = [];
    
    if (finca != null) {
      animales = await LocalDatabase.instance.getAnimalesByFinca(finca['id'] as String);
    } else {
      animales = await LocalDatabase.instance.getAllAnimales();
    }

    setState(() {
      // Filtrar hembras y machos
      _vacas = animales.where((a) => a['sexo'] == 'Hembra').toList();
      _toros = animales.where((a) => a['sexo'] == 'Macho').toList();
      _isLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaEvento,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF16A34A), // Verde
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaEvento) {
      setState(() {
        _fechaEvento = picked;
      });
    }
  }

  Future<void> _guardarRegistro() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVaca == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una vaca')),
      );
      return;
    }
    if (_selectedTipoEvento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona el tipo de evento')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final registro = {
        'id': _uuid.v4(),
        'animal_id': _selectedVaca!['id'],
        'tipo_evento': _selectedTipoEvento,
        'fecha_evento': _fechaEvento.toIso8601String(),
        'toro_id': _selectedToro?['id'],
        'observaciones': _observacionesController.text.trim(),
        'is_synced': 0, // Pendiente de sincronizar
      };

      await LocalDatabase.instance.insertRegistroReproductivo(registro);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento reproductivo guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF16A34A)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Registro Reproductivo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF16A34A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selección de Vaca
              const Text(
                'Vaca a registrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              DropdownSearch<Map<String, dynamic>>(
                items: _vacas,
                itemAsString: (v) => '${v['identificacion']} - ${v['sexo']}',
                selectedItem: _selectedVaca,
                onChanged: (val) => setState(() => _selectedVaca = val),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: 'Seleccione o busque una vaca...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.pets, color: Colors.grey),
                  ),
                ),
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Buscar por arete...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Tipo de Evento
              const Text(
                'Tipo de Evento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTipoEvento,
                hint: const Text('Seleccione el evento'),
                items: _tiposEvento.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedTipoEvento = val;
                    // Resetear toro si no es aplicable
                    if (val != 'Inseminación' && val != 'Monta') {
                      _selectedToro = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.favorite, color: Colors.pink),
                ),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),

              // 3. Fecha del Evento
              const Text(
                'Fecha del Evento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        '${_fechaEvento.day.toString().padLeft(2, '0')}/${_fechaEvento.month.toString().padLeft(2, '0')}/${_fechaEvento.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Toro (Opcional, solo si es Inseminación o Monta)
              if (_selectedTipoEvento == 'Inseminación' || _selectedTipoEvento == 'Monta') ...[
                const Text(
                  'Toro (Semental)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                DropdownSearch<Map<String, dynamic>>(
                  items: _toros,
                  itemAsString: (t) => '${t['identificacion']} - Macho',
                  selectedItem: _selectedToro,
                  onChanged: (val) => setState(() => _selectedToro = val),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Seleccione el toro (opcional)...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.male, color: Colors.blue),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 5. Observaciones
              const Text(
                'Observaciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej. Detalles adicionales sobre el evento...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),

              // Botón Guardar
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _guardarRegistro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar Registro',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: -1),
    );
  }
}
