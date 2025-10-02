import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/ml_util.dart';
import '../providers/glucose_provider.dart';
import '../models/glucose.dart';

/// Widget para mostrar predicción on-device de hipoglucemia.
/// Utiliza MLUtil para predicciones basadas en datos históricos de glucosa.
/// Incluye indicador visual de riesgo, gráfica de tendencia y alertas.
/// Compatible con Dart 3.0, null-safety y accesibilidad WCAG 2.2 AA.
class HypoglycemiaPredictionWidget extends StatefulWidget {
  /// Constructor del widget.
  const HypoglycemiaPredictionWidget({super.key});

  @override
  State<HypoglycemiaPredictionWidget> createState() => _HypoglycemiaPredictionWidgetState();
}

class _HypoglycemiaPredictionWidgetState extends State<HypoglycemiaPredictionWidget> {
  /// Instancia de MLUtil para predicciones.
  final MLUtil _mlUtil = MLUtil();

  /// Probabilidad de hipoglucemia predicha (0.0 a 1.0).
  double? _hypoglycemiaProbability;

  /// Estado de carga de la predicción.
  bool _isPredicting = false;

  /// Mensaje de error en caso de fallo en la predicción.
  String? _predictionError;

  @override
  void initState() {
    super.initState();
    _loadModelAndPredict();
  }

  /// Carga el modelo ML y realiza la predicción de hipoglucemia.
  /// Lógica compleja: Se extraen los valores históricos de glucosa del provider,
  /// se normalizan implícitamente en MLUtil, y se pasa como tensor al modelo.
  /// El modelo procesa secuencias temporales para identificar patrones predictivos.
  /// Se maneja errores para robustez en producción.
  Future<void> _loadModelAndPredict() async {
    setState(() {
      _isPredicting = true;
      _predictionError = null;
    });

    try {
      // Cargar modelo ARDA preferentemente, fallback a OhioT1DM.
      await _mlUtil.loadArdaModel();

      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
      final measurements = glucoseProvider.measurements;

      if (measurements.isNotEmpty) {
        // Extraer valores históricos ordenados por timestamp ascendente.
        final sortedMeasurements = List<Glucose>.from(measurements)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final historicalData = sortedMeasurements.map((g) => g.value).toList();

        // Realizar predicción: probabilidad de glucosa <70 mg/dL en 30 min.
        _hypoglycemiaProbability = await _mlUtil.predictHypoglycemia(historicalData);
      }
    } catch (e) {
      _predictionError = 'Error en predicción: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glucoseProvider = Provider.of<GlucoseProvider>(context);
    final measurements = glucoseProvider.measurements;

    // Indicador visual de riesgo: cambia basado en probabilidad.
    Widget riskIndicator;
    String riskLabel;
    if (_isPredicting) {
      riskIndicator = const CircularProgressIndicator();
      riskLabel = 'Calculando riesgo de hipoglucemia';
    } else if (_predictionError != null) {
      riskIndicator = Icon(Icons.error, color: Colors.red, size: 48);
      riskLabel = 'Error en predicción: $_predictionError';
    } else if (_hypoglycemiaProbability != null && _hypoglycemiaProbability! > 0.5) {
      riskIndicator = Icon(Icons.warning, color: Colors.red, size: 48);
      riskLabel = 'Riesgo alto de hipoglucemia (<70 mg/dL en 30 min)';
    } else {
      riskIndicator = Icon(Icons.check_circle, color: Colors.green, size: 48);
      riskLabel = 'Riesgo bajo de hipoglucemia';
    }

    // Mensaje de alerta si hay riesgo.
    String alertMessage = '';
    if (_hypoglycemiaProbability != null && _hypoglycemiaProbability! > 0.5) {
      alertMessage = '¡Alerta! Probabilidad alta de hipoglucemia en los próximos 30 minutos. Monitorea tu glucosa.';
    }

    // Gráfica de tendencia: muestra mediciones históricas con línea de referencia en 70 mg/dL.
    Widget trendChart;
    if (measurements.isEmpty) {
      trendChart = Semantics(
        label: 'No hay datos de glucosa para mostrar tendencia',
        child: const Center(
          child: Text('No hay datos disponibles', style: TextStyle(color: Colors.grey)),
        ),
      );
    } else {
      // Procesar datos similares a GlucoseChartWidget.
      final sortedMeasurements = List<Glucose>.from(measurements)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final firstTimestamp = sortedMeasurements.first.timestamp;
      final spots = sortedMeasurements.map((glucose) {
        final hoursSinceFirst = glucose.timestamp.difference(firstTimestamp).inHours.toDouble();
        return FlSpot(hoursSinceFirst, glucose.value);
      }).toList();

      final values = spots.map((s) => s.y);
      final minValue = values.reduce((a, b) => a < b ? a : b);
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      final minY = (minValue - 10).clamp(0.0, double.infinity);
      final maxY = maxValue + 10;

      trendChart = Semantics(
        label: 'Gráfica de tendencia de glucosa con línea de referencia para hipoglucemia',
        hint: 'Línea horizontal en 70 mg/dL indica umbral de hipoglucemia',
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 20,
                verticalInterval: 6, // Cada 6 horas
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 12, // Cada 12 horas
                    getTitlesWidget: (value, meta) {
                      final date = firstTimestamp.add(Duration(hours: value.toInt()));
                      return Text(
                        '${date.day}/${date.month} ${date.hour}:00',
                        style: const TextStyle(fontSize: 10, color: Colors.black),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              // Línea de referencia para hipoglucemia.
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 70,
                    color: Colors.red,
                    strokeWidth: 2,
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      labelResolver: (line) => 'Hipoglucemia (<70)',
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  dotData: FlDotData(show: false), // Ocultar puntos para simplicidad.
                ),
              ],
              minX: 0,
              maxX: spots.isNotEmpty ? spots.last.x : 0,
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final glucose = sortedMeasurements[spot.spotIndex];
                      return LineTooltipItem(
                        '${glucose.timestamp.hour}:${glucose.timestamp.minute.toString().padLeft(2, '0')}: ${glucose.value.toStringAsFixed(1)} mg/dL',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título accesible.
            Semantics(
              header: true,
              child: Text(
                'Predicción de Hipoglucemia',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            // Indicador de riesgo.
            Center(
              child: Semantics(
                label: riskLabel,
                child: riskIndicator,
              ),
            ),
            const SizedBox(height: 8),
            // Probabilidad si disponible.
            if (_hypoglycemiaProbability != null)
              Center(
                child: Semantics(
                  label: 'Probabilidad de hipoglucemia: ${_hypoglycemiaProbability!.toStringAsFixed(2)}',
                  child: Text(
                    'Probabilidad: ${(_hypoglycemiaProbability! * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Alerta.
            if (alertMessage.isNotEmpty)
              Semantics(
                liveRegion: true, // Anuncia cambios dinámicos.
                label: alertMessage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alertMessage,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Gráfica de tendencia.
            trendChart,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mlUtil.dispose();
    super.dispose();
  }
}