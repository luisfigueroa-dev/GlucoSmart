import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/glucose.dart';

/// Utilidad para exportar datos de glucosa a un archivo PDF.
/// Incluye una gráfica de líneas simple y una tabla con los datos.
/// Maneja permisos de almacenamiento y utiliza null-safety de Dart 3.0.
class PdfExportUtil {
  /// Exporta una lista de mediciones de glucosa a un PDF.
  /// Crea un documento con gráfica y tabla, solicita permisos si es necesario.
  /// Retorna true si la exportación fue exitosa.
  static Future<bool> exportGlucoseData(List<Glucose> glucoseData) async {
    // Solicitar permisos de almacenamiento si no están concedidos
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      return false; // Permiso denegado, no se puede exportar
    }

    // Crear documento PDF
    final pdf = pw.Document();

    // Preparar datos para la gráfica
    final chartData = _prepareChartData(glucoseData);

    // Agregar página al PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Reporte de Glucosa',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              // Gráfica simple de líneas
              pw.Container(
                height: 200,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(
                      List.generate(chartData.length, (index) => 'D${index + 1}'),
                      marginStart: 20,
                      marginEnd: 20,
                    ),
                    yAxis: pw.FixedAxis([0, 50, 100, 150, 200, 250], format: (v) => '${v.toInt()}'),
                  ),
                  datasets: [
                    pw.LineDataSet(
                      data: chartData.map((point) => pw.PointChartValue(point.x, point.y)).toList(),
                      color: PdfColors.blue,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              // Tabla con datos
              pw.Table.fromTextArray(
                headers: ['Fecha', 'Valor (mg/dL)', 'Notas'],
                data: glucoseData.map((glucose) => [
                  glucose.timestamp.toString().split(' ')[0], // Solo fecha
                  glucose.value.toStringAsFixed(1),
                  glucose.notes ?? '',
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    // Generar bytes del PDF
    final Uint8List pdfBytes = await pdf.save();

    // Compartir o guardar el PDF usando printing
    await Printing.sharePdf(bytes: pdfBytes, filename: 'reporte_glucosa.pdf');

    return true;
  }

  /// Prepara datos para la gráfica de líneas.
  /// Convierte las mediciones en puntos (x: índice, y: valor) para simplificar.
  /// Lógica compleja: Ordena por timestamp y limita a los últimos 30 puntos para evitar sobrecarga.
  static List<pw.PointChartValue> _prepareChartData(List<Glucose> data) {
    // Ordenar por timestamp ascendente
    data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Limitar a los últimos 30 puntos para mantener la gráfica legible
    final limitedData = data.length > 30 ? data.sublist(data.length - 30) : data;

    // Crear puntos: x como índice (0 a n-1), y como valor de glucosa
    return List.generate(
      limitedData.length,
      (index) => pw.PointChartValue(index.toDouble(), limitedData[index].value),
    );
  }
}