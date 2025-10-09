import 'package:flutter/foundation.dart';
import '../models/personalized_plan.dart';
import '../repositories/personalized_plan_repo.dart';

/// Provider para gestionar planes personalizados.
/// Maneja estado de planes, generación con IA y operaciones CRUD.
class PersonalizedPlanProvider with ChangeNotifier {
  /// Repositorio para operaciones de BD.
  final PersonalizedPlanRepository _repository;

  /// Lista de planes activos.
  List<PersonalizedPlan> _activePlans = [];

  /// Plan activo actual.
  PersonalizedPlan? _currentPlan;

  /// Estado de carga.
  bool _isLoading = false;

  /// Mensaje de error.
  String? _error;

  /// Constructor que recibe el repositorio.
  PersonalizedPlanProvider(this._repository);

  /// Getter para planes activos.
  List<PersonalizedPlan> get activePlans => _activePlans;

  /// Getter para plan actual.
  PersonalizedPlan? get currentPlan => _currentPlan;

  /// Getter para estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para mensaje de error.
  String? get error => _error;

  /// Carga planes activos del usuario.
  Future<void> loadActivePlans(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _activePlans = await _repository.getActivePlans(userId);
      _currentPlan = await _repository.getLatestActivePlan(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Genera un nuevo plan personalizado usando IA.
  /// Requiere datos históricos del usuario para análisis.
  Future<void> generatePersonalizedPlan(
    String userId, {
    required List<double> glucoseHistory,
    required List<int> carbsHistory,
    required List<double> activityHistory,
    required Map<String, dynamic> healthMetrics,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      // Análisis básico de datos (en producción usar modelo ML complejo)
      final avgGlucose = glucoseHistory.isNotEmpty
          ? glucoseHistory.reduce((a, b) => a + b) / glucoseHistory.length
          : 100.0;

      final avgCarbs = carbsHistory.isNotEmpty
          ? carbsHistory.reduce((a, b) => a + b) / carbsHistory.length
          : 50;

      final riskLevel = _calculateRiskLevel(avgGlucose, healthMetrics);

      // Generar recomendaciones basadas en análisis
      final recommendations = _generateRecommendations(
        avgGlucose,
        avgCarbs.toInt(),
        activityHistory,
        healthMetrics,
        riskLevel,
      );

      final plan = PersonalizedPlan(
        id: '', // Se asignará en BD
        userId: userId,
        title: _generatePlanTitle(riskLevel),
        description: _generatePlanDescription(avgGlucose, riskLevel),
        goals: _generateGoals(riskLevel),
        recommendations: recommendations,
        riskLevel: riskLevel,
        generatedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
      );

      final createdPlan = await _repository.createPlan(plan);
      _activePlans.insert(0, createdPlan);
      _currentPlan = createdPlan;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Desactiva un plan.
  Future<void> deactivatePlan(String planId) async {
    try {
      await _repository.deactivatePlan(planId, _currentPlan!.userId);
      _activePlans.removeWhere((plan) => plan.id == planId);
      if (_currentPlan?.id == planId) {
        _currentPlan = _activePlans.isNotEmpty ? _activePlans.first : null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Método auxiliar para calcular nivel de riesgo.
  RiskLevel _calculateRiskLevel(double avgGlucose, Map<String, dynamic> healthMetrics) {
    if (avgGlucose > 180 || healthMetrics['hba1c'] > 8.0) {
      return RiskLevel.high;
    } else if (avgGlucose > 140 || healthMetrics['hba1c'] > 7.0) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  /// Genera recomendaciones basadas en análisis.
  PlanRecommendations _generateRecommendations(
    double avgGlucose,
    int avgCarbs,
    List<double> activityHistory,
    Map<String, dynamic> healthMetrics,
    RiskLevel riskLevel,
  ) {
    final nutrition = <String>[];
    final exercise = <String>[];
    final medication = <String>[];
    final monitoring = <String>[];
    final lifestyle = <String>[];

    // Recomendaciones nutricionales
    if (avgCarbs > 60) {
      nutrition.add('Reducir ingesta de carbohidratos a 45-60g por comida');
    } else if (avgCarbs < 30) {
      nutrition.add('Aumentar carbohidratos complejos para mantener energía');
    }
    nutrition.add('Priorizar vegetales, proteínas magras y grasas saludables');
    nutrition.add('Distribuir comidas cada 3-4 horas para estabilidad glucémica');

    // Recomendaciones de ejercicio
    final avgActivity = activityHistory.isNotEmpty
        ? activityHistory.reduce((a, b) => a + b) / activityHistory.length
        : 0.0;
    if (avgActivity < 5000) {
      exercise.add('Caminar al menos 30 minutos diarios');
      exercise.add('Incorporar actividad física moderada 5 días por semana');
    }
    exercise.add('Combinar ejercicio cardiovascular con entrenamiento de fuerza');

    // Recomendaciones de medicación
    if (riskLevel == RiskLevel.high) {
      medication.add('Consultar con endocrinólogo para ajuste de tratamiento');
      medication.add('Considerar terapia intensiva de insulina si aplica');
    }

    // Recomendaciones de monitoreo
    monitoring.add('Medir glucosa antes y después de comidas');
    monitoring.add('Registrar síntomas de hipo/hiperglucemia');
    if (riskLevel != RiskLevel.low) {
      monitoring.add('Monitoreo continuo si está disponible');
    }

    // Recomendaciones de estilo de vida
    lifestyle.add('Dormir 7-8 horas por noche');
    lifestyle.add('Manejar estrés con técnicas de relajación');
    lifestyle.add('Mantener peso saludable y BMI óptimo');

    return PlanRecommendations(
      nutrition: nutrition,
      exercise: exercise,
      medication: medication,
      monitoring: monitoring,
      lifestyle: lifestyle,
    );
  }

  /// Genera título del plan basado en riesgo.
  String _generatePlanTitle(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Plan de Mantenimiento Estable';
      case RiskLevel.medium:
        return 'Plan de Mejora del Control';
      case RiskLevel.high:
        return 'Plan de Control Intensivo';
    }
  }

  /// Genera descripción del plan.
  String _generatePlanDescription(double avgGlucose, RiskLevel riskLevel) {
    final baseDesc = 'Plan personalizado generado el ${DateTime.now().toString().split(' ')[0]}. ';
    final glucoseDesc = 'Glucosa promedio: ${avgGlucose.toStringAsFixed(1)} mg/dL. ';

    switch (riskLevel) {
      case RiskLevel.low:
        return baseDesc + glucoseDesc + 'Tu control es estable. Enfócate en mantener hábitos saludables.';
      case RiskLevel.medium:
        return baseDesc + glucoseDesc + 'Hay oportunidades de mejora. Sigue las recomendaciones para optimizar tu control.';
      case RiskLevel.high:
        return baseDesc + glucoseDesc + 'Se requiere atención inmediata. Consulta con tu equipo médico.';
    }
  }

  /// Genera objetivos del plan.
  List<String> _generateGoals(RiskLevel riskLevel) {
    final goals = <String>[];

    switch (riskLevel) {
      case RiskLevel.low:
        goals.add('Mantener glucosa en rango 70-140 mg/dL');
        goals.add('Continuar con alimentación balanceada');
        goals.add('Mantener rutina de ejercicio');
        break;
      case RiskLevel.medium:
        goals.add('Reducir glucosa promedio en 20-30 mg/dL');
        goals.add('Mejorar HbA1c por debajo de 7.0%');
        goals.add('Aumentar actividad física semanal');
        break;
      case RiskLevel.high:
        goals.add('Lograr control glucémico estable');
        goals.add('Reducir episodios de hiperglucemia');
        goals.add('Consultar especialista para ajuste de tratamiento');
        break;
    }

    return goals;
  }

  /// Método auxiliar para cambiar estado de carga.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Limpia el error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}