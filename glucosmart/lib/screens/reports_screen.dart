import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glucose_provider.dart';
import '../providers/carbs_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/health_parameter_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/pdf_export_util.dart';

/// Pantalla para generar y exportar informes de salud.
/// Permite seleccionar período y tipo de informe.
/// Compatible con WCAG 2.2 AA para accesibilidad.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes de Salud'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y descripción
            Semantics(
              header: true,
              child: Text(
                'Generar Informe de Salud',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cree un informe completo con sus datos de salud para compartir con profesionales médicos.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Selector de fechas
            Text(
              'Seleccionar Período',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateSelector(
                    'Fecha Inicio',
                    _startDate,
                    (date) => setState(() => _startDate = date),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateSelector(
                    'Fecha Fin',
                    _endDate,
                    (date) => setState(() => _endDate = date),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vista previa de datos
            Text(
              'Vista Previa de Datos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDataPreview(),
            const SizedBox(height: 24),

            // Botones de acción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAndShareReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'Generando...' : 'Generar y Compartir PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateAndPrintReport,
                icon: const Icon(Icons.print),
                label: const Text('Generar e Imprimir'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, Function(DateTime) onDateSelected) {
    return Semantics(
      label: 'Seleccionar $label',
      hint: 'Toque para abrir el selector de fecha',
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            helpText: 'Seleccionar $label',
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            '${date.day}/${date.month}/${date.year}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    return Consumer5<GlucoseProvider, CarbsProvider, MedicationProvider, ActivityProvider, HealthParameterProvider>(
      builder: (context, glucose, carbs, medication, activity, health, child) {
        final glucoseCount = glucose.measurements.length;
        final carbsCount = carbs.entries.length;
        final medicationCount = medication.entries.length;
        final activityCount = activity.activities.length;
        final healthCount = health.parameters.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildPreviewItem('Glucosa', glucoseCount, 'mediciones'),
                _buildPreviewItem('Carbohidratos', carbsCount, 'registros'),
                _buildPreviewItem('Medicamentos', medicationCount, 'dosis'),
                _buildPreviewItem('Actividad', activityCount, 'sesiones'),
                _buildPreviewItem('Parámetros', healthCount, 'registros'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewItem(String label, int count, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('$count $unit', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _generateAndShareReport() async {
    setState(() => _isGenerating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
      final carbsProvider = Provider.of<CarbsProvider>(context, listen: false);
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      final healthProvider = Provider.of<HealthParameterProvider>(context, listen: false);

      // Cargar datos (últimos 7-30 días por simplicidad - en producción cargar más datos)
      await glucoseProvider.loadLast7Days(authProvider.user!.id);
      await carbsProvider.loadLast7Days(authProvider.user!.id);
      await medicationProvider.loadLast7Days(authProvider.user!.id);
      await activityProvider.loadLast7DaysActivities(authProvider.user!.id);
      await healthProvider.loadLast30DaysParameters(authProvider.user!.id);

      // Filtrar datos por el período seleccionado
      final filteredGlucose = glucoseProvider.measurements.where((g) =>
        g.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        g.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredCarbs = carbsProvider.entries.where((c) =>
        c.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        c.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredMedication = medicationProvider.entries.where((m) =>
        m.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        m.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredActivity = activityProvider.activities.where((a) =>
        a.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        a.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredHealth = healthProvider.parameters.where((h) =>
        h.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        h.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();

      final pdfData = await PDFExportUtil.generateHealthReport(
        userName: authProvider.user?.email?.split('@')[0] ?? 'Usuario',
        glucoseData: filteredGlucose,
        carbsData: filteredCarbs,
        medicationData: filteredMedication,
        activityData: filteredActivity,
        healthData: filteredHealth,
        startDate: _startDate,
        endDate: _endDate,
      );

      final fileName = 'informe_salud_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await PDFExportUtil.sharePDF(pdfData, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe generado y listo para compartir')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _generateAndPrintReport() async {
    setState(() => _isGenerating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
      final carbsProvider = Provider.of<CarbsProvider>(context, listen: false);
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      final healthProvider = Provider.of<HealthParameterProvider>(context, listen: false);

      // Cargar datos (últimos 7-30 días por simplicidad - en producción cargar más datos)
      await glucoseProvider.loadLast7Days(authProvider.user!.id);
      await carbsProvider.loadLast7Days(authProvider.user!.id);
      await medicationProvider.loadLast7Days(authProvider.user!.id);
      await activityProvider.loadLast7DaysActivities(authProvider.user!.id);
      await healthProvider.loadLast30DaysParameters(authProvider.user!.id);

      // Filtrar datos por el período seleccionado
      final filteredGlucose = glucoseProvider.measurements.where((g) =>
        g.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        g.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredCarbs = carbsProvider.entries.where((c) =>
        c.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        c.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredMedication = medicationProvider.entries.where((m) =>
        m.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        m.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredActivity = activityProvider.activities.where((a) =>
        a.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        a.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();
      final filteredHealth = healthProvider.parameters.where((h) =>
        h.timestamp.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        h.timestamp.isBefore(_endDate.add(const Duration(days: 1)))).toList();

      final pdfData = await PDFExportUtil.generateHealthReport(
        userName: authProvider.user?.email?.split('@')[0] ?? 'Usuario',
        glucoseData: filteredGlucose,
        carbsData: filteredCarbs,
        medicationData: filteredMedication,
        activityData: filteredActivity,
        healthData: filteredHealth,
        startDate: _startDate,
        endDate: _endDate,
      );

      await PDFExportUtil.printPDF(pdfData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe enviado a impresión')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar informe: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}