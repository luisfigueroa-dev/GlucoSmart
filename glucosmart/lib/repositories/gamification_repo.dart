import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gamification.dart';

/// Repositorio para gestionar gamificación en Supabase.
/// Maneja logros, estadísticas y progreso del usuario.
class GamificationRepository {
  /// Instancia del cliente Supabase.
  final SupabaseClient _supabase;

  /// Constructor que recibe el cliente Supabase.
  GamificationRepository(this._supabase);

  /// Obtiene todos los logros del usuario.
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener logros del usuario: $e');
    }
  }

  /// Obtiene logros completados del usuario.
  Future<List<Achievement>> getCompletedAchievements(String userId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('date_earned', ascending: false);

      return response.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener logros completados: $e');
    }
  }

  /// Obtiene estadísticas de gamificación del usuario.
  Future<UserGamificationStats?> getUserStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_gamification_stats')
          .select()
          .eq('user_id', userId)
          .single();

      return UserGamificationStats.fromJson(response);
    } catch (e) {
      // Si no existe, devolver null (se creará automáticamente por trigger)
      return null;
    }
  }

  /// Inicializa logros por defecto para un nuevo usuario.
  Future<void> initializeDefaultAchievements(String userId) async {
    try {
      final defaultAchievements = _getDefaultAchievements(userId);

      for (final achievement in defaultAchievements) {
        await _supabase
            .from('achievements')
            .insert(achievement.toJson());
      }
    } catch (e) {
      throw Exception('Error al inicializar logros por defecto: $e');
    }
  }

  /// Actualiza el progreso de un logro.
  Future<Achievement> updateAchievementProgress(
    String achievementId,
    int newValue,
    String userId,
  ) async {
    try {
      final targetValue = await _getAchievementTargetValue(achievementId, userId);
      final isCompleted = newValue >= targetValue;

      final updateData = {
        'current_value': newValue,
        'is_completed': isCompleted,
        'date_earned': isCompleted ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('achievements')
          .update(updateData)
          .eq('id', achievementId)
          .eq('user_id', userId)
          .select()
          .single();

      return Achievement.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar progreso del logro: $e');
    }
  }

  /// Reclama recompensa de un logro completado.
  Future<void> claimAchievementReward(String achievementId, String userId) async {
    try {
      await _supabase
          .from('achievements')
          .update({'is_claimed': true})
          .eq('id', achievementId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error al reclamar recompensa: $e');
    }
  }

  /// Actualiza estadísticas del usuario.
  Future<UserGamificationStats> updateUserStats(
    String userId,
    {
      int? pointsToAdd,
      int? streakUpdate,
    }
  ) async {
    try {
      // Obtener stats actuales
      final currentStats = await getUserStats(userId);
      if (currentStats == null) {
        throw Exception('Estadísticas de usuario no encontradas');
      }

      int newTotalPoints = currentStats.totalPoints;
      int newLevel = currentStats.level;
      int newCurrentLevelPoints = currentStats.currentLevelPoints;
      int newPointsToNextLevel = currentStats.pointsToNextLevel;
      int newCurrentStreak = currentStats.currentStreak;
      int newLongestStreak = currentStats.longestStreak;

      // Actualizar puntos si se especifica
      if (pointsToAdd != null && pointsToAdd > 0) {
        newTotalPoints += pointsToAdd;
        newCurrentLevelPoints += pointsToAdd;

        // Verificar si sube de nivel
        while (newCurrentLevelPoints >= newPointsToNextLevel) {
          newCurrentLevelPoints -= newPointsToNextLevel;
          newLevel++;
          newPointsToNextLevel = _calculatePointsForLevel(newLevel);
        }
      }

      // Actualizar racha si se especifica
      if (streakUpdate != null) {
        newCurrentStreak = streakUpdate;
        if (newCurrentStreak > newLongestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      }

      final updateData = {
        'total_points': newTotalPoints,
        'level': newLevel,
        'current_level_points': newCurrentLevelPoints,
        'points_to_next_level': newPointsToNextLevel,
        'current_streak': newCurrentStreak,
        'longest_streak': newLongestStreak,
        'last_activity_date': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_gamification_stats')
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return UserGamificationStats.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar estadísticas: $e');
    }
  }

  /// Obtiene el valor objetivo de un logro.
  Future<int> _getAchievementTargetValue(String achievementId, String userId) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('target_value')
          .eq('id', achievementId)
          .eq('user_id', userId)
          .single();

      return response['target_value'] as int;
    } catch (e) {
      throw Exception('Error al obtener valor objetivo: $e');
    }
  }

  /// Calcula puntos necesarios para un nivel específico.
  int _calculatePointsForLevel(int level) {
    // Fórmula: puntos base + (nivel * multiplicador)
    return 100 + (level * 50);
  }

  /// Genera logros por defecto para nuevos usuarios.
  List<Achievement> _getDefaultAchievements(String userId) {
    return [
      // Logros de glucosa
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.glucose,
        title: 'Primer Paso',
        description: 'Registra tu primera medición de glucosa',
        iconName: 'bloodtype',
        points: 10,
        targetValue: 1,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.health,
      ),
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.glucose,
        title: 'Monitor Constante',
        description: 'Registra glucosa durante 7 días consecutivos',
        iconName: 'timeline',
        points: 50,
        targetValue: 7,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.health,
      ),

      // Logros de actividad
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.activity,
        title: 'Paseo Saludable',
        description: 'Registra 10000 pasos en un día',
        iconName: 'directions_walk',
        points: 25,
        targetValue: 10000,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.health,
      ),

      // Logros de nutrición
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.nutrition,
        title: 'Conteo de Carbohidratos',
        description: 'Registra 10 ingestas de carbohidratos',
        iconName: 'restaurant',
        points: 20,
        targetValue: 10,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.health,
      ),

      // Logros de educación
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.education,
        title: 'Aprendiz Constante',
        description: 'Completa 5 sesiones de educación',
        iconName: 'school',
        points: 30,
        targetValue: 5,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.knowledge,
      ),

      // Logros de adherencia
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.adherence,
        title: 'Tratamiento Consistente',
        description: 'Registra medicamentos durante 14 días',
        iconName: 'medication',
        points: 40,
        targetValue: 14,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.health,
      ),

      // Logros sociales
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.social,
        title: 'Comparte tu Progreso',
        description: 'Comparte un informe con tu médico',
        iconName: 'share',
        points: 15,
        targetValue: 1,
        currentValue: 0,
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.community,
      ),

      // Logros milestone
      Achievement(
        id: '',
        userId: userId,
        type: AchievementType.milestone,
        title: 'Nivel 5 Alcanzado',
        description: 'Alcanza el nivel 5 en la gamificación',
        iconName: 'grade',
        points: 100,
        targetValue: 5,
        currentValue: 1, // Nivel actual
        isCompleted: false,
        isClaimed: false,
        dateEarned: null,
        category: AchievementCategory.special,
      ),
    ];
  }
}