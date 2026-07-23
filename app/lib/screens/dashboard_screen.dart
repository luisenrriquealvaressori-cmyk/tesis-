import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../data/local_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _currentIndex = 0;
  bool _isLoading = true;
  String _fincaNombre = 'Cargando...';
  int _totalAnimales = 0;
  double _litrosHoy = 0.0;
  List<Map<String, dynamic>> _ultimosRegistros = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final finca = await LocalDatabase.instance.getFinca();
    if (finca != null) {
      final fincaId = finca['id'] as String;
      final totalAnimales = await LocalDatabase.instance.getTotalAnimales(fincaId);
      final litrosHoy = await LocalDatabase.instance.getLitrosHoy(fincaId);
      final ultimosRegistros = await LocalDatabase.instance.getUltimosRegistrosSalud(fincaId);
      
      if (mounted) {
        setState(() {
          _fincaNombre = finca['nombre'] as String;
          _totalAnimales = totalAnimales;
          _litrosHoy = litrosHoy;
          _ultimosRegistros = ultimosRegistros;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _fincaNombre = 'Finca no configurada';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2C694E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4332).withOpacity(0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Panel de Control',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(radius: 4, backgroundColor: Color(0xFF52B788)),
                              SizedBox(width: 6),
                              Text('Offline Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hola, Ganadero',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFB7E4C7), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _fincaNombre,
                          style: const TextStyle(color: Color(0xFFD8F3DC), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Metrics Cards Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF2C694E), Color(0xFF40916C)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.pets, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('VACAS ACTIVAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text('$_totalAnimales', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.extrabold, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.water_drop, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('LECHE HOY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text('$_litrosHoy L', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.extrabold, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Acciones Rápidas', style: Theme.of(context).textTheme.titleLarge),
                  const Icon(Icons.flash_on, color: Color(0xFFD97706), size: 20),
                ],
              ),
              const SizedBox(height: 14),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context, 
                    title: 'Registrar\nAnimal', 
                    icon: Icons.add, 
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () async {
                      await context.push('/register_animal');
                      _loadDashboardData(); // Refresh on return
                    },
                  ),
                  _buildActionCard(
                    context, 
                    title: 'Reportar\nSanidad', 
                    icon: Icons.medical_services, 
                    color: Theme.of(context).colorScheme.errorContainer,
                    iconColor: Theme.of(context).colorScheme.onErrorContainer,
                    onTap: () async {
                      await context.push('/health_record');
                      _loadDashboardData();
                    },
                  ),
                  _buildActionCard(
                    context, 
                    title: 'Ordeño\nDiario', 
                    icon: Icons.ev_station, 
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    iconColor: Theme.of(context).colorScheme.onTertiaryContainer,
                    onTap: () async {
                      await context.push('/milking');
                      _loadDashboardData();
                    },
                  ),
                  _buildActionCard(
                    context, 
                    title: 'Mi\nGanado', 
                    icon: Icons.list_alt, 
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    iconColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    onTap: () => context.go('/ganado'),
                  ),
                ],
              ),
              
              if (_ultimosRegistros.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text('Últimos Eventos de Salud', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ultimosRegistros.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final reg = _ultimosRegistros[index];
                    final obligatoria = (reg['notificacion_obligatoria'] as int) == 1;
                    return Card(
                      color: obligatoria ? Colors.red.shade50 : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: obligatoria ? Colors.red.shade200 : Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: obligatoria ? Colors.red : Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
                        ),
                        title: Text('${reg['animal_id']} - ${reg['enfermedad_nombre']}'),
                        subtitle: Text(reg['fecha_deteccion'] as String),
                        trailing: obligatoria ? const Icon(Icons.warning, color: Colors.red) : null,
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) context.go('/ganado');
          if (index == 2) context.go('/health_record');
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, Color? iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
