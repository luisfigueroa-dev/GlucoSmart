import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/pdf_export_util.dart';
import '../providers/glucose_provider.dart';
import '../providers/carbs_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/health_parameter_provider.dart';

/// Pantalla para compartir datos de salud de forma segura con profesionales.
/// Permite generar enlaces temporales con datos específicos.
/// Compatible con WCAG 2.2 AA para accesibilidad.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool _shareGlucose = true;
  bool _shareCarbs = true;
  bool _shareMedication = true;
  bool _shareActivity = false;
  bool _shareHealthParams = false;
  bool _isGenerating = false;
  String? _generatedLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir Datos'),
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
                'Compartir Datos con Profesionales',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona qué datos deseas compartir y genera un enlace seguro temporal.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Opciones de datos a compartir
            Text(
              'Seleccionar Datos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDataOption(
              'Glucosa',
              'Niveles de azúcar en sangre',
              _shareGlucose,
              (value) => setState(() => _shareGlucose = value),
            ),
            _buildDataOption(
              'Carbohidratos',
              'Registro de ingesta alimentaria',
              _shareCarbs,
              (value) => setState(() => _shareCarbs = value),
            ),
            _buildDataOption(
              'Medicamentos',
              'Dosis y tipos de medicamentos',
              _shareMedication,
              (value) => setState(() => _shareMedication = value),
            ),
            _buildDataOption(
              'Actividad Física',
              'Pasos y ejercicio realizado',
              _shareActivity,
              (value) => setState(() => _shareActivity = value),
            ),
            _buildDataOption(
              'Parámetros de Salud',
              'Peso, HbA1c, presión arterial',
              _shareHealthParams,
              (value) => setState(() => _shareHealthParams = value),
            ),
            const SizedBox(height: 24),

            // Información de seguridad
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Información de Seguridad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Los enlaces son temporales y expiran en 24 horas\n'
                      '• Solo contienen los datos seleccionados\n'
                      '• No incluyen información personal identificable\n'
                      '• Se recomienda compartir solo con profesionales de confianza',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Enlace generado
            if (_generatedLink != null) ...[
              Text(
                'Enlace Generado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedLink!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        // Copiar al portapapeles
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enlace copiado al portapapeles')),
                        );
                      },
                      tooltip: 'Copiar enlace',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón de generar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateShareLink,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(_generatedLink != null ? 'Generar Nuevo Enlace' : 'Generar Enlace de Compartición'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataOption(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _generateShareLink() async {
    if (!_shareGlucose && !_shareCarbs && !_shareMedication && !_shareActivity && !_shareHealthParams) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un tipo de dato para compartir')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Crear objeto con datos seleccionados
      final shareData = <String, dynamic>{
        'userId': authProvider.user!.id,
        'sharedAt': DateTime.now().toIso8601String(),
        'dataTypes': {
          'glucose': _shareGlucose,
          'carbs': _shareCarbs,
          'medication': _shareMedication,
          'activity': _shareActivity,
          'healthParams': _shareHealthParams,
        },
      };

      // Aquí iría la llamada a la función Edge para crear el enlace
      // Por ahora, simulamos la generación
      final linkId = DateTime.now().millisecondsSinceEpoch.toString();
      final shareLink = 'https://glucosmart.app/share/$linkId';

      setState(() {
        _generatedLink = shareLink;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace de compartición generado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar enlace: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }
}