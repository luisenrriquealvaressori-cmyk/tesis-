import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:uuid/uuid.dart';
import '../data/local_database.dart';
import '../widgets/bottom_nav_bar.dart';

class AnimalRegistrationScreen extends StatefulWidget {
  const AnimalRegistrationScreen({super.key});

  @override
  State<AnimalRegistrationScreen> createState() =>
      _AnimalRegistrationScreenState();
}

class _AnimalRegistrationScreenState extends State<AnimalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificacionController = TextEditingController();
  final _uuid = const Uuid();

  // Catálogos desde SQLite
  List<Map<String, dynamic>> _razas = [];
  Map<String, dynamic>? _selectedRaza;

  // Sexo: 1=Hembra, 2=Macho (igual que la BD PostgreSQL / C# SexoAnimal)
  int _sexo = 1; // Hembra por defecto (producción láctea)

  DateTime? _fechaNacimiento;
  bool _isSaving = false;
  bool _isLoadingCatalogs = true;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _identificacionController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    final razas = await LocalDatabase.instance.getRazas();
    setState(() {
      _razas = razas;
      _isLoadingCatalogs = false;
    });
  }

  Future<void> _pickFechaNacimiento() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'NI'),
      helpText: 'Selecciona fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (date != null) setState(() => _fechaNacimiento = date);
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRaza == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una raza'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Obtener la finca del usuario
      final finca = await LocalDatabase.instance.getFinca();
      if (finca == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se encontró finca configurada'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final animalId = _uuid.v4();
      await LocalDatabase.instance.insertAnimal({
        'id': animalId,
        'finca_id': finca['id'],
        'raza_id': _selectedRaza!['id'],
        'identificacion': _identificacionController.text.trim().toUpperCase(),
        'sexo': _sexo,
        'fecha_nacimiento': _fechaNacimiento!.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'is_deleted': 0,
        'is_synced': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Animal "${_identificacionController.text.trim().toUpperCase()}" guardado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Registrar Animal',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingCatalogs
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Formulario principal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Identificación / Arete
                          _buildLabel('Identificación / Arete *'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _identificacionController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Ej: B-4592',
                              prefixIcon: Icon(Icons.tag),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa la identificación'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Raza
                          _buildLabel('Raza *'),
                          const SizedBox(height: 8),
                          DropdownSearch<Map<String, dynamic>>(
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: const TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Buscar raza...',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            items: _razas,
                            itemAsString: (r) {
                              final proposito = r['proposito'] as int;
                              final label = proposito == 1
                                  ? '🥛 Leche'
                                  : proposito == 2
                                      ? '🥩 Carne'
                                      : '⚖️ Doble';
                              return '${r['nombre']} — $label';
                            },
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: 'Seleccione una raza...',
                                prefixIcon: Icon(Icons.category),
                              ),
                            ),
                            onChanged: (v) => setState(() => _selectedRaza = v),
                            selectedItem: _selectedRaza,
                          ),
                          const SizedBox(height: 16),

                          // Sexo
                          _buildLabel('Sexo *'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _sexo = 1),
                                  child: _buildSexoButton(
                                    icon: Icons.female,
                                    label: 'Hembra',
                                    isSelected: _sexo == 1,
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(8)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _sexo = 2),
                                  child: _buildSexoButton(
                                    icon: Icons.male,
                                    label: 'Macho',
                                    isSelected: _sexo == 2,
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Fecha de Nacimiento
                          _buildLabel('Fecha de Nacimiento *'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickFechaNacimiento,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              child: Text(
                                _fechaNacimiento != null
                                    ? '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}'
                                    : 'Seleccionar fecha...',
                                style: _fechaNacimiento != null
                                    ? Theme.of(context).textTheme.bodyLarge
                                    : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Aviso de guardado local
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync_problem, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Guardado en el dispositivo.',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Se sincronizará con el servidor cuando haya conexión.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: (_isSaving || _isLoadingCatalogs) ? null : _saveAnimal,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Guardando...' : 'Guardar Animal'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }

  Widget _buildSexoButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required BorderRadius borderRadius,
  }) {
    final color = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? color.primaryContainer : color.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.black87),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

// =============================================================================
// GANADO SCREEN — Pantalla "Mi Ganado" con lista, filtros e historial médico
// =============================================================================

class GanadoScreen extends StatefulWidget {
  const GanadoScreen({super.key});

  @override
  State<GanadoScreen> createState() => _GanadoScreenState();
}

class _GanadoScreenState extends State<GanadoScreen> {
  List<Map<String, dynamic>> _animales = [];
  bool _isLoading = true;
  String? _fincaId;
  String _filtroSexo = 'todos';

  @override
  void initState() {
    super.initState();
    _loadAnimales();
  }

  Future<void> _loadAnimales() async {
    setState(() => _isLoading = true);
    final finca = await LocalDatabase.instance.getFinca();
    if (finca != null) {
      _fincaId = finca['id'] as String;
      final todos = await LocalDatabase.instance.getAnimalesConRaza(_fincaId!);
      setState(() {
        _animales = todos;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _animalesFiltrados {
    if (_filtroSexo == 'hembras') {
      return _animales.where((a) => (a['sexo'] as int) == 2).toList();
    }
    if (_filtroSexo == 'machos') {
      return _animales.where((a) => (a['sexo'] as int) == 1).toList();
    }
    return _animales;
  }

  String _calcularEdad(String fechaNacimientoStr) {
    try {
      final fn = DateTime.parse(fechaNacimientoStr);
      final ahora = DateTime.now();
      final meses = (ahora.year - fn.year) * 12 + (ahora.month - fn.month);
      if (meses < 12) return '$meses meses';
      final anios = meses ~/ 12;
      final mesesResto = meses % 12;
      if (mesesResto == 0) return '$anios año${anios > 1 ? 's' : ''}';
      return '$anios a. $mesesResto m.';
    } catch (_) {
      return 'N/A';
    }
  }

  String _propositoLabel(int proposito) {
    switch (proposito) {
      case 1:
        return '🥛 Leche';
      case 2:
        return '🥩 Carne';
      default:
        return '⚖️ Doble';
    }
  }

  Color _propositoColor(int proposito) {
    switch (proposito) {
      case 1:
        return Colors.blue.shade50;
      case 2:
        return Colors.red.shade50;
      default:
        return Colors.orange.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _animalesFiltrados;
    final totalHembras = _animales.where((a) => (a['sexo'] as int) == 2).length;
    final totalMachos = _animales.where((a) => (a['sexo'] as int) == 1).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ganado', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Registrar animal',
            onPressed: () async {
              await context.push('/register_animal');
              _loadAnimales();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Resumen de conteos ─────────────────────────────
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _buildStat('${_animales.length}', 'Total'),
                      const SizedBox(width: 20),
                      _buildStat('$totalHembras', '♀ Hembras', color: Colors.pink),
                      const SizedBox(width: 20),
                      _buildStat('$totalMachos', '♂ Machos', color: Colors.blue),
                    ],
                  ),
                ),
                // ── Filtro sexo ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildFiltroChip('Todos', 'todos'),
                      _buildFiltroChip('♀ Hembras', 'hembras'),
                      _buildFiltroChip('♂ Machos', 'machos'),
                    ],
                  ),
                ),
                // ── Lista de animales ──────────────────────────────
                Expanded(
                  child: filtrados.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadAnimales,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) => _buildAnimalCard(filtrados[i]),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/register_animal');
          _loadAnimales();
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Animal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 2) context.go('/health_record');
        },
      ),
    );
  }

  Widget _buildStat(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color ?? Theme.of(context).colorScheme.primary),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final selected = _filtroSexo == valor;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filtroSexo = valor),
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final esMacho = (animal['sexo'] as int) == 1;
    final proposito = (animal['raza_proposito'] as int?) ?? 3;
    final synced = (animal['is_synced'] as int) == 1;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarHistorial(animal),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar circular con color de propósito
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _propositoColor(proposito),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Center(
                  child: Text(
                    esMacho ? '♂' : '♀',
                    style: TextStyle(
                        fontSize: 24,
                        color: esMacho ? Colors.blue.shade700 : Colors.pink.shade600),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            animal['identificacion'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (!synced)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Sin sync',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${animal['raza_nombre'] ?? '—'}  ·  ${_propositoLabel(proposito)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📅 ${_calcularEdad(animal['fecha_nacimiento'] as String)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarHistorial(Map<String, dynamic> animal) async {
    final animalId = animal['id'] as String;
    final historial =
        await LocalDatabase.instance.getHistorialSaludAnimal(animalId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medical_information,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(animal['identificacion'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '${animal['raza_nombre'] ?? '—'}  ·  ${_calcularEdad(animal['fecha_nacimiento'] as String)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: historial.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.health_and_safety_outlined,
                                size: 56, color: Colors.green),
                            SizedBox(height: 12),
                            Text('Sin registros médicos',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 6),
                            Text(
                              'Este animal no tiene eventos de salud registrados.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: historial.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final h = historial[i];
                        final obligatoria =
                            (h['notificacion_obligatoria'] as int?) == 1;
                        final fecha = h['fecha_deteccion'] as String;
                        final fechaFmt =
                            fecha.length >= 10 ? fecha.substring(0, 10) : fecha;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: obligatoria
                                ? Colors.red.shade50
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: obligatoria
                                  ? Colors.red.shade200
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 10,
                                      color: obligatoria
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      h['enfermedad_nombre'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(fechaFmt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall),
                                ],
                              ),
                              if (h['nombre_comercial'] != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.vaccines,
                                        size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${h['nombre_comercial']}'
                                        '${(h['dosis_aplicada'] as double? ?? 0) > 0 ? '  ·  ${h['dosis_aplicada']} ml' : ''}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (h['observaciones'] != null &&
                                  (h['observaciones'] as String).isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  h['observaciones'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cruelty_free,
              size: 72,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            _filtroSexo == 'hembras'
                ? 'Sin hembras registradas'
                : _filtroSexo == 'machos'
                    ? 'Sin machos registrados'
                    : 'Sin animales registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await context.push('/register_animal');
              _loadAnimales();
            },
            icon: const Icon(Icons.add),
            label: const Text('Registrar primer animal'),
          ),
        ],
      ),
    );
  }
}

