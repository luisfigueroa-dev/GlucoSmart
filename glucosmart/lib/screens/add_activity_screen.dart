import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../models/activity.dart';

/// Pantalla para agregar una nueva entrada de actividad física.
/// Incluye campos para pasos, calorías quemadas, duración, tipo de actividad y timestamp.
/// Implementa validación de formulario, integración con ActivityProvider,
/// accesibilidad WCAG 2.2 AA y navegación de vuelta tras guardar.
/// Compatible con Dart 3.0 y null-safety.
class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _durationController = TextEditingController();
  final _activityTypeController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    _activityTypeController.dispose();
    super.dispose();
  }

  /// Valida que los pasos sean un número entero positivo.
  String? _validateSteps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese el número de pasos';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Ingrese un número entero válido';
    }
    if (intValue <= 0) {
      return 'Los pasos deben ser mayor a 0';
    }
    if (intValue > 100000) {
      return 'Número de pasos demasiado alto (máx. 100,000)';
    }
    return null;
  }

  /// Valida que las calorías sean un número positivo.
  String? _validateCalories(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese las calorías quemadas';
    }
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Ingrese un número válido';
    }
    if (doubleValue <= 0) {
      return 'Las calorías deben ser mayor a 0';
    }
    if (doubleValue > 10000) {
      return 'Calorías demasiado altas (máx. 10,000)';
    }
    return null;
  }

  /// Valida que la duración sea un número entero positivo (opcional).
  String? _validateDuration(String? value) {
    if (value != null && value.isNotEmpty) {
      final intValue = int.tryParse(value);
      if (intValue == null) {
        return 'Ingrese un número entero válido';
      }
      if (intValue <= 0) {
        return 'La duración debe ser mayor a 0';
      }
      if (intValue > 1440) {
        return 'Duración demasiado larga (máx. 1440 minutos)';
      }
    }
    return null;
  }

  /// Muestra el selector de fecha y hora para el timestamp.
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Seleccione la fecha de la actividad',
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        helpText: 'Seleccione la hora de la actividad',
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

  /// Guarda la nueva entrada de actividad.
  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final steps = int.parse(_stepsController.text);
    final caloriesBurned = double.parse(_caloriesController.text);
    final durationMinutes = _durationController.text.isEmpty ? null : int.parse(_durationController.text);
    final activityType = _activityTypeController.text.isEmpty ? null : _activityTypeController.text;

    final activity = Activity(
      id: '',
      userId: authProvider.user!.id,
      steps: steps,
      caloriesBurned: caloriesBurned,
      timestamp: _selectedDateTime,
      durationMinutes: durationMinutes,
      activityType: activityType,
    );

    try {
      await activityProvider.addActivity(activity);
      if (activityProvider.error == null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(activityProvider.error!)),
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
        title: const Text('Agregar Actividad Física'),
        actions: [
          Consumer<ActivityProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Guardando actividad',
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: provider.isLoading ? null : _saveActivity,
                tooltip: 'Guardar actividad',
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
              // Campo para pasos
              Semantics(
                label: 'Campo para ingresar el número de pasos dados',
                hint: 'Ingrese un número entero entre 1 y 100,000',
                child: TextFormField(
                  controller: _stepsController,
                  decoration: const InputDecoration(
                    labelText: 'Pasos',
                    hintText: 'Ej: 8000',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateSteps,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para calorías
              Semantics(
                label: 'Campo para ingresar las calorías quemadas',
                hint: 'Ingrese un número entre 0.1 y 10,000',
                child: TextFormField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calorías Quemadas',
                    hintText: 'Ej: 350.5',
                    border: OutlineInputBorder(),
                    suffixText: 'kcal',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateCalories,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para duración
              Semantics(
                label: 'Campo opcional para la duración de la actividad en minutos',
                hint: 'Ingrese un número entero positivo',
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duración (minutos, opcional)',
                    hintText: 'Ej: 60',
                    border: OutlineInputBorder(),
                    suffixText: 'min',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateDuration,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para tipo de actividad
              Semantics(
                label: 'Campo opcional para el tipo de actividad física',
                hint: 'Describa la actividad realizada',
                child: TextFormField(
                  controller: _activityTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Actividad (opcional)',
                    hintText: 'Ej: Caminar, Correr, Bicicleta',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para timestamp
              Semantics(
                label: 'Campo para seleccionar fecha y hora de la actividad',
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
              const SizedBox(height: 24),
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: Consumer<ActivityProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveActivity,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                              semanticsLabel: 'Guardando actividad',
                            )
                          : const Text('Guardar Actividad'),
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