import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../widgets/bottom_nav_bar.dart';

class MilkingRegistrationScreen extends StatefulWidget {
  const MilkingRegistrationScreen({super.key});

  @override
  State<MilkingRegistrationScreen> createState() =>
      _MilkingRegistrationScreenState();
}

class _MilkingRegistrationScreenState
    extends State<MilkingRegistrationScreen> {
  // Jornada: 1=AM, 2=PM (igual que la BD)
  int _jornada = 1;

  List<Map<String, dynamic>> _animales = [];
  // Map: animalId → TextEditingController para litros
  final Map<String, TextEditingController> _controllers = {};

  bool _isLoading = true;
  bool _isSaving = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadAnimales();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAnimales() async {
    final finca = await LocalDatabase.instance.getFinca();
    if (finca != null) {
      // Solo hembras (sexo=1) pueden producir leche
      final todos = await LocalDatabase.instance
          .getAnimalesByFinca(finca['id'] as String);
      final hembras = todos.where((a) => (a['sexo'] as int) == 1).toList();

      // Crear un controller por cada animal hembra
      for (final animal in hembras) {
        final id = animal['id'] as String;
        _controllers[id] = TextEditingController();
      }

      setState(() {
        _animales = hembras;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _guardarProduccion() async {
    // Verificar que al menos un animal tenga litros > 0
    final registros = _animales.where((a) {
      final id = a['id'] as String;
      final litros = double.tryParse(_controllers[id]?.text ?? '') ?? 0.0;
      return litros > 0;
    }).toList();

    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la producción de al menos un animal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now().toIso8601String();

      for (final animal in registros) {
        final id = animal['id'] as String;
        final litros = double.parse(_controllers[id]!.text);
        await LocalDatabase.instance.insertProduccionLeche({
          'id': _uuid.v4(),
          'animal_id': id,
          'fecha': now,
          'jornada': _jornada,
          'volumen_litros': litros,
          'created_at': now,
          'is_deleted': 0,
          'is_synced': 0,
        });
      }

      if (mounted) {
        final totalLitros = registros.fold<double>(0, (sum, a) {
          final id = a['id'] as String;
          return sum + (double.tryParse(_controllers[id]?.text ?? '') ?? 0.0);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Producción guardada: ${totalLitros.toStringAsFixed(1)} L en ${registros.length} animales',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar campos después de guardar
        for (final c in _controllers.values) {
          c.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.agriculture),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Agro-UX Cattle',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_done, color: Colors.green),
            onPressed: () => context.push('/sync'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Selector de Jornada AM/PM
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                                width: 2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _jornada = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _jornada == 1
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.light_mode,
                                            color: _jornada == 1
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                        const SizedBox(width: 8),
                                        Text('Jornada AM',
                                            style: TextStyle(
                                                color: _jornada == 1
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _jornada = 2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _jornada == 2
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.dark_mode,
                                            color: _jornada == 2
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                        const SizedBox(width: 8),
                                        Text('Jornada PM',
                                            style: TextStyle(
                                                color: _jornada == 2
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registro de producción (Litros) — ${_jornada == 1 ? 'Mañana' : 'Tarde'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de animales
                  Expanded(
                    child: _animales.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cruelty_free,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay hembras registradas.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  'Registra animales hembra para comenzar.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _animales.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final animal = _animales[index];
                              final id = animal['id'] as String;
                              return _buildAnimalInput(animal, _controllers[id]!);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _guardarProduccion,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar Producción Total',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
        },
      ),
    );
  }

  Widget _buildAnimalInput(
      Map<String, dynamic> animal, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cruelty_free,
                color: Theme.of(context).colorScheme.onTertiaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal['identificacion'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '♀ Hembra',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: ' L',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
