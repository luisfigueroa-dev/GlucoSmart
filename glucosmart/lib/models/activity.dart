/// Modelo de datos para representar una entrada de actividad física.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y auxiliares para validaciones comunes.
class Activity {
  /// Constructor constante para crear instancias inmutables.
  const Activity({
    required this.id,
    required this.userId,
    required this.steps,
    required this.caloriesBurned,
    required this.timestamp,
    this.durationMinutes,
    this.activityType,
  });

  /// Identificador único de la entrada (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario de la entrada.
  final String userId;

  /// Número de pasos dados.
  final int steps;

  /// Calorías quemadas durante la actividad.
  final double caloriesBurned;

  /// Fecha y hora de la entrada.
  final DateTime timestamp;

  /// Duración de la actividad en minutos (opcional).
  final int? durationMinutes;

  /// Tipo de actividad (ej. caminar, correr, ciclismo).
  final String? activityType;

  /// Crea una instancia de Activity desde un mapa JSON.
  /// Maneja la conversión de tipos y parsing de fechas.
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      steps: json['steps'] as int,
      caloriesBurned: (json['calories_burned'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      activityType: json['activity_type'] as String?,
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  /// Formatea la fecha en ISO 8601 para compatibilidad.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'steps': steps,
      'calories_burned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
      'duration_minutes': durationMinutes,
      'activity_type': activityType,
    };
  }

  /// Convierte la instancia a un mapa JSON para inserción en Supabase.
  /// Excluye el ID ya que se genera automáticamente en la base de datos.
  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'steps': steps,
      'calories_burned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
      'duration_minutes': durationMinutes,
      'activity_type': activityType,
    };
  }

  /// Verifica si la actividad es considerada alta (>10000 pasos).
  /// Útil para alertas o categorización.
  bool isHighActivity() => steps > 10000;

  /// Verifica si la actividad es baja (<5000 pasos).
  /// Método auxiliar para clasificar entradas.
  bool isLowActivity() => steps < 5000;

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  /// Facilita la actualización inmutable de datos.
  Activity copyWith({
    String? id,
    String? userId,
    int? steps,
    double? caloriesBurned,
    DateTime? timestamp,
    int? durationMinutes,
    String? activityType,
  }) {
    return Activity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      steps: steps ?? this.steps,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      timestamp: timestamp ?? this.timestamp,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      activityType: activityType ?? this.activityType,
    );
  }
}