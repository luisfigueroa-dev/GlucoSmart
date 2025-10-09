/// Modelo de datos para representar parámetros de salud adicionales.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y auxiliares para validaciones comunes.
enum HealthParameterType {
  /// Peso corporal en kilogramos.
  weight,

  /// Nivel de HbA1c en porcentaje.
  hba1c,

  /// Presión arterial sistólica/diastólica en mmHg.
  bloodPressure,

  /// Horas de sueño.
  sleepHours,
}

/// Modelo de datos para representar un parámetro de salud.
class HealthParameter {
  /// Constructor constante para crear instancias inmutables.
  const HealthParameter({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    this.unit,
    required this.timestamp,
    this.notes,
  });

  /// Identificador único del parámetro (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario del parámetro.
  final String userId;

  /// Tipo del parámetro de salud.
  final HealthParameterType type;

  /// Valor numérico del parámetro.
  final double value;

  /// Unidad de medida (opcional, puede inferirse del tipo).
  final String? unit;

  /// Fecha y hora del registro.
  final DateTime timestamp;

  /// Notas opcionales.
  final String? notes;

  /// Crea una instancia de HealthParameter desde un mapa JSON.
  factory HealthParameter.fromJson(Map<String, dynamic> json) {
    return HealthParameter(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: HealthParameterType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => HealthParameterType.weight,
      ),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  /// Retorna la unidad por defecto basada en el tipo.
  String get defaultUnit {
    switch (type) {
      case HealthParameterType.weight:
        return 'kg';
      case HealthParameterType.hba1c:
        return '%';
      case HealthParameterType.bloodPressure:
        return 'mmHg';
      case HealthParameterType.sleepHours:
        return 'horas';
    }
  }

  /// Verifica si el valor está en rango normal (aproximado).
  bool isNormal() {
    switch (type) {
      case HealthParameterType.weight:
        return value > 30 && value < 200; // Rango amplio
      case HealthParameterType.hba1c:
        return value >= 4.0 && value <= 6.0; // Normal <5.7, pero amplio
      case HealthParameterType.bloodPressure:
        return value >= 90 && value <= 140; // Sistólica aproximada
      case HealthParameterType.sleepHours:
        return value >= 6 && value <= 10;
    }
  }

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  HealthParameter copyWith({
    String? id,
    String? userId,
    HealthParameterType? type,
    double? value,
    String? unit,
    DateTime? timestamp,
    String? notes,
  }) {
    return HealthParameter(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}