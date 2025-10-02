/// Modelo de datos para representar una notificación en la aplicación.
/// Compatible con Supabase, utilizando tipos de datos estándar de PostgreSQL.
/// Incluye métodos para serialización JSON y auxiliares para validaciones comunes.
class Notification {
  /// Constructor constante para crear instancias inmutables.
  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
    required this.isActive,
  });

  /// Identificador único de la notificación (UUID en Supabase).
  final String id;

  /// Identificador del usuario propietario de la notificación.
  final String userId;

  /// Título de la notificación.
  final String title;

  /// Cuerpo o mensaje de la notificación.
  final String body;

  /// Fecha y hora programada para la notificación.
  final DateTime scheduledTime;

  /// Tipo de notificación (glucosa, medicamento, recordatorio).
  final NotificationType type;

  /// Indica si la notificación está activa y debe ser enviada.
  final bool isActive;

  /// Crea una instancia de Notification desde un mapa JSON.
  /// Maneja la conversión de tipos, parsing de fechas y enums.
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['user_id'] as String,  // Supabase usa snake_case por defecto
      title: json['title'] as String,
      body: json['body'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => NotificationType.reminder,  // Valor por defecto si no coincide
      ),
      isActive: json['is_active'] as bool,
    );
  }

  /// Convierte la instancia a un mapa JSON para envío a Supabase.
  /// Formatea la fecha en ISO 8601 y el enum como string para compatibilidad.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.toIso8601String(),
      'type': type.name,
      'is_active': isActive,
    };
  }

  /// Verifica si la notificación está programada para el futuro.
  /// Útil para determinar si debe ser procesada o ignorada.
  bool isScheduledForFuture() => scheduledTime.isAfter(DateTime.now());

  /// Verifica si la notificación está activa y programada para el futuro.
  /// Método auxiliar para filtrar notificaciones pendientes.
  bool isActiveAndScheduled() => isActive && isScheduledForFuture();

  /// Crea una copia de la instancia con campos modificados opcionalmente.
  /// Facilita la actualización inmutable de datos.
  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    DateTime? scheduledTime,
    NotificationType? type,
    bool? isActive,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Enum para los tipos de notificación disponibles.
/// Facilita la categorización y manejo de diferentes tipos de alertas.
enum NotificationType {
  /// Notificación relacionada con mediciones de glucosa.
  glucose,

  /// Notificación para recordatorios de medicamentos.
  medication,

  /// Notificación general de recordatorio.
  reminder,
}