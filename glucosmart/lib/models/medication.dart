/// Modelo de datos para representar una dosis de medicamento.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y auxiliares para validaciones comunes.
enum MedicationType {
  /// Insulina administrada antes de comidas para cubrir carbohidratos.
  bolus,

  /// Insulina de acción prolongada para mantener niveles basales.
  basal,

  /// Dosis de corrección para ajustar niveles altos de glucosa.
  correction,

  /// Otros tipos de medicamentos no categorizados.
  other,
}

/// Modelo de datos para representar una dosis de medicamento.
class Medication {
  /// Constructor constante para crear instancias inmutables.
  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.unit,
    required this.timestamp,
    required this.type,
  });

  /// Identificador único de la dosis (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario de la dosis.
  final String userId;

  /// Nombre del medicamento (ej. "Insulina rápida").
  final String name;

  /// Cantidad de dosis administrada.
  final double dose;

  /// Unidad de medida de la dosis (ej. "unidades", "mg").
  final String unit;

  /// Fecha y hora de la administración.
  final DateTime timestamp;

  /// Tipo de medicamento según la clasificación.
  final MedicationType type;

  /// Crea una instancia de Medication desde un mapa JSON.
  /// Maneja la conversión de tipos, parsing de fechas y enums.
  /// Lógica compleja: el enum se parsea desde string, asumiendo valores en minúsculas.
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      userId: json['user_id'] as String,  // Supabase usa snake_case por defecto
      name: json['name'] as String,
      dose: (json['dose'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MedicationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => MedicationType.other,
      ),
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  /// Formatea la fecha en ISO 8601 y el enum como string en minúsculas.
  /// Lógica compleja: asegura compatibilidad con PostgreSQL enum types.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'dose': dose,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,  // Convierte enum a string
    };
  }

  /// Convierte la instancia a un mapa JSON para inserción en Supabase.
  /// Excluye el ID ya que se genera automáticamente en la base de datos.
  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'name': name,
      'dose': dose,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,  // Convierte enum a string
    };
  }

  /// Verifica si el medicamento es de tipo bolus.
  /// Útil para cálculos relacionados con comidas.
  bool isBolus() => type == MedicationType.bolus;

  /// Verifica si el medicamento es de tipo basal.
  /// Importante para dosis continuas.
  bool isBasal() => type == MedicationType.basal;

  /// Verifica si el medicamento es de tipo corrección.
  /// Método auxiliar para ajustes de glucosa.
  bool isCorrection() => type == MedicationType.correction;

  /// Retorna la dosis formateada como string (ej. "5.0 unidades").
  /// Facilita la presentación en UI.
  String formattedDose() => '$dose $unit';

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  /// Facilita la actualización inmutable de datos.
  Medication copyWith({
    String? id,
    String? userId,
    String? name,
    double? dose,
    String? unit,
    DateTime? timestamp,
    MedicationType? type,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}