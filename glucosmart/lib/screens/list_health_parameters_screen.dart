import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_parameter_provider.dart';
import '../providers/auth_provider.dart';
import '../models/health_parameter.dart';
import 'add_health_parameter_screen.dart';

/// Pantalla para listar y gestionar parámetros de salud.
/// Incluye lista organizada por tipo, opciones de editar/eliminar.
/// Compatible con WCAG 2.2 AA para accesibilidad.
/// Compatible con Dart 3.0 y null-safety.
class ListHealthParametersScreen extends StatefulWidget {
  const ListHealthParametersScreen({super.key});

  @override
  State<ListHealthParametersScreen> createState() => _ListHealthParametersScreenState();
}

class _ListHealthParametersScreenState extends State<ListHealthParametersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: HealthParameterType.values.length, vsync: this);

    // Cargar parámetros al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final healthProvider = Provider.of<HealthParameterProvider>(context, listen: false);
      if (authProvider.user != null) {
        healthProvider.loadLast30DaysParameters(authProvider.user!.id);
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
        title: const Text('Parámetros de Salud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddHealthParameterScreen(),
                ),
              );
            },
            tooltip: 'Agregar parámetro',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: HealthParameterType.values.map((type) {
            return Tab(text: _getTypeLabel(type));
          }).toList(),
        ),
      ),
      body: Consumer<HealthParameterProvider>(
        builder: (context, healthProvider, child) {
          if (healthProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando parámetros de salud',
              ),
            );
          }

          if (healthProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    healthProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.user != null) {
                        healthProvider.loadLast30DaysParameters(authProvider.user!.id);
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
            children: HealthParameterType.values.map((type) {
              final parametersOfType = healthProvider.parameters
                  .where((param) => param.type == type)
                  .toList();

              if (parametersOfType.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getTypeIcon(type), size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No hay registros de ${_getTypeLabel(type).toLowerCase()}',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: parametersOfType.length,
                itemBuilder: (context, index) {
                  final parameter = parametersOfType[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(type),
                        child: Icon(_getTypeIcon(type), color: Colors.white),
                      ),
                      title: Text(
                        '${parameter.value} ${parameter.unit ?? parameter.defaultUnit}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (parameter.notes != null && parameter.notes!.isNotEmpty)
                            Text(parameter.notes!),
                          Text(
                            parameter.timestamp.toLocal().toString().split('.')[0],
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            parameter.isNormal() ? Icons.check_circle : Icons.warning,
                            color: parameter.isNormal() ? Colors.green : Colors.orange,
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  // TODO: Implementar edición
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Edición próximamente')),
                                  );
                                  break;
                                case 'delete':
                                  _showDeleteDialog(context, parameter);
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
                        ],
                      ),
                      onTap: () {
                        _showParameterDetails(context, parameter);
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

  String _getTypeLabel(HealthParameterType type) {
    switch (type) {
      case HealthParameterType.weight:
        return 'Peso';
      case HealthParameterType.hba1c:
        return 'HbA1c';
      case HealthParameterType.bloodPressure:
        return 'Presión';
      case HealthParameterType.sleepHours:
        return 'Sueño';
    }
  }

  IconData _getTypeIcon(HealthParameterType type) {
    switch (type) {
      case HealthParameterType.weight:
        return Icons.monitor_weight;
      case HealthParameterType.hba1c:
        return Icons.science;
      case HealthParameterType.bloodPressure:
        return Icons.favorite;
      case HealthParameterType.sleepHours:
        return Icons.bedtime;
    }
  }

  Color _getTypeColor(HealthParameterType type) {
    switch (type) {
      case HealthParameterType.weight:
        return Colors.blue;
      case HealthParameterType.hba1c:
        return Colors.purple;
      case HealthParameterType.bloodPressure:
        return Colors.red;
      case HealthParameterType.sleepHours:
        return Colors.indigo;
    }
  }

  void _showDeleteDialog(BuildContext context, HealthParameter parameter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Parámetro'),
        content: const Text('¿Estás seguro de que quieres eliminar este parámetro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final healthProvider = Provider.of<HealthParameterProvider>(context, listen: false);
              if (authProvider.user != null) {
                await healthProvider.deleteParameter(parameter.id, authProvider.user!.id);
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

  void _showParameterDetails(BuildContext context, HealthParameter parameter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${_getTypeLabel(parameter.type)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor: ${parameter.value} ${parameter.unit ?? parameter.defaultUnit}'),
            if (parameter.notes != null && parameter.notes!.isNotEmpty)
              Text('Notas: ${parameter.notes}'),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${parameter.timestamp.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  parameter.isNormal() ? Icons.check_circle : Icons.warning,
                  color: parameter.isNormal() ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  parameter.isNormal() ? 'Valor normal' : 'Valor fuera de rango',
                  style: TextStyle(
                    color: parameter.isNormal() ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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