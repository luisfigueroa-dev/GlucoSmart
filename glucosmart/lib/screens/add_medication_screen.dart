import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/auth_provider.dart';
import '../models/medication.dart';

/// Pantalla para agregar una nueva dosis de medicamento.
/// Incluye campos para nombre, dosis, unidad, tipo y timestamp.
/// Implementa validación de formulario, integración con MedicationProvider,
/// accesibilidad WCAG 2.2 AA y navegación de vuelta tras guardar.
/// Compatible con Dart 3.0 y null-safety.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _unitController = TextEditingController();
  MedicationType _selectedType = MedicationType.bolus;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  /// Valida el nombre del medicamento.
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese el nombre del medicamento';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Valida la dosis.
  String? _validateDose(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese la dosis';
    }
    final doubleValue = double.tryParse(value);
    if (doubleValue == null) {
      return 'Ingrese un número válido';
    }
    if (doubleValue <= 0) {
      return 'La dosis debe ser mayor a 0';
    }
    if (doubleValue > 1000) {
      return 'Dosis demasiado alta (máx. 1000)';
    }
    return null;
  }

  /// Valida la unidad.
  String? _validateUnit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese la unidad';
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
      helpText: 'Seleccione la fecha de la dosis',
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        helpText: 'Seleccione la hora de la dosis',
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

  /// Guarda la nueva dosis de medicamento.
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final dose = double.parse(_doseController.text);
    final unit = _unitController.text.trim();

    final medication = Medication(
      id: '',
      userId: authProvider.user!.id,
      name: name,
      dose: dose,
      unit: unit,
      timestamp: _selectedDateTime,
      type: _selectedType,
    );

    try {
      await medicationProvider.addMedication(medication);
      if (medicationProvider.error == null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(medicationProvider.error!)),
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
        title: const Text('Agregar Dosis de Medicamento'),
        actions: [
          Consumer<MedicationProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Guardando dosis',
                        ),
                      )
                    : const Icon(Icons.save),
                onPressed: provider.isLoading ? null : _saveMedication,
                tooltip: 'Guardar dosis',
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
              // Campo para nombre
              Semantics(
                label: 'Campo para ingresar el nombre del medicamento',
                hint: 'Ej: Insulina rápida',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Medicamento',
                    hintText: 'Ej: Insulina rápida',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para dosis
              Semantics(
                label: 'Campo para ingresar la dosis del medicamento',
                hint: 'Ingrese un número entre 0.1 y 1000',
                child: TextFormField(
                  controller: _doseController,
                  decoration: const InputDecoration(
                    labelText: 'Dosis',
                    hintText: 'Ej: 5.0',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateDose,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Campo para unidad
              Semantics(
                label: 'Campo para ingresar la unidad de la dosis',
                hint: 'Ej: unidades, mg, ml',
                child: TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unidad',
                    hintText: 'Ej: unidades',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateUnit,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              // Selector de tipo
              Semantics(
                label: 'Selector de tipo de medicamento',
                hint: 'Elija el tipo de dosis',
                child: DropdownButtonFormField<MedicationType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Medicamento',
                    border: OutlineInputBorder(),
                  ),
                  items: MedicationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
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
              // Campo para timestamp
              Semantics(
                label: 'Campo para seleccionar fecha y hora de la dosis',
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
                child: Consumer<MedicationProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading ? null : _saveMedication,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                              semanticsLabel: 'Guardando dosis',
                            )
                          : const Text('Guardar Dosis'),
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

  /// Retorna el label legible para el tipo de medicamento.
  String _getTypeLabel(MedicationType type) {
    switch (type) {
      case MedicationType.bolus:
        return 'Bolo (antes de comidas)';
      case MedicationType.basal:
        return 'Basal (acción prolongada)';
      case MedicationType.correction:
        return 'Corrección (ajuste glucosa)';
      case MedicationType.other:
        return 'Otro';
    }
  }
}