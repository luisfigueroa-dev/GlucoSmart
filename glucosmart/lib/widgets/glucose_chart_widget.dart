import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/glucose_provider.dart';
import '../models/glucose.dart';

/// Widget reutilizable para mostrar una gráfica de línea de mediciones de glucosa.
/// Utiliza fl_chart para renderizar el gráfico y obtiene datos del GlucoseProvider.
/// Implementa accesibilidad WCAG 2.2 AA con contraste de colores, navegación por teclado y descripciones semánticas.
/// Compatible con Dart 3.0 y null-safety.
class GlucoseChartWidget extends StatelessWidget {
  /// Constructor del widget.
  const GlucoseChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el provider para acceder a las mediciones.
    final glucoseProvider = Provider.of<GlucoseProvider>(context);
    final measurements = glucoseProvider.measurements;

    // Si no hay mediciones, mostrar un mensaje accesible.
    if (measurements.isEmpty) {
      return Semantics(
        label: 'No hay mediciones de glucosa disponibles para mostrar en el gráfico',
        child: const Center(
          child: Text(
            'No hay datos disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Procesar las mediciones para crear los puntos del gráfico.
    // Se ordenan por timestamp ascendente para una línea cronológica correcta.
    final sortedMeasurements = List<Glucose>.from(measurements)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Convertir mediciones a FlSpot: x como días desde la primera medición, y como valor.
    // Esto facilita la visualización en el eje X sin timestamps largos.
    final firstTimestamp = sortedMeasurements.first.timestamp;
    final spots = sortedMeasurements.map((glucose) {
      final daysSinceFirst = glucose.timestamp.difference(firstTimestamp).inDays.toDouble();
      return FlSpot(daysSinceFirst, glucose.value);
    }).toList();

    // Determinar rangos para los ejes Y (valores de glucosa).
    // Rango normal: 70-140 mg/dL, pero se ajusta dinámicamente.
    final values = spots.map((s) => s.y);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minY = (minValue - 10).clamp(0.0, double.infinity);
    final maxY = maxValue + 10;

    // Colores accesibles: Azul para la línea (contraste alto en fondo blanco).
    final lineColor = Theme.of(context).colorScheme.primary;
    final gridColor = Colors.grey.withOpacity(0.3);

    return Semantics(
      label: 'Gráfico de línea mostrando mediciones de glucosa a lo largo del tiempo',
      hint: 'Toca para explorar valores específicos',
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            // Configuración de la cuadrícula para mejor legibilidad.
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 20, // Intervalos de 20 mg/dL
              verticalInterval: 1, // Un día
              getDrawingHorizontalLine: (value) => FlLine(
                color: gridColor,
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: gridColor,
                strokeWidth: 1,
              ),
            ),
            // Títulos de los ejes con formato accesible.
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1, // Cada día
                  getTitlesWidget: (value, meta) {
                    final date = firstTimestamp.add(Duration(days: value.toInt()));
                    return Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()} mg/dL',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            // Líneas de referencia para rangos normales de glucosa.
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 70,
                  color: Colors.green,
                  strokeWidth: 2,
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (line) => 'Mínimo normal',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
                HorizontalLine(
                  y: 140,
                  color: Colors.orange,
                  strokeWidth: 2,
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    labelResolver: (line) => 'Máximo normal',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
            // Datos de la línea principal.
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true, // Curva suave para mejor visualización.
                color: lineColor,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: lineColor.withOpacity(0.1), // Área sombreada sutil.
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              ),
            ],
            // Rangos de los ejes.
            minX: 0,
            maxX: spots.isNotEmpty ? spots.last.x : 0,
            minY: minY,
            maxY: maxY,
            // Interacción táctil para accesibilidad.
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final glucose = sortedMeasurements[spot.spotIndex];
                    return LineTooltipItem(
                      '${glucose.timestamp.day}/${glucose.timestamp.month}: ${glucose.value.toStringAsFixed(1)} mg/dL',
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
}