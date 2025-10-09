/// Modelo de datos para estadísticas y gamificación del usuario.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y cálculo de niveles.
class UserStats {
  /// Constructor constante para crear instancias inmutables.
  const UserStats({
    required this.id,
    required this.userId,
    required this.points,
    required this.level,
    required this.streakDays,
    required this.lastActivity,
    this.achievements = const [],
  });

  /// Identificador único de las estadísticas (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario de las estadísticas.
  final String userId;

  /// Puntos totales acumulados.
  final int points;

  /// Nivel actual basado en puntos.
  final int level;

  /// Días consecutivos de actividad.
  final int streakDays;

  /// Fecha de la última actividad.
  final DateTime lastActivity;

  /// Lista de logros desbloqueados.
  final List<String> achievements;

  /// Crea una instancia de UserStats desde un mapa JSON.
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      points: json['points'] as int,
      level: json['level'] as int,
      streakDays: json['streak_days'] as int,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'level': level,
      'streak_days': streakDays,
      'last_activity': lastActivity.toIso8601String(),
      'achievements': achievements,
    };
  }

  /// Calcula el nivel basado en puntos (cada 100 puntos = 1 nivel).
  static int calculateLevel(int points) => (points / 100).floor() + 1;

  /// Verifica si se desbloqueó un nuevo logro.
  bool hasNewAchievement(int newPoints) {
    final newLevel = calculateLevel(newPoints);
    return newLevel > level;
  }

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  UserStats copyWith({
    String? id,
    String? userId,
    int? points,
    int? level,
    int? streakDays,
    DateTime? lastActivity,
    List<String>? achievements,
  }) {
    return UserStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      lastActivity: lastActivity ?? this.lastActivity,
      achievements: achievements ?? this.achievements,
    );
  }
}