import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/glucose_provider.dart';
import '../providers/auth_provider.dart';
import '../models/glucose.dart';
import 'add_glucose_screen.dart';

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
    // Cargar mediciones al inicializar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
      if (authProvider.user != null) {
        glucoseProvider.loadLast7Days(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GlucoSmart - Inicio'),
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
      body: Consumer<GlucoseProvider>(
        builder: (context, glucoseProvider, child) {
          if (glucoseProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando mediciones de glucosa',
              ),
            );
          }

          if (glucoseProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    glucoseProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.user != null) {
                        glucoseProvider.loadLast7Days(authProvider.user!.id);
                      }
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final measurements = glucoseProvider.measurements;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gráfica de glucosa
                Semantics(
                  label: 'Gráfica de niveles de glucosa de los últimos 7 días',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tendencia de Glucosa',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: _buildGlucoseChart(measurements),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Lista de mediciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mediciones Recientes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddMeasurementDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (measurements.isEmpty)
                  const Center(
                    child: Text('No hay mediciones en los últimos 7 días'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: measurements.length,
                    itemBuilder: (context, index) {
                      final measurement = measurements[index];
                      return Card(
                        child: ListTile(
                          title: Text('${measurement.value} mg/dL'),
                          subtitle: Text(
                            '${measurement.timestamp.toLocal().toString().split(' ')[0]} ${measurement.timestamp.toLocal().toString().split(' ')[1].substring(0, 5)}',
                          ),
                          trailing: _getStatusIcon(measurement),
                          onTap: () {
                            // Placeholder para editar medición
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
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

  /// Navega a la pantalla para agregar una nueva medición.
  void _showAddMeasurementDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddGlucoseScreen(),
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