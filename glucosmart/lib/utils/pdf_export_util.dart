import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/glucose.dart';
import '../models/carbs.dart';
import '../models/medication.dart';
import '../models/activity.dart';
import '../models/health_parameter.dart';

/// Utilidad para generar informes PDF con datos de salud del usuario.
/// Incluye gráficos, estadísticas y resumen de mediciones.
/// Compatible con impresión y exportación.
class PDFExportUtil {
  /// Genera un informe PDF completo con datos de salud.
  /// Incluye gráficos de glucosa, estadísticas y resumen del período.
  static Future<Uint8List> generateHealthReport({
    required String userName,
    required List<Glucose> glucoseData,
    required List<Carbs> carbsData,
    required List<Medication> medicationData,
    required List<Activity> activityData,
    required List<HealthParameter> healthData,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // Calcular estadísticas
    final glucoseStats = _calculateGlucoseStats(glucoseData);
    final carbsStats = _calculateCarbsStats(carbsData);
    final activityStats = _calculateActivityStats(activityData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Encabezado
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Informe de Salud GlucoSmart',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Usuario: $userName',
                    style: const pw.TextStyle(fontSize: 16)),
                pw.Text('Período: ${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.Divider(),
              ],
            ),
          ),

          // Resumen Ejecutivo
          pw.Header(level: 1, child: pw.Text('Resumen Ejecutivo')),
          pw.Paragraph(
            text: 'Este informe contiene un análisis detallado de sus mediciones de glucosa, '
                  'ingesta de carbohidratos, actividad física y otros parámetros de salud '
                  'durante el período seleccionado.',
          ),
          pw.SizedBox(height: 16),

          // Estadísticas de Glucosa
          pw.Header(level: 1, child: pw.Text('Glucosa en Sangre')),
          pw.Text('Total de mediciones: ${glucoseData.length}'),
          pw.Text('Promedio: ${glucoseStats['average']?.toStringAsFixed(1)} mg/dL'),
          pw.Text('Valor mínimo: ${glucoseStats['min']} mg/dL'),
          pw.Text('Valor máximo: ${glucoseStats['max']} mg/dL'),
          pw.Text('Tiempo en rango (70-140 mg/dL): ${glucoseStats['timeInRange']?.toStringAsFixed(1)}%'),
          pw.SizedBox(height: 16),

          // Gráfico de Glucosa (placeholder - en implementación real necesitaríamos renderizar)
          pw.Container(
            height: 200,
            child: pw.Center(
              child: pw.Text('Gráfico de Tendencia de Glucosa'),
            ),
          ),
          pw.SizedBox(height: 16),

          // Carbohidratos
          pw.Header(level: 1, child: pw.Text('Ingesta de Carbohidratos')),
          pw.Text('Total de registros: ${carbsData.length}'),
          pw.Text('Promedio diario: ${carbsStats['dailyAverage']?.toStringAsFixed(1)} g'),
          pw.Text('Total acumulado: ${carbsStats['total']} g'),
          pw.SizedBox(height: 16),

          // Actividad Física
          pw.Header(level: 1, child: pw.Text('Actividad Física')),
          pw.Text('Total de sesiones: ${activityData.length}'),
          pw.Text('Pasos promedio diario: ${activityStats['avgSteps']?.toStringAsFixed(0)}'),
          pw.Text('Calorías promedio diario: ${activityStats['avgCalories']?.toStringAsFixed(1)}'),
          pw.SizedBox(height: 16),

          // Medicamentos
          pw.Header(level: 1, child: pw.Text('Medicamentos')),
          pw.Text('Total de dosis registradas: ${medicationData.length}'),
          ..._buildMedicationSummary(medicationData),
          pw.SizedBox(height: 16),

          // Parámetros de Salud
          pw.Header(level: 1, child: pw.Text('Parámetros de Salud')),
          ..._buildHealthParametersSummary(healthData),

          // Pie de página
          pw.Spacer(),
          pw.Divider(),
          pw.Text('Generado por GlucoSmart - ${DateTime.now().toString().split('.')[0]}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );

    return pdf.save();
  }

  /// Calcula estadísticas de glucosa.
  static Map<String, dynamic> _calculateGlucoseStats(List<Glucose> data) {
    if (data.isEmpty) return {};

    final values = data.map((g) => g.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    final inRange = data.where((g) => g.value >= 70 && g.value <= 140).length;
    final timeInRange = (inRange / data.length) * 100;

    return {
      'average': average,
      'min': min,
      'max': max,
      'timeInRange': timeInRange,
    };
  }

  /// Calcula estadísticas de carbohidratos.
  static Map<String, dynamic> _calculateCarbsStats(List<Carbs> data) {
    if (data.isEmpty) return {};

    final total = data.map((c) => c.grams).reduce((a, b) => a + b);
    final dailyAverage = total / 7; // Asumiendo semana

    return {
      'total': total,
      'dailyAverage': dailyAverage,
    };
  }

  /// Calcula estadísticas de actividad.
  static Map<String, dynamic> _calculateActivityStats(List<Activity> data) {
    if (data.isEmpty) return {};

    final totalSteps = data.map((a) => a.steps).reduce((a, b) => a + b);
    final totalCalories = data.map((a) => a.caloriesBurned).reduce((a, b) => a + b);
    final avgSteps = totalSteps / data.length;
    final avgCalories = totalCalories / data.length;

    return {
      'avgSteps': avgSteps,
      'avgCalories': avgCalories,
    };
  }

  /// Construye resumen de medicamentos para PDF.
  static List<pw.Widget> _buildMedicationSummary(List<Medication> data) {
    final summary = <String, int>{};

    for (final med in data) {
      summary[med.name] = (summary[med.name] ?? 0) + 1;
    }

    return summary.entries.map((entry) =>
      pw.Text('${entry.key}: ${entry.value} dosis')
    ).toList();
  }

  /// Construye resumen de parámetros de salud para PDF.
  static List<pw.Widget> _buildHealthParametersSummary(List<HealthParameter> data) {
    return data.map((param) =>
      pw.Text('${param.type.name}: ${param.value} ${param.unit ?? ''}')
    ).toList();
  }

  /// Comparte el PDF generado.
  static Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(bytes: pdfData, filename: fileName);
  }

  /// Imprime el PDF generado.
  static Future<void> printPDF(Uint8List pdfData) async {
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfData);
  }
}