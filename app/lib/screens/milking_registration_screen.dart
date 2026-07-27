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
  // Set con IDs de animales en período de retiro de leche por medicamentos
  Set<String> _animalesEnRetiroIds = {};
  
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
      final fincaId = finca['id'] as String;

      // Cargar vacas en retiro sanitario (tiempo de carencia de medicamentos)
      final retiroList = await LocalDatabase.instance.getAnimalesEnRetiroLeche(fincaId);
      final retiroIds = retiroList.map((r) => r['animal_id'] as String).toSet();

      // Solo hembras (sexo=1) pueden producir leche
      final todos = await LocalDatabase.instance.getAnimalesByFinca(fincaId);
      final hembras = todos.where((a) => (a['sexo'] as int) == 1).toList();

      // Crear un controller por cada animal hembra
      for (final animal in hembras) {
        final id = animal['id'] as String;
        _controllers[id] = TextEditingController();
      }

      setState(() {
        _animales = hembras;
        _animalesEnRetiroIds = retiroIds;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  double _calcularTotalLitros() {
    double total = 0.0;
    for (final controller in _controllers.values) {
      total += double.tryParse(controller.text.trim()) ?? 0.0;
    }
    return total;
  }

  Future<void> _guardarProduccion() async {
    // Validar valores numéricos erróneos o fuera de límites biológicos reales (> 60L por ordeño)
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val == null || val < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingresa un valor numérico válido para la producción de leche'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (val > 60.0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El valor ingresado supera el límite biológico real (máximo 60 L por ordeño)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Verificar que al menos un animal tenga litros > 0
    final registros = _animales.where((a) {
      final id = a['id'] as String;
      final litros = double.tryParse(_controllers[id]?.text ?? '') ?? 0.0;
      return litros > 0;
    }).toList();

    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la producción de al menos un animal (litros mayor a 0)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar si se incluyeron vacas en retiro de leche y advertir
    final vacasRetiroIngresadas = registros
        .where((a) => _animalesEnRetiroIds.contains(a['id'] as String))
        .toList();

    if (vacasRetiroIngresadas.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('⚠️ Alerta de Leche de Descarte'),
            ],
          ),
          content: Text(
            'Has ingresado producción para ${vacasRetiroIngresadas.length} vaca(s) bajo tratamiento médico (retiro sanitario por medicamentos).\n\n'
            '¿Deseas registrar esta producción? Recuerda que esta leche debe ser descartada y NO mezclarse en el tanque de comercialización.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar y Revisar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar y Registrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
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
        final totalLitros = _calcularTotalLitros();
        final totalKg = (totalLitros * 1.032).toStringAsFixed(1);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Producción guardada: ${totalLitros.toStringAsFixed(1)} L ($totalKg kg) en ${registros.length} animales',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar campos después de guardar
        for (final c in _controllers.values) {
          c.clear();
        }
        setState(() {});
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
    final totalLitros = _calcularTotalLitros();
    final totalKg = (totalLitros * 1.032).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.agriculture),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Ordeño Diario KPI',
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
                  // Selector de Jornada AM/PM y Resumen en vivo
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
                        const SizedBox(height: 12),

                        // Barra resumen en vivo (Litros + Kg + Retiro)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).colorScheme.primaryContainer),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL REGISTRADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  Text(
                                    '${totalLitros.toStringAsFixed(1)} L  ($totalKg kg)',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B4332)),
                                  ),
                                ],
                              ),
                              if (_animalesEnRetiroIds.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade800),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_animalesEnRetiroIds.length} en Retiro',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
                              final isEnRetiro = _animalesEnRetiroIds.contains(id);
                              return _buildAnimalInput(animal, _controllers[id]!, isEnRetiro);
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
          _isSaving ? 'Guardando...' : 'Guardar Producción Total (${totalLitros.toStringAsFixed(1)} L)',
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
      Map<String, dynamic> animal, TextEditingController controller, bool isEnRetiro) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnRetiro ? Colors.red.shade50 : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnRetiro ? Colors.red.shade400 : Theme.of(context).colorScheme.outlineVariant,
          width: isEnRetiro ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnRetiro ? Colors.red.shade100 : Theme.of(context).colorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnRetiro ? Icons.medical_services : Icons.cruelty_free,
              color: isEnRetiro ? Colors.red.shade900 : Theme.of(context).colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      animal['identificacion'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (isEnRetiro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RETIRO',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isEnRetiro ? '⚠️ Bajo Medicamento - Descarte' : '♀ Hembra en Ordeño',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnRetiro ? Colors.red.shade900 : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isEnRetiro ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextFormField(
              controller: controller,
              onChanged: (_) => setState(() {}),
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
                      color: isEnRetiro ? Colors.red.shade400 : Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
