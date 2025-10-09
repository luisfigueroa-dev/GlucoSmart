import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_parameter_provider.dart';
import '../providers/auth_provider.dart';
import '../models/health_parameter.dart';

/// Pantalla para agregar un nuevo parámetro de salud.
/// Soporta múltiples tipos: peso, HbA1c, presión arterial, sueño.
/// Incluye validación específica por tipo y accesibilidad WCAG 2.2 AA.
/// Compatible con Dart 3.0 y null-safety.
class AddHealthParameterScreen extends StatefulWidget {
  const AddHealthParameterScreen({super.key});

  @override
  State<AddHealthParameterScreen> createState() => _AddHealthParameterScreenState();
}

class _AddHealthParameterScreenState extends State<AddHealthParameterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  HealthParameterType _selectedType = HealthParameterType.weight;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Valida el valor basado en el tipo seleccionado.
  String? _validateValue(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un valor';
    }
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Ingrese un número válido';
    }
    if (doubleValue <= 0) {
      return 'El valor debe ser mayor a 0';
    }

    // Validaciones específicas por tipo
    switch (_selectedType) {
      case HealthParameterType.weight:
        if (doubleValue > 500) return 'Peso demasiado alto (máx. 500 kg)';
        break;
      case HealthParameterType.hba1c:
        if (doubleValue > 20) return 'HbA1c demasiado alta (máx. 20%)';
        break;
      case HealthParameterType.bloodPressure:
        if (doubleValue > 300) return 'Presión demasiado alta (máx. 300 mmHg)';
        break;
      case HealthParameterType.sleepHours:
        if (doubleValue > 24) return 'Horas de sueño demasiado altas (máx. 24)';
        break;
    }
    return null;
  }

  /// Muestra el selector de fecha y hora.
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Seleccione la fecha del registro',
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        helpText: 'Seleccione la hora del registro',
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

  /// Guarda el nuevo parámetro de salud.
  Future<void> _saveParameter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthParameterProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final value = double.parse(_valueController.text);
    final unit = _getUnitForType(_selectedType);
    final notes = _notesController.text.isEmpty ? null : _notesController.text;

    final parameter = HealthParameter(
      id: '',
      userId: authProvider.user!.id,
      type: _selectedType,
      value: value,
      unit: unit,
      timestamp: _selectedDateTime,
      notes: notes,
    );

    try {
      await healthProvider.addParameter(parameter);
      if (healthProvider.error == null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(healthProvider.error!)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  /// Retorna la unidad por defecto para el tipo.
  String _getUnitForType(HealthParameterType type) {
    return HealthParameter(id: '', userId: '', type: type, value: 0, timestamp: DateTime.now()).defaultUnit;
  }

  /// Retorna el hint text para el campo de valor basado en el tipo.
  String _getHintForType(HealthParameterType type) {
    switch (type) {
      case HealthParameterType.weight:
        return 'Ej: 70.5';
      case HealthParameterType.hba1c:
        return 'Ej: 5.2';
      case HealthParameterType.bloodPressure:
        return 'Ej: 120 (sistólica)';
      case HealthParameterType.sleepHours:
        return 'Ej: 8.0';
    }
  }

  /// Retorna el label para el campo de valor basado en el tipo.
  String _getLabelForType(HealthParameterType type) {
    switch (type) {
      case HealthParameterType.weight:
        return 'Peso';
      case HealthParameterType.hba1c:
        return 'HbA1c';
      case HealthParameterType.bloodPressure:
        return 'Presión Arterial';
      case HealthParameterType.sleepHours:
        return 'Horas de Sueño';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Parámetro de Salud'),
        actions: [
          Consumer<HealthParameterProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Guardando parámetro',
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: provider.isLoading ? null : _saveParameter,
                tooltip: 'Guardar parámetro',
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
              // Selector de tipo
              Semantics(
                label: 'Selector de tipo de parámetro de salud',
                hint: 'Elija qué parámetro desea registrar',
                child: DropdownButtonFormField<HealthParameterType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Parámetro',
                    border: OutlineInputBorder(),
                  ),
                  items: HealthParameterType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getLabelForType(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Campo para valor
              Semantics(
                label: 'Campo para ingresar el valor del ${_getLabelForType(_selectedType).toLowerCase()}',
                hint: _getHintForType(_selectedType),
                child: TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: '${_getLabelForType(_selectedType)} (${_getUnitForType(_selectedType)})',
                    hintText: _getHintForType(_selectedType),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateValue,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para timestamp
              Semantics(
                label: 'Campo para seleccionar fecha y hora del registro',
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
                label: 'Campo opcional para notas sobre el registro',
                hint: 'Describa el contexto del registro',
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: Medición matutina',
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
                child: Consumer<HealthParameterProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveParameter,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                              semanticsLabel: 'Guardando parámetro',
                            )
                          : const Text('Guardar Parámetro'),
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