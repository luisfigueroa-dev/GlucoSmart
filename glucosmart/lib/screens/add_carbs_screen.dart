import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carbs_provider.dart';
import '../providers/auth_provider.dart';
import '../models/carbs.dart';

/// Pantalla para agregar una nueva ingesta de carbohidratos.
/// Incluye campos para gramos, timestamp y alimento opcional.
/// Implementa validación de formulario, integración con CarbsProvider,
/// accesibilidad WCAG 2.2 AA y navegación de vuelta tras guardar.
/// Compatible con Dart 3.0 y null-safety.
class AddCarbsScreen extends StatefulWidget {
  const AddCarbsScreen({super.key});

  @override
  State<AddCarbsScreen> createState() => _AddCarbsScreenState();
}

class _AddCarbsScreenState extends State<AddCarbsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gramsController = TextEditingController();
  final _foodController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _gramsController.dispose();
    _foodController.dispose();
    super.dispose();
  }

  /// Valida que la cantidad de gramos sea un número entero positivo.
  /// Retorna null si es válido, o un mensaje de error en caso contrario.
  String? _validateGrams(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese la cantidad de gramos';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Ingrese un número entero válido';
    }
    if (intValue <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    if (intValue > 500) {
      return 'Cantidad demasiado alta (máx. 500g)';
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
      helpText: 'Seleccione la fecha de la ingesta',
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        helpText: 'Seleccione la hora de la ingesta',
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

  /// Guarda la nueva ingesta de carbohidratos.
  /// Valida el formulario, crea la instancia de Carbs y la agrega vía provider.
  /// Navega de vuelta si es exitoso, muestra error en caso contrario.
  Future<void> _saveIntake() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final carbsProvider = Provider.of<CarbsProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final grams = int.parse(_gramsController.text);
    final food = _foodController.text.isEmpty ? null : _foodController.text;

    // Crear instancia de Carbs sin ID (se genera en BD)
    final carbs = Carbs(
      id: '', // Se asignará en el provider
      userId: authProvider.user!.id,
      grams: grams,
      timestamp: _selectedDateTime,
      food: food,
    );

    try {
      await carbsProvider.addCarbsIntake(carbs);
      if (carbsProvider.error == null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(carbsProvider.error!)),
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
        title: const Text('Agregar Ingesta de Carbohidratos'),
        actions: [
          Consumer<CarbsProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Guardando ingesta',
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: provider.isLoading ? null : _saveIntake,
                tooltip: 'Guardar ingesta',
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
              // Campo para gramos
              Semantics(
                label: 'Campo para ingresar la cantidad de gramos de carbohidratos',
                hint: 'Ingrese un número entero entre 1 y 500',
                child: TextFormField(
                  controller: _gramsController,
                  decoration: const InputDecoration(
                    labelText: 'Gramos de Carbohidratos',
                    hintText: 'Ej: 50',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateGrams,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para timestamp
              Semantics(
                label: 'Campo para seleccionar fecha y hora de la ingesta',
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
              // Campo para alimento
              Semantics(
                label: 'Campo opcional para el nombre del alimento',
                hint: 'Describa el alimento consumido',
                child: TextFormField(
                  controller: _foodController,
                  decoration: const InputDecoration(
                    labelText: 'Alimento (opcional)',
                    hintText: 'Ej: Pan integral',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(height: 24),
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: Consumer<CarbsProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveIntake,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                              semanticsLabel: 'Guardando ingesta',
                            )
                          : const Text('Guardar Ingesta'),
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