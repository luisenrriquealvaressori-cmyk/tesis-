import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import '../data/local_database.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';

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
  
  // Métricas KPI Ganaderas
  double _litrosHoy = 0.0;
  double _kgLecheHoy = 0.0;
  int _vacasOrdenadasHoy = 0;
  double _promedioVacaDia = 0.0;
  double _totalUGM = 0.0;
  int _vacasEnRetiroCount = 0;

  List<Map<String, dynamic>> _ultimosRegistros = [];
  List<Map<String, dynamic>> _produccion7Dias = [];

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
      final kpis = await LocalDatabase.instance.getKPIsProduccion(fincaId);
      final ultimosRegistros = await LocalDatabase.instance.getUltimosRegistrosSalud(fincaId);
      final produccion7Dias = await LocalDatabase.instance.getProduccionUltimos7Dias(fincaId);
      
      if (mounted) {
        setState(() {
          _fincaNombre = finca['nombre'] as String;
          _totalAnimales = totalAnimales;
          _litrosHoy = (kpis['litrosHoy'] as num).toDouble();
          _kgLecheHoy = (kpis['kgLecheHoy'] as num).toDouble();
          _vacasOrdenadasHoy = kpis['vacasOrdenadasHoy'] as int;
          _promedioVacaDia = (kpis['promedioVacaDia'] as num).toDouble();
          _totalUGM = (kpis['totalUGM'] as num).toDouble();
          _vacasEnRetiroCount = kpis['vacasEnRetiroCount'] as int;
          _ultimosRegistros = ultimosRegistros;
          _produccion7Dias = produccion7Dias;
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

  Widget _buildShimmerDashboard() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _isLoading 
        ? _buildShimmerDashboard()
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
                      color: const Color(0xFF1B4332).withValues(alpha: 0.25),
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
                          'Panel de Control KPI',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
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
              const SizedBox(height: 20),

              if (_vacasEnRetiroCount > 0) ...[
                _PulsingAlert(count: _vacasEnRetiroCount),
                const SizedBox(height: 20),
              ],

              
              // Metrics Cards Grid (4 tarjetas KPI)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'HATO / UGM',
                      value: '$_totalAnimales cab',
                      subtext: '$_totalUGM UGM',
                      icon: Icons.pets,
                      colors: [const Color(0xFF2C694E), const Color(0xFF40916C)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'LECHE HOY',
                      value: '$_litrosHoy L',
                      subtext: '$_kgLecheHoy kg',
                      icon: Icons.water_drop,
                      colors: [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'PROMEDIO / VACA',
                      value: '$_promedioVacaDia L/día',
                      subtext: '$_vacasOrdenadasHoy vacas en ordeño',
                      icon: Icons.speed,
                      colors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'RETIRO LECHE',
                      value: '$_vacasEnRetiroCount vacas',
                      subtext: _vacasEnRetiroCount > 0 ? 'Leche de descarte' : 'Hato 100% sano',
                      icon: Icons.sanitizer,
                      colors: _vacasEnRetiroCount > 0 
                          ? [Colors.red.shade700, Colors.red.shade400]
                          : [Colors.teal.shade700, Colors.teal.shade400],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Gráfico de Producción
              _buildChartSection(),
              
              const SizedBox(height: 24),
              
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
                    icon: Icons.add_circle_outline, 
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () async {
                      await context.push('/register_animal');
                      _loadDashboardData();
                    },
                  ),
                  _buildActionCard(
                    context, 
                    title: 'Reportar\nSanidad', 
                    icon: Icons.health_and_safety, 
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
                    icon: Icons.opacity, 
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    iconColor: Theme.of(context).colorScheme.onTertiaryContainer,
                    onTap: () async {
                      await context.push('/milking');
                      _loadDashboardData();
                    },
                  ),
                  _buildActionCard(
                    context, 
                    title: 'Sincronizar\nDatos', 
                    icon: Icons.cloud_sync, 
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    onTap: () async {
                      await context.push('/sync');
                      _loadDashboardData();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const SizedBox(height: 28),

              // Registros de salud de la finca
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Eventos de Salud del Hato (${_ultimosRegistros.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                    tooltip: 'Nuevo Registro de Salud',
                    onPressed: () async {
                      await context.push('/health_record');
                      _loadDashboardData();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_ultimosRegistros.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text('No hay eventos de salud registrados en la finca.', style: TextStyle(color: Colors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ultimosRegistros.length,
                  itemBuilder: (context, index) {
                    final reg = _ultimosRegistros[index];
                    final esObligatorio = (reg['notificacion_obligatoria'] as int?) == 1;
                    final fechaStr = reg['fecha_deteccion'] != null && reg['fecha_deteccion'].toString().length >= 10
                        ? reg['fecha_deteccion'].toString().substring(0, 10)
                        : '—';
                    final observaciones = (reg['observaciones'] as String?)?.trim();

                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: esObligatorio ? Colors.red.shade700 : Colors.teal.shade600,
                          child: Icon(
                            esObligatorio ? Icons.warning_amber_rounded : Icons.medical_services,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Arete ${reg['animal_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reg['enfermedad_nombre'] as String? ?? 'Diagnóstico Desconocido',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: esObligatorio ? Colors.red.shade800 : Colors.black87,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📅 Detección: $fechaStr',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              if (observaciones != null && observaciones.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    '📝 $observaciones',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 1) {
            await context.push('/ganado');
            _loadDashboardData();
          }
          if (index == 2) {
            await context.push('/health_record');
            _loadDashboardData();
          }
        },
      ),
    );
  }

  Widget _buildChartSection() {
    if (_produccion7Dias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: const Column(
          children: [
            Icon(Icons.show_chart, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text('No hay datos de producción recientes para la gráfica.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final spots = _produccion7Dias.asMap().entries.map((e) {
      final idx = e.key.toDouble();
      final litros = (e.value['total_litros'] as num).toDouble();
      return FlSpot(idx, litros);
    }).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Producción Últimos 7 Días (Litros)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _produccion7Dias.length) {
                          final fecha = _produccion7Dias[idx]['fecha_corta'] as String;
                          final day = fecha.substring(8, 10);
                          final month = fecha.substring(5, 7);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('$day/$month', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}L', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                Text(subtext, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 26,
              child: Icon(icon, color: iconColor ?? Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alerta sanitaria animada con efecto de pulso.
/// Se muestra en el dashboard cuando hay vacas en período de retiro de leche.
class _PulsingAlert extends StatefulWidget {
  final int count;
  const _PulsingAlert({required this.count});

  @override
  State<_PulsingAlert> createState() => _PulsingAlertState();
}

class _PulsingAlertState extends State<_PulsingAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: _glow.value * 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFFB45309)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  // Ícono con borde pulsante
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: _glow.value),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.count} vaca${widget.count > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RETIRO SANITARIO',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Leche bajo tratamiento médico — no apta para consumo ni venta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

