import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_stats.dart';

/// Repositorio para gestionar estadísticas de usuario en Supabase.
/// Maneja operaciones CRUD para UserStats con manejo de errores y logging.
class UserStatsRepository {
  /// Instancia del cliente Supabase.
  final SupabaseClient _supabase;

  /// Constructor que recibe el cliente Supabase.
  UserStatsRepository(this._supabase);

  /// Obtiene las estadísticas del usuario actual.
  /// Si no existen, crea unas por defecto.
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .single();

      return UserStats.fromJson(response);
    } catch (e) {
      // Si no existe, devolver null para crear nuevas
      if (e.toString().contains('No rows found')) {
        return null;
      }
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Crea estadísticas iniciales para un usuario.
  Future<UserStats> createUserStats(String userId) async {
    try {
      final newStats = UserStats(
        id: '',
        userId: userId,
        points: 0,
        level: 1,
        streakDays: 0,
        lastActivity: DateTime.now(),
        achievements: [],
      );

      final response = await _supabase
          .from('user_stats')
          .insert(newStats.toJson())
          .select()
          .single();

      return UserStats.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear estadísticas: $e');
    }
  }

  /// Actualiza las estadísticas del usuario.
  Future<UserStats> updateUserStats(UserStats stats) async {
    try {
      final response = await _supabase
          .from('user_stats')
          .update(stats.toJson())
          .eq('id', stats.id)
          .select()
          .single();

      return UserStats.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar estadísticas: $e');
    }
  }

  /// Agrega puntos al usuario y actualiza nivel si es necesario.
  Future<UserStats> addPoints(String userId, int pointsToAdd) async {
    try {
      var stats = await getUserStats(userId);
      if (stats == null) {
        stats = await createUserStats(userId);
      }

      final newPoints = stats.points + pointsToAdd;
      final newLevel = UserStats.calculateLevel(newPoints);
      final newAchievements = List<String>.from(stats.achievements);

      // Verificar si desbloqueó nuevo nivel
      if (newLevel > stats.level) {
        newAchievements.add('Nivel $newLevel alcanzado');
      }

      final updatedStats = stats.copyWith(
        points: newPoints,
        level: newLevel,
        lastActivity: DateTime.now(),
        achievements: newAchievements,
      );

      return await updateUserStats(updatedStats);
    } catch (e) {
      throw Exception('Error al agregar puntos: $e');
    }
  }
}