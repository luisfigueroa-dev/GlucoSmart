import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glucose_provider.dart';
import '../providers/auth_provider.dart';
import '../models/glucose.dart';

/// Pantalla para agregar una nueva medición de glucosa.
/// Incluye campos para valor, timestamp y notas opcionales.
/// Implementa validación de formulario, integración con GlucoseProvider,
/// accesibilidad WCAG 2.2 AA y navegación de vuelta tras guardar.
/// Compatible con Dart 3.0 y null-safety.
class AddGlucoseScreen extends StatefulWidget {
  const AddGlucoseScreen({super.key});

  @override
  State<AddGlucoseScreen> createState() => _AddGlucoseScreenState();
}

class _AddGlucoseScreenState extends State<AddGlucoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Valida que el valor de glucosa sea un número positivo.
  /// Retorna null si es válido, o un mensaje de error en caso contrario.
  String? _validateGlucoseValue(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un valor de glucosa';
    }
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Ingrese un número válido';
    }
    if (doubleValue <= 0) {
      return 'El valor debe ser mayor a 0';
    }
    if (doubleValue > 1000) {
      return 'Valor demasiado alto (máx. 1000 mg/dL)';
    }
    return null;
  }

  /// Muestra el selector de fecha y hora para el timestamp.
  /// Actualiza [_selectedDateTime] con la selección del usuario.
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Seleccione la fecha de la medición',
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        helpText: 'Seleccione la hora de la medición',
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  /// Guarda la nueva medición de glucosa.
  /// Valida el formulario, crea la instancia de Glucose y la agrega vía provider.
  /// Navega de vuelta si es exitoso, muestra error en caso contrario.
  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final value = double.parse(_valueController.text);
    final notes = _notesController.text.isEmpty ? null : _notesController.text;

    // Crear instancia de Glucose sin ID (se genera en BD)
    final glucose = Glucose(
      id: '', // Se asignará en el provider
      userId: authProvider.user!.id,
      value: value,
      timestamp: _selectedDateTime,
      notes: notes,
    );

    try {
      await glucoseProvider.addMeasurement(glucose);
      if (glucoseProvider.error == null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(glucoseProvider.error!)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Medición de Glucosa'),
        actions: [
          Consumer<GlucoseProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Guardando medición',
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: provider.isLoading ? null : _saveMeasurement,
                tooltip: 'Guardar medición',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo para valor de glucosa
              Semantics(
                label: 'Campo para ingresar el valor de glucosa en mg/dL',
                hint: 'Ingrese un número entre 1 y 1000',
                child: TextFormField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    labelText: 'Valor de Glucosa (mg/dL)',
                    hintText: 'Ej: 120',
                    border: OutlineInputBorder(),
                    suffixText: 'mg/dL',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateGlucoseValue,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para timestamp
              Semantics(
                label: 'Campo para seleccionar fecha y hora de la medición',
                hint: 'Toque para abrir el selector de fecha y hora',
                child: InkWell(
                  onTap: _selectDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y Hora',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_selectedDateTime.toLocal().toString().split('.')[0]}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo para notas
              Semantics(
                label: 'Campo opcional para notas sobre la medición',
                hint: 'Describa el contexto, como después de comer',
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: Después del desayuno',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: 24),
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: Consumer<GlucoseProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveMeasurement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                              semanticsLabel: 'Guardando medición',
                            )
                          : const Text('Guardar Medición'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}