import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/personalized_plan_provider.dart';
import '../providers/glucose_provider.dart';
import '../providers/carbs_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/health_parameter_provider.dart';
import '../providers/auth_provider.dart';
import '../models/personalized_plan.dart';

/// Pantalla para mostrar y gestionar planes personalizados.
/// Permite ver plan actual, generar nuevos y gestionar historial.
/// Compatible con WCAG 2.2 AA para accesibilidad.
class PersonalizedPlanScreen extends StatefulWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  State<PersonalizedPlanScreen> createState() => _PersonalizedPlanScreenState();
}

class _PersonalizedPlanScreenState extends State<PersonalizedPlanScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final planProvider = Provider.of<PersonalizedPlanProvider>(context, listen: false);

    if (authProvider.user != null) {
      await planProvider.loadActivePlans(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes Personalizados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<PersonalizedPlanProvider>(
        builder: (context, planProvider, child) {
          if (planProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (planProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${planProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final currentPlan = planProvider.currentPlan;

          if (currentPlan == null) {
            return _buildNoPlanView(planProvider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan actual
                _buildCurrentPlanCard(currentPlan),
                const SizedBox(height: 24),

                // Objetivos
                _buildGoalsSection(currentPlan),
                const SizedBox(height: 24),

                // Recomendaciones
                _buildRecommendationsSection(currentPlan),
                const SizedBox(height: 24),

                // Acciones
                _buildActionsSection(currentPlan, planProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNewPlan,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Generar Plan IA'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNoPlanView(PersonalizedPlanProvider planProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'No tienes un plan personalizado activo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Genera un plan personalizado con IA basado en tus datos históricos',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateNewPlan,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Generar Plan con IA'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(PersonalizedPlan plan) {
    final riskColor = _getRiskColor(plan.riskLevel);
    final riskIcon = _getRiskIcon(plan.riskLevel);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(riskIcon, color: riskColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRiskLevelText(plan.riskLevel),
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              plan.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Válido hasta: ${_formatDate(plan.validUntil)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(PersonalizedPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Objetivos del Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...plan.goals.map((goal) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(goal)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRecommendationsSection(PersonalizedPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendaciones Personalizadas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Nutrición
        if (plan.recommendations.nutrition.isNotEmpty) ...[
          _buildRecommendationCategory(
            'Nutrición',
            Icons.restaurant,
            Colors.orange,
            plan.recommendations.nutrition,
          ),
          const SizedBox(height: 16),
        ],

        // Ejercicio
        if (plan.recommendations.exercise.isNotEmpty) ...[
          _buildRecommendationCategory(
            'Ejercicio',
            Icons.directions_run,
            Colors.blue,
            plan.recommendations.exercise,
          ),
          const SizedBox(height: 16),
        ],

        // Medicación
        if (plan.recommendations.medication.isNotEmpty) ...[
          _buildRecommendationCategory(
            'Medicación',
            Icons.medication,
            Colors.red,
            plan.recommendations.medication,
          ),
          const SizedBox(height: 16),
        ],

        // Monitoreo
        if (plan.recommendations.monitoring.isNotEmpty) ...[
          _buildRecommendationCategory(
            'Monitoreo',
            Icons.monitor_heart,
            Colors.purple,
            plan.recommendations.monitoring,
          ),
          const SizedBox(height: 16),
        ],

        // Estilo de vida
        if (plan.recommendations.lifestyle.isNotEmpty) ...[
          _buildRecommendationCategory(
            'Estilo de Vida',
            Icons.self_improvement,
            Colors.green,
            plan.recommendations.lifestyle,
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendationCategory(String title, IconData icon, Color color, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(PersonalizedPlan plan, PersonalizedPlanProvider planProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showDeactivateDialog(plan, planProvider),
                icon: const Icon(Icons.archive),
                label: const Text('Archivar Plan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _generateNewPlan,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generateNewPlan() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final planProvider = Provider.of<PersonalizedPlanProvider>(context, listen: false);
    final glucoseProvider = Provider.of<GlucoseProvider>(context, listen: false);
    final carbsProvider = Provider.of<CarbsProvider>(context, listen: false);
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthParameterProvider>(context, listen: false);

    if (authProvider.user == null) return;

    // Cargar datos históricos
    await glucoseProvider.loadLast7Days(authProvider.user!.id);
    await carbsProvider.loadLast7Days(authProvider.user!.id);
    await activityProvider.loadLast7DaysActivities(authProvider.user!.id);
    await healthProvider.loadLast30DaysParameters(authProvider.user!.id);

    // Preparar datos para IA
    final glucoseHistory = glucoseProvider.measurements.map((g) => g.value).toList();
    final carbsHistory = carbsProvider.entries.map((c) => c.grams).toList();
    final activityHistory = activityProvider.activities.map((a) => a.caloriesBurned).toList();

    // Métricas de salud (simplificadas)
    final healthMetrics = <String, dynamic>{
      'hba1c': 6.5, // En producción obtener de health parameters
      'weight': 70.0,
      'bloodPressure': 120.0,
    };

    await planProvider.generatePersonalizedPlan(
      authProvider.user!.id,
      glucoseHistory: glucoseHistory,
      carbsHistory: carbsHistory,
      activityHistory: activityHistory,
      healthMetrics: healthMetrics,
    );

    if (planProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan personalizado generado exitosamente')),
      );
    }
  }

  Future<void> _showDeactivateDialog(PersonalizedPlan plan, PersonalizedPlanProvider planProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivar Plan'),
        content: const Text('¿Estás seguro de que quieres archivar este plan? Podrás generar uno nuevo en cualquier momento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await planProvider.deactivatePlan(plan.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan archivado')),
      );
    }
  }

  Color _getRiskColor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  IconData _getRiskIcon(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
    }
  }

  String _getRiskLevelText(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Riesgo Bajo';
      case RiskLevel.medium:
        return 'Riesgo Medio';
      case RiskLevel.high:
        return 'Riesgo Alto';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}