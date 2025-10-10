/// Modelo de datos para representar una medición de glucosa.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y auxiliares para validaciones comunes.
class Glucose {
  /// Constructor constante para crear instancias inmutables.
  const Glucose({
    required this.id,
    required this.userId,
    required this.value,
    required this.timestamp,
    this.notes,
  });

  /// Identificador único de la medición (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario de la medición.
  final String userId;

  /// Valor de la medición de glucosa en mg/dL.
  final double value;

  /// Fecha y hora de la medición.
  final DateTime timestamp;

  /// Notas opcionales sobre la medición (ej. contexto alimenticio).
  final String? notes;

  /// Crea una instancia de Glucose desde un mapa JSON.
  /// Maneja la conversión de tipos y parsing de fechas.
  factory Glucose.fromJson(Map<String, dynamic> json) {
    return Glucose(
      id: json['id'] as String,
      userId: json['user_id'] as String,  // Supabase usa snake_case por defecto
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  /// Formatea la fecha en ISO 8601 para compatibilidad.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  /// Convierte la instancia a un mapa JSON para inserción en Supabase.
  /// Excluye el ID ya que se genera automáticamente en la base de datos.
  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  /// Verifica si el valor de glucosa está en rango alto (>140 mg/dL).
  /// Útil para alertas o categorización de mediciones.
  bool isHigh() => value > 140.0;

  /// Verifica si el valor de glucosa está en rango bajo (<70 mg/dL).
  /// Importante para detectar hipoglucemia.
  bool isLow() => value < 70.0;

  /// Verifica si el valor está en rango normal (70-140 mg/dL).
  /// Método auxiliar para clasificar mediciones.
  bool isNormal() => value >= 70.0 && value <= 140.0;

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  /// Facilita la actualización inmutable de datos.
  Glucose copyWith({
    String? id,
    String? userId,
    double? value,
    DateTime? timestamp,
    String? notes,
  }) {
    return Glucose(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}