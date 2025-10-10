import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_parameter.dart';

/// Repositorio para manejar operaciones CRUD de parámetros de salud.
/// Proporciona métodos para interactuar con la tabla 'health_parameters' en Supabase.
/// Maneja errores y conversiones de datos de manera centralizada.
class HealthParameterRepository {
  /// Instancia del cliente de Supabase.
  final SupabaseClient _supabase;

  /// Constructor que recibe el cliente de Supabase.
  HealthParameterRepository(this._supabase);

  /// Obtiene todos los parámetros de salud del usuario actual.
  /// Ordena por timestamp descendente (más recientes primero).
  Future<List<HealthParameter>> getHealthParameters(String userId) async {
    try {
      final response = await _supabase
          .from('health_parameters')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return response.map((json) => HealthParameter.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener parámetros de salud: $e');
    }
  }

  /// Obtiene parámetros de salud de los últimos 30 días para el usuario.
  Future<List<HealthParameter>> getLast30DaysParameters(String userId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    try {
      final response = await _supabase
          .from('health_parameters')
          .select()
          .eq('user_id', userId)
          .gte('timestamp', thirtyDaysAgo.toIso8601String())
          .order('timestamp', ascending: false);

      return response.map((json) => HealthParameter.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener parámetros de los últimos 30 días: $e');
    }
  }

  /// Obtiene parámetros de un tipo específico.
  Future<List<HealthParameter>> getParametersByType(String userId, HealthParameterType type) async {
    try {
      final response = await _supabase
          .from('health_parameters')
          .select()
          .eq('user_id', userId)
          .eq('type', type.name)
          .order('timestamp', ascending: false);

      return response.map((json) => HealthParameter.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener parámetros por tipo: $e');
    }
  }

  /// Agrega un nuevo parámetro de salud.
  Future<HealthParameter> addHealthParameter(HealthParameter parameter) async {
    try {
      final response = await _supabase
          .from('health_parameters')
          .insert(parameter.toJsonForInsert())
          .select()
          .single();

      return HealthParameter.fromJson(response);
    } catch (e) {
      throw Exception('Error al agregar parámetro de salud: $e');
    }
  }

  /// Actualiza un parámetro de salud existente.
  Future<HealthParameter> updateHealthParameter(HealthParameter parameter) async {
    try {
      final response = await _supabase
          .from('health_parameters')
          .update(parameter.toJson())
          .eq('id', parameter.id)
          .eq('user_id', parameter.userId)
          .select()
          .single();

      return HealthParameter.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar parámetro de salud: $e');
    }
  }

  /// Elimina un parámetro de salud por ID.
  Future<void> deleteHealthParameter(String parameterId, String userId) async {
    try {
      await _supabase
          .from('health_parameters')
          .delete()
          .eq('id', parameterId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error al eliminar parámetro de salud: $e');
    }
  }

  /// Obtiene el último valor de un tipo específico.
  Future<HealthParameter?> getLatestParameter(String userId, HealthParameterType type) async {
    try {
      final response = await _supabase
          .from('health_parameters')
          .select()
          .eq('user_id', userId)
          .eq('type', type.name)
          .order('timestamp', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return HealthParameter.fromJson(response.first);
    } catch (e) {
      throw Exception('Error al obtener último parámetro: $e');
    }
  }

  /// Obtiene el promedio de valores en un rango de fechas para un tipo.
  Future<double?> getAverageInRange(String userId, HealthParameterType type, DateTime start, DateTime end) async {
    try {
      final response = await _supabase
          .from('health_parameters')
          .select('value')
          .eq('user_id', userId)
          .eq('type', type.name)
          .gte('timestamp', start.toIso8601String())
          .lte('timestamp', end.toIso8601String());

      if (response.isEmpty) return null;
      final values = response.map((json) => (json['value'] as num).toDouble()).toList();
      return values.reduce((a, b) => a + b) / values.length;
    } catch (e) {
      throw Exception('Error al obtener promedio: $e');
    }
  }
}