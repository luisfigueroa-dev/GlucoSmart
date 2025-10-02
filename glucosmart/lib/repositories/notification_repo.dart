import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

/// Repositorio para manejar operaciones de base de datos relacionadas con notificaciones.
/// Utiliza únicamente el cliente Supabase para todas las operaciones.
/// Incluye manejo de errores con try-catch y comentarios en español.
///
/// Configuración recomendada en Supabase:
/// - Tabla: notifications
/// - Columnas: id (uuid, primary key), user_id (uuid), title (text), body (text), scheduled_time (timestamptz), type (text), is_active (bool)
/// - Índices: CREATE INDEX idx_notifications_user_active_scheduled ON notifications (user_id, is_active, scheduled_time DESC);
/// - RLS: ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
///   Política: CREATE POLICY "Users can only access their own notifications" ON notifications
///     FOR ALL USING (auth.uid() = user_id);
class NotificationRepository {
  /// Constructor constante que recibe el cliente de Supabase.
  const NotificationRepository(this._supabaseClient);

  /// Cliente de Supabase para realizar operaciones de base de datos.
  final SupabaseClient _supabaseClient;

  /// Inserta una nueva notificación en la base de datos.
  /// Maneja errores de conexión y validación.
  ///
  /// [notification] La notificación a insertar.
  /// Retorna el ID de la notificación insertada o lanza una excepción en caso de error.
  Future<String> insert(Notification notification) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .insert(notification.toJson())
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al insertar notificación: $e');
    }
  }

  /// Obtiene las notificaciones activas para un usuario específico.
  /// Ordena los resultados por fecha programada descendente.
  /// Maneja errores de consulta y parsing de datos.
  ///
  /// [userId] El ID del usuario cuyas notificaciones se desean obtener.
  /// Retorna una lista de notificaciones activas o lanza una excepción en caso de error.
  Future<List<Notification>> getActive(String userId) async {
    try {
      final response = await _supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('scheduled_time', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Notification.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener notificaciones activas: $e');
    }
  }

  /// Actualiza una notificación existente en la base de datos.
  /// Maneja errores de conexión y validación.
  ///
  /// [id] El ID de la notificación a actualizar.
  /// [updates] Un mapa con los campos a actualizar.
  /// Retorna void o lanza una excepción en caso de error.
  Future<void> update(String id, Map<String, dynamic> updates) async {
    try {
      await _supabaseClient.from('notifications').update(updates).eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar notificación: $e');
    }
  }

  /// Elimina una notificación de la base de datos por su ID.
  /// Maneja errores de conexión y validación.
  ///
  /// [id] El ID de la notificación a eliminar.
  /// Retorna void o lanza una excepción en caso de error.
  Future<void> delete(String id) async {
    try {
      await _supabaseClient.from('notifications').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }
}
