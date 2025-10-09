/// Modelo de datos para el sistema de gamificación.
/// Incluye logros, puntos, niveles y recompensas.
/// Compatible con Supabase, con métodos para cálculo automático de progreso.
class Achievement {
  /// Constructor constante para crear instancias inmutables.
  const Achievement({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.iconName,
    required this.points,
    required this.targetValue,
    required this.currentValue,
    required this.isCompleted,
    required this.isClaimed,
    required this.dateEarned,
    required this.category,
  });

  /// Identificador único del logro (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario.
  final String userId;

  /// Tipo de logro (glucosa, actividad, educación, etc.).
  final AchievementType type;

  /// Título descriptivo del logro.
  final String title;

  /// Descripción detallada.
  final String description;

  /// Nombre del ícono (para Flutter Icons).
  final String iconName;

  /// Puntos otorgados al completar.
  final int points;

  /// Valor objetivo para completar.
  final int targetValue;

  /// Valor actual de progreso.
  final int currentValue;

  /// Indica si está completado.
  final bool isCompleted;

  /// Indica si la recompensa fue reclamada.
  final bool isClaimed;

  /// Fecha de obtención (null si no completado).
  final DateTime? dateEarned;

  /// Categoría del logro.
  final AchievementCategory category;

  /// Crea instancia desde JSON.
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => AchievementType.glucose,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String,
      points: json['points'] as int,
      targetValue: json['target_value'] as int,
      currentValue: json['current_value'] as int,
      isCompleted: json['is_completed'] as bool,
      isClaimed: json['is_claimed'] as bool,
      dateEarned: json['date_earned'] != null ? DateTime.parse(json['date_earned'] as String) : null,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'] as String,
        orElse: () => AchievementCategory.health,
      ),
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'points': points,
      'target_value': targetValue,
      'current_value': currentValue,
      'is_completed': isCompleted,
      'is_claimed': isClaimed,
      'date_earned': dateEarned?.toIso8601String(),
      'category': category.name,
    };
  }

  /// Calcula el progreso como porcentaje (0.0 a 1.0).
  double get progressPercentage => (currentValue / targetValue).clamp(0.0, 1.0);

  /// Crea copia con campos modificados.
  Achievement copyWith({
    String? id,
    String? userId,
    AchievementType? type,
    String? title,
    String? description,
    String? iconName,
    int? points,
    int? targetValue,
    int? currentValue,
    bool? isCompleted,
    bool? isClaimed,
    DateTime? dateEarned,
    AchievementCategory? category,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      points: points ?? this.points,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      dateEarned: dateEarned ?? this.dateEarned,
      category: category ?? this.category,
    );
  }
}

/// Tipos de logros disponibles.
enum AchievementType {
  /// Logros relacionados con mediciones de glucosa.
  glucose,

  /// Logros de actividad física.
  activity,

  /// Logros de registro de alimentos.
  nutrition,

  /// Logros de educación y aprendizaje.
  education,

  /// Logros de adherencia al tratamiento.
  adherence,

  /// Logros sociales (compartir, comunidad).
  social,

  /// Logros especiales o milestones.
  milestone,
}

/// Categorías de logros.
enum AchievementCategory {
  /// Salud y bienestar.
  health,

  /// Conocimiento y educación.
  knowledge,

  /// Comunidad y social.
  community,

  /// Logros especiales.
  special,
}

/// Modelo para estadísticas de usuario en gamificación.
class UserGamificationStats {
  const UserGamificationStats({
    required this.userId,
    required this.totalPoints,
    required this.level,
    required this.currentLevelPoints,
    required this.pointsToNextLevel,
    required this.totalAchievements,
    required this.completedAchievements,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivityDate,
  });

  /// ID del usuario.
  final String userId;

  /// Puntos totales acumulados.
  final int totalPoints;

  /// Nivel actual del usuario.
  final int level;

  /// Puntos en el nivel actual.
  final int currentLevelPoints;

  /// Puntos necesarios para el siguiente nivel.
  final int pointsToNextLevel;

  /// Total de logros disponibles.
  final int totalAchievements;

  /// Logros completados.
  final int completedAchievements;

  /// Racha actual de días activos.
  final int currentStreak;

  /// Racha más larga de días activos.
  final int longestStreak;

  /// Última fecha de actividad.
  final DateTime lastActivityDate;

  /// Crea instancia desde JSON.
  factory UserGamificationStats.fromJson(Map<String, dynamic> json) {
    return UserGamificationStats(
      userId: json['user_id'] as String,
      totalPoints: json['total_points'] as int,
      level: json['level'] as int,
      currentLevelPoints: json['current_level_points'] as int,
      pointsToNextLevel: json['points_to_next_level'] as int,
      totalAchievements: json['total_achievements'] as int,
      completedAchievements: json['completed_achievements'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      lastActivityDate: DateTime.parse(json['last_activity_date'] as String),
    );
  }

  /// Convierte a JSON.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'level': level,
      'current_level_points': currentLevelPoints,
      'points_to_next_level': pointsToNextLevel,
      'total_achievements': totalAchievements,
      'completed_achievements': completedAchievements,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate.toIso8601String(),
    };
  }

  /// Calcula el progreso del nivel actual como porcentaje.
  double get levelProgress => (currentLevelPoints / (currentLevelPoints + pointsToNextLevel)).clamp(0.0, 1.0);

  /// Verifica si el usuario está en racha (actividad hoy).
  bool get isInStreak => lastActivityDate.day == DateTime.now().day;
}