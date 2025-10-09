import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/auth_provider.dart';
import '../models/medication.dart';
import 'add_medication_screen.dart';

/// Pantalla para listar y gestionar dosis de medicamentos.
/// Incluye lista organizada por tipo, opciones de editar/eliminar.
/// Compatible con WCAG 2.2 AA para accesibilidad.
/// Compatible con Dart 3.0 y null-safety.
class ListMedicationScreen extends StatefulWidget {
  const ListMedicationScreen({super.key});

  @override
  State<ListMedicationScreen> createState() => _ListMedicationScreenState();
}

class _ListMedicationScreenState extends State<ListMedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: MedicationType.values.length, vsync: this);

    // Cargar medicamentos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      if (authProvider.user != null) {
        medicationProvider.loadAll(authProvider.user!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMedicationScreen(),
                ),
              );
            },
            tooltip: 'Agregar dosis',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: MedicationType.values.map((type) {
            return Tab(text: _getTypeLabel(type));
          }).toList(),
        ),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, medicationProvider, child) {
          if (medicationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando medicamentos',
              ),
            );
          }

          if (medicationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    medicationProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.user != null) {
                        medicationProvider.loadAll(authProvider.user!.id);
                      }
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: MedicationType.values.map((type) {
              final medicationsOfType = medicationProvider.entries
                  .where((med) => med.type == type)
                  .toList();

              if (medicationsOfType.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getTypeIcon(type), size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No hay dosis de ${_getTypeLabel(type).toLowerCase()}',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: medicationsOfType.length,
                itemBuilder: (context, index) {
                  final medication = medicationsOfType[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(type),
                        child: Icon(_getTypeIcon(type), color: Colors.white),
                      ),
                      title: Text(
                        '${medication.name} - ${medication.formattedDose()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        medication.timestamp.toLocal().toString().split('.')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              // TODO: Implementar edición
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edición próximamente')),
                              );
                              break;
                            case 'delete':
                              _showDeleteDialog(context, medication);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        _showMedicationDetails(context, medication);
                      },
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _getTypeLabel(MedicationType type) {
    switch (type) {
      case MedicationType.bolus:
        return 'Bolo';
      case MedicationType.basal:
        return 'Basal';
      case MedicationType.correction:
        return 'Corrección';
      case MedicationType.other:
        return 'Otros';
    }
  }

  IconData _getTypeIcon(MedicationType type) {
    switch (type) {
      case MedicationType.bolus:
        return Icons.restaurant;
      case MedicationType.basal:
        return Icons.schedule;
      case MedicationType.correction:
        return Icons.warning;
      case MedicationType.other:
        return Icons.medication;
    }
  }

  Color _getTypeColor(MedicationType type) {
    switch (type) {
      case MedicationType.bolus:
        return Colors.orange;
      case MedicationType.basal:
        return Colors.blue;
      case MedicationType.correction:
        return Colors.red;
      case MedicationType.other:
        return Colors.grey;
    }
  }

  void _showDeleteDialog(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Dosis'),
        content: const Text('¿Estás seguro de que quieres eliminar esta dosis de medicamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
              if (authProvider.user != null) {
                await medicationProvider.deleteMedication(medication.id, authProvider.user!.id);
              }
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showMedicationDetails(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${medication.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosis: ${medication.formattedDose()}'),
            Text('Tipo: ${_getTypeLabel(medication.type)}'),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${medication.timestamp.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}