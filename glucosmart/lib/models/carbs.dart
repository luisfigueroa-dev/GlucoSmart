/// Modelo de datos para representar una entrada de carbohidratos.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y auxiliares para validaciones comunes.
class Carbs {
  /// Constructor constante para crear instancias inmutables.
  const Carbs({
    required this.id,
    required this.userId,
    required this.grams,
    required this.timestamp,
    this.food,
  });

  /// Identificador único de la entrada (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario de la entrada.
  final String userId;

  /// Cantidad de gramos de carbohidratos consumidos.
  final int grams;

  /// Fecha y hora de la entrada.
  final DateTime timestamp;

  /// Nombre del alimento opcional (ej. "pan integral").
  final String? food;

  /// Crea una instancia de Carbs desde un mapa JSON.
  /// Maneja la conversión de tipos y parsing de fechas.
  factory Carbs.fromJson(Map<String, dynamic> json) {
    return Carbs(
      id: json['id'] as String,
      userId: json['user_id'] as String,  // Supabase usa snake_case por defecto
      grams: json['grams'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      food: json['food'] as String?,
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  /// Formatea la fecha en ISO 8601 para compatibilidad.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'grams': grams,
      'timestamp': timestamp.toIso8601String(),
      'food': food,
    };
  }

  /// Convierte la instancia a un mapa JSON para inserción en Supabase.
  /// Excluye el ID ya que se genera automáticamente en la base de datos.
  Map<String, dynamic> toJsonForInsert() {
    return {
      'user_id': userId,
      'grams': grams,
      'timestamp': timestamp.toIso8601String(),
      'food': food,
    };
  }

  /// Verifica si la cantidad de carbohidratos es considerada alta (>50g).
  /// Útil para alertas o categorización de entradas.
  bool isHigh() => grams > 50;

  /// Verifica si la cantidad de carbohidratos es baja (<=20g).
  /// Método auxiliar para clasificar entradas.
  bool isLow() => grams <= 20;

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  /// Facilita la actualización inmutable de datos.
  Carbs copyWith({
    String? id,
    String? userId,
    int? grams,
    DateTime? timestamp,
    String? food,
  }) {
    return Carbs(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      grams: grams ?? this.grams,
      timestamp: timestamp ?? this.timestamp,
      food: food ?? this.food,
    );
  }
}