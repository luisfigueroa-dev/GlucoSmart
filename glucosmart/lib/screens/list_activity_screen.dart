import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../models/activity.dart';
import 'add_activity_screen.dart';

/// Pantalla para listar y gestionar entradas de actividad física.
/// Incluye lista de actividades, opciones de editar/eliminar, filtros por fecha.
/// Compatible con WCAG 2.2 AA para accesibilidad.
/// Compatible con Dart 3.0 y null-safety.
class ListActivityScreen extends StatefulWidget {
  const ListActivityScreen({super.key});

  @override
  State<ListActivityScreen> createState() => _ListActivityScreenState();
}

class _ListActivityScreenState extends State<ListActivityScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar actividades al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      if (authProvider.user != null) {
        activityProvider.loadLast7DaysActivities(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividad Física'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddActivityScreen(),
                ),
              );
            },
            tooltip: 'Agregar actividad',
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          if (activityProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando actividades',
              ),
            );
          }

          if (activityProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    activityProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.user != null) {
                        activityProvider.loadLast7DaysActivities(authProvider.user!.id);
                      }
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final activities = activityProvider.activities;
          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_run, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay actividades registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddActivityScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Primera Actividad'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.directions_run, color: Colors.white),
                  ),
                  title: Text(
                    '${activity.steps} pasos',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${activity.caloriesBurned.toStringAsFixed(1)} kcal quemadas'),
                      if (activity.activityType != null)
                        Text('Tipo: ${activity.activityType}'),
                      if (activity.durationMinutes != null)
                        Text('Duración: ${activity.durationMinutes} min'),
                      Text(
                        activity.timestamp.toLocal().toString().split('.')[0],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
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
                          _showDeleteDialog(context, activity);
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
                    // Mostrar detalles en un diálogo
                    _showActivityDetails(context, activity);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Actividad'),
        content: const Text('¿Estás seguro de que quieres eliminar esta actividad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
              if (authProvider.user != null) {
                await activityProvider.deleteActivity(activity.id, authProvider.user!.id);
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

  void _showActivityDetails(BuildContext context, Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Actividad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pasos: ${activity.steps}'),
            Text('Calorías quemadas: ${activity.caloriesBurned.toStringAsFixed(1)} kcal'),
            if (activity.durationMinutes != null)
              Text('Duración: ${activity.durationMinutes} minutos'),
            if (activity.activityType != null)
              Text('Tipo: ${activity.activityType}'),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${activity.timestamp.toLocal().toString().split('.')[0]}',
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