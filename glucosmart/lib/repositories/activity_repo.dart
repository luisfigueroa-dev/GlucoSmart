import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity.dart';

/// Repositorio para manejar operaciones CRUD de actividad física.
/// Proporciona métodos para interactuar con la tabla 'activity' en Supabase.
/// Maneja errores y conversiones de datos de manera centralizada.
class ActivityRepository {
  /// Instancia del cliente de Supabase.
  final SupabaseClient _supabase;

  /// Constructor que recibe el cliente de Supabase.
  ActivityRepository(this._supabase);

  /// Obtiene todas las entradas de actividad del usuario actual.
  /// Ordena por timestamp descendente (más recientes primero).
  /// Lanza excepción si hay error en la consulta.
  Future<List<Activity>> getActivities(String userId) async {
    try {
      final response = await _supabase
          .from('activity')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return response.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener actividades: $e');
    }
  }

  /// Obtiene actividades de los últimos 7 días para el usuario.
  /// Útil para dashboards y análisis recientes.
  Future<List<Activity>> getLast7DaysActivities(String userId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    try {
      final response = await _supabase
          .from('activity')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', sevenDaysAgo.toIso8601String())
          .order('timestamp', ascending: false);

      return response.map((json) => Activity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener actividades de los últimos 7 días: $e');
    }
  }

  /// Agrega una nueva entrada de actividad.
  /// Retorna la actividad creada con ID asignado por BD.
  Future<Activity> addActivity(Activity activity) async {
    try {
      final response = await _supabase
          .from('activity')
          .insert(activity.toJsonForInsert())
          .select()
          .single();

      return Activity.fromJson(response);
    } catch (e) {
      throw Exception('Error al agregar actividad: $e');
    }
  }

  /// Actualiza una entrada de actividad existente.
  /// Retorna la actividad actualizada.
  Future<Activity> updateActivity(Activity activity) async {
    try {
      final response = await _supabase
          .from('activity')
          .update(activity.toJson())
          .eq('id', activity.id)
          .eq('user_id', activity.userId)
          .select()
          .single();

      return Activity.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar actividad: $e');
    }
  }

  /// Elimina una entrada de actividad por ID.
  /// Solo permite eliminación si pertenece al usuario actual (por RLS).
  Future<void> deleteActivity(String activityId, String userId) async {
    try {
      await _supabase
          .from('activity')
          .delete()
          .eq('id', activityId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error al eliminar actividad: $e');
    }
  }

  /// Obtiene el total de pasos en un rango de fechas.
  /// Útil para estadísticas y reportes.
  Future<int> getTotalStepsInRange(String userId, DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('activity')
          .select('steps')
          .eq('user_id', userId)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String());

      final stepsList = response.map((json) => json['steps'] as int).toList();
      return stepsList.isEmpty ? 0 : stepsList.reduce((a, b) => a + b);
    } catch (e) {
      throw Exception('Error al obtener total de pasos: $e');
    }
  }

  /// Obtiene el total de calorías quemadas en un rango de fechas.
  Future<double> getTotalCaloriesInRange(String userId, DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('activity')
          .select('calories_burned')
          .eq('user_id', userId)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String());

      final caloriesList = response.map((json) => (json['calories_burned'] as num).toDouble()).toList();
      return caloriesList.isEmpty ? 0.0 : caloriesList.reduce((a, b) => a + b);
    } catch (e) {
      throw Exception('Error al obtener total de calorías: $e');
    }
  }
}