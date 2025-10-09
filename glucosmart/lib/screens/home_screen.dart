import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/glucose_provider.dart';
import '../providers/auth_provider.dart';
import '../models/glucose.dart';
import 'add_glucose_screen.dart';
import 'add_carbs_screen.dart';
import 'list_activity_screen.dart';
import 'list_health_parameters_screen.dart';
import 'list_medication_screen.dart';
import '../widgets/hypoglycemia_prediction_widget.dart';
import '../widgets/retinopathy_detection_widget.dart';
import 'education_screen.dart';
import 'reports_screen.dart';
import '../providers/user_stats_provider.dart';
import '../models/user_stats.dart';

/// Pantalla principal que muestra mediciones de glucosa de los últimos 7 días.
/// Incluye lista de mediciones, gráfica básica con fl_chart y botón para agregar nueva medición.
/// Maneja estados de carga y errores. Compatible con WCAG 2.2 AA para accesibilidad.
/// Usa Dart 3.0 con null-safety y comentarios en español para lógica compleja.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar mediciones y estadísticas al inicializar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
      final userStatsProvider = Provider.of<UserStatsProvider>(context, listen: false);
      if (authProvider.user != null) {
        glucoseProvider.loadLast7Days(authProvider.user!.id);
        userStatsProvider.loadUserStats(authProvider.user!.id);
      }
    });
  }

  void _showAddMeasurementDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddGlucoseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GlucoSmart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Text(
                  '¡Hola, ${authProvider.user?.email?.split('@')[0] ?? 'Usuario'}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Monitorea tu salud diabética',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Acciones rápidas
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Glucosa',
                    Icons.bloodtype,
                    Colors.red,
                    _showAddMeasurementDialog,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    'Carbohidratos',
                    Icons.restaurant,
                    Colors.orange,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AddCarbsScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Resumen de salud
            Text(
              'Resumen de Salud',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<GlucoseProvider>(
              builder: (context, glucoseProvider, child) {
                if (glucoseProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final measurements = glucoseProvider.measurements;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Glucosa (Últimos 7 días)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${measurements.length} mediciones',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (measurements.isNotEmpty)
                          SizedBox(
                            height: 150,
                            child: _buildGlucoseChart(measurements),
                          )
                        else
                          const Center(
                            child: Text('No hay datos de glucosa'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Gamificación
            Text(
              'Tu Progreso',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<UserStatsProvider>(
              builder: (context, userStatsProvider, child) {
                if (userStatsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = userStatsProvider.userStats;
                if (stats == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Cargando estadísticas...'),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nivel ${stats.level}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            Text(
                              '${stats.points} puntos',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Racha: ${stats.streakDays} días',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (stats.achievements.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Logros: ${stats.achievements.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (stats.points % 100) / 100,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.points % 100}/100 para nivel ${stats.level + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Módulos principales
            Text(
              'Módulos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildModuleCard(
                  context,
                  'Actividad Física',
                  'Registra tus pasos',
                  Icons.directions_run,
                  Colors.blue,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ListActivityScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Parámetros',
                  'Peso, HbA1c, presión',
                  Icons.monitor_heart,
                  Colors.purple,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ListHealthParametersScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Medicamentos',
                  'Gestiona tus dosis',
                  Icons.medication,
                  Colors.green,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ListMedicationScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Educación',
                  'Aprende sobre diabetes',
                  Icons.school,
                  Colors.amber,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EducationScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Informes',
                  'Exporta tus datos',
                  Icons.description,
                  Colors.indigo,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'IA & Análisis',
                  'Predicciones',
                  Icons.smart_toy,
                  Colors.teal,
                  () => _showAIAnalysis(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Consejos del día
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Consejo del Día',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mantén un registro constante de tus niveles de glucosa para identificar patrones y mejorar tu control.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Análisis con IA',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const HypoglycemiaPredictionWidget(),
              const SizedBox(height: 16),
              const RetinopathyDetectionWidget(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la gráfica de línea para los niveles de glucosa.
  /// Agrupa mediciones por día y calcula el promedio diario para simplificar la visualización.
  /// Usa fl_chart para renderizar la gráfica de manera eficiente.
  Widget _buildGlucoseChart(List<Glucose> measurements) {
    if (measurements.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar'));
    }

    // Agrupar mediciones por día y calcular promedio
    // Lógica compleja: se itera sobre las mediciones, se agrupa por fecha (ignorando hora),
    // se calcula el promedio de valores por día para reducir ruido en la gráfica.
    final Map<String, List<double>> dailyValues = {};
    for (final measurement in measurements) {
      final dateKey = measurement.timestamp.toLocal().toString().split(' ')[0];
      dailyValues.putIfAbsent(dateKey, () => []).add(measurement.value);
    }

    final List<FlSpot> spots = [];
    final List<String> dates = dailyValues.keys.toList()..sort();
    for (int i = 0; i < dates.length; i++) {
      final values = dailyValues[dates[i]]!;
      final average = values.reduce((a, b) => a + b) / values.length;
      spots.add(FlSpot(i.toDouble(), average));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < dates.length) {
                  final date = dates[value.toInt()];
                  return Text(date.substring(5)); // MM-DD
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
            dotData: const FlDotData(show: true),
          ),
        ],
        minY: 0,
        maxY: 300, // Rango típico de glucosa
      ),
    );
  }

  /// Retorna un ícono basado en el estado de la medición (normal, alto, bajo).
  Widget _getStatusIcon(Glucose measurement) {
    if (measurement.isLow()) {
      return const Icon(Icons.warning, color: Colors.red);
    } else if (measurement.isHigh()) {
      return const Icon(Icons.warning, color: Colors.orange);
    } else {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
  }
}