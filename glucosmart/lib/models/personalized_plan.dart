/// Modelo de datos para planes de tratamiento personalizados generados por IA.
/// Compatible con Supabase, incluye recomendaciones de alimentación, ejercicio y medicación.
/// Basado en análisis de datos históricos del usuario.
class PersonalizedPlan {
  /// Constructor constante para crear instancias inmutables.
  const PersonalizedPlan({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.goals,
    required this.recommendations,
    required this.riskLevel,
    required this.generatedAt,
    required this.validUntil,
    this.isActive = true,
  });

  /// Identificador único del plan (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario del plan.
  final String userId;

  /// Título descriptivo del plan.
  final String title;

  /// Descripción detallada del plan.
  final String description;

  /// Lista de objetivos específicos del plan.
  final List<String> goals;

  /// Recomendaciones estructuradas por categoría.
  final PlanRecommendations recommendations;

  /// Nivel de riesgo calculado (bajo, medio, alto).
  final RiskLevel riskLevel;

  /// Fecha de generación del plan.
  final DateTime generatedAt;

  /// Fecha de expiración del plan (normalmente 30 días).
  final DateTime validUntil;

  /// Indica si el plan está activo.
  final bool isActive;

  /// Crea una instancia desde un mapa JSON.
  factory PersonalizedPlan.fromJson(Map<String, dynamic> json) {
    return PersonalizedPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      goals: List<String>.from(json['goals'] ?? []),
      recommendations: PlanRecommendations.fromJson(json['recommendations'] ?? {}),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => RiskLevel.medium,
      ),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
      isActive: json['is_active'] ?? true,
    );
  }

  /// Convierte la instancia a un mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'goals': goals,
      'recommendations': recommendations.toJson(),
      'risk_level': riskLevel.name,
      'generated_at': generatedAt.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Verifica si el plan está expirado.
  bool get isExpired => DateTime.now().isAfter(validUntil);

  /// Crea una copia con campos modificados.
  PersonalizedPlan copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? goals,
    PlanRecommendations? recommendations,
    RiskLevel? riskLevel,
    DateTime? generatedAt,
    DateTime? validUntil,
    bool? isActive,
  }) {
    return PersonalizedPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      goals: goals ?? this.goals,
      recommendations: recommendations ?? this.recommendations,
      riskLevel: riskLevel ?? this.riskLevel,
      generatedAt: generatedAt ?? this.generatedAt,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Niveles de riesgo para clasificación de planes.
enum RiskLevel {
  /// Riesgo bajo - control estable.
  low,

  /// Riesgo medio - requiere monitoreo.
  medium,

  /// Riesgo alto - atención inmediata necesaria.
  high,
}

/// Recomendaciones estructuradas del plan personalizado.
class PlanRecommendations {
  const PlanRecommendations({
    required this.nutrition,
    required this.exercise,
    required this.medication,
    required this.monitoring,
    required this.lifestyle,
  });

  /// Recomendaciones nutricionales.
  final List<String> nutrition;

  /// Recomendaciones de ejercicio.
  final List<String> exercise;

  /// Recomendaciones de medicación.
  final List<String> medication;

  /// Recomendaciones de monitoreo.
  final List<String> monitoring;

  /// Recomendaciones de estilo de vida.
  final List<String> lifestyle;

  /// Crea instancia desde JSON.
  factory PlanRecommendations.fromJson(Map<String, dynamic> json) {
    return PlanRecommendations(
      nutrition: List<String>.from(json['nutrition'] ?? []),
      exercise: List<String>.from(json['exercise'] ?? []),
      medication: List<String>.from(json['medication'] ?? []),
      monitoring: List<String>.from(json['monitoring'] ?? []),
      lifestyle: List<String>.from(json['lifestyle'] ?? []),
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() {
    return {
      'nutrition': nutrition,
      'exercise': exercise,
      'medication': medication,
      'monitoring': monitoring,
      'lifestyle': lifestyle,
    };
  }
}