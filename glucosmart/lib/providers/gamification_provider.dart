import 'package:flutter/foundation.dart';
import '../models/gamification.dart';
import '../repositories/gamification_repo.dart';

/// Provider para gestionar gamificación.
/// Detecta acciones del usuario y otorga puntos/logros automáticamente.
/// Integra con otros providers para monitorear actividad.
class GamificationProvider with ChangeNotifier {
  /// Repositorio para operaciones de BD.
  final GamificationRepository _repository;

  /// Estadísticas del usuario.
  UserGamificationStats? _userStats;

  /// Lista de logros del usuario.
  List<Achievement> _userAchievements = [];

  /// Estado de carga.
  bool _isLoading = false;

  /// Mensaje de error.
  String? _error;

  /// Constructor que recibe el repositorio.
  GamificationProvider(this._repository);

  /// Getter para estadísticas.
  UserGamificationStats? get userStats => _userStats;

  /// Getter para logros.
  List<Achievement> get userAchievements => _userAchievements;

  /// Getter para logros completados.
  List<Achievement> get completedAchievements =>
      _userAchievements.where((a) => a.isCompleted).toList();

  /// Getter para logros disponibles.
  List<Achievement> get availableAchievements =>
      _userAchievements.where((a) => !a.isCompleted).toList();

  /// Getter para estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para error.
  String? get error => _error;

  /// Inicializa gamificación para un usuario.
  Future<void> initializeGamification(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      // Verificar si ya tiene logros
      final existingAchievements = await _repository.getUserAchievements(userId);

      if (existingAchievements.isEmpty) {
        // Inicializar logros por defecto
        await _repository.initializeDefaultAchievements(userId);
        _userAchievements = await _repository.getUserAchievements(userId);
      } else {
        _userAchievements = existingAchievements;
      }

      // Obtener estadísticas
      _userStats = await _repository.getUserStats(userId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Registra acción del usuario y actualiza gamificación.
  /// [actionType] Tipo de acción realizada
  /// [value] Valor asociado a la acción (ej: cantidad de glucosa registrada)
  Future<void> registerUserAction(String userId, AchievementType actionType, {int value = 1}) async {
    try {
      // Buscar logros relacionados con esta acción
      final relevantAchievements = _userAchievements
          .where((achievement) =>
              achievement.type == actionType &&
              !achievement.isCompleted)
          .toList();

      for (final achievement in relevantAchievements) {
        final newValue = achievement.currentValue + value;
        final updatedAchievement = await _repository.updateAchievementProgress(
          achievement.id,
          newValue,
          userId,
        );

        // Actualizar en lista local
        final index = _userAchievements.indexWhere((a) => a.id == achievement.id);
        if (index != -1) {
          _userAchievements[index] = updatedAchievement;

          // Si se completó, otorgar puntos
          if (updatedAchievement.isCompleted && !updatedAchievement.isClaimed) {
            await _grantAchievementPoints(userId, updatedAchievement.points);
          }
        }
      }

      // Actualizar estadísticas de racha
      await _updateActivityStreak(userId);

      notifyListeners();
    } catch (e) {
      _error = 'Error al registrar acción: $e';
      notifyListeners();
    }
  }

  /// Otorga puntos por completar un logro.
  Future<void> _grantAchievementPoints(String userId, int points) async {
    try {
      _userStats = await _repository.updateUserStats(userId, pointsToAdd: points);
      notifyListeners();
    } catch (e) {
      _error = 'Error al otorgar puntos: $e';
    }
  }

  /// Actualiza la racha de actividad del usuario.
  Future<void> _updateActivityStreak(String userId) async {
    try {
      final today = DateTime.now();
      final lastActivity = _userStats?.lastActivityDate ?? today.subtract(const Duration(days: 1));

      int newStreak = _userStats?.currentStreak ?? 0;

      if (_isConsecutiveDay(lastActivity, today)) {
        newStreak++;
      } else if (!_isSameDay(lastActivity, today)) {
        newStreak = 1; // Reiniciar racha
      }

      _userStats = await _repository.updateUserStats(userId, streakUpdate: newStreak);
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar racha: $e';
    }
  }

  /// Reclama recompensa de un logro completado.
  Future<void> claimAchievementReward(String achievementId, String userId) async {
    try {
      await _repository.claimAchievementReward(achievementId, userId);

      // Actualizar estado local
      final index = _userAchievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        _userAchievements[index] = _userAchievements[index].copyWith(isClaimed: true);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al reclamar recompensa: $e';
      notifyListeners();
    }
  }

  /// Obtiene logros por categoría.
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _userAchievements.where((a) => a.category == category).toList();
  }

  /// Obtiene logros por tipo.
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _userAchievements.where((a) => a.type == type).toList();
  }

  /// Calcula progreso total del usuario.
  double get totalProgress {
    if (_userAchievements.isEmpty) return 0.0;

    final totalProgress = _userAchievements
        .map((a) => a.progressPercentage)
        .reduce((a, b) => a + b);

    return totalProgress / _userAchievements.length;
  }

  /// Verifica si el usuario está en racha actual.
  bool get isInCurrentStreak {
    if (_userStats == null) return false;
    final today = DateTime.now();
    return _isSameDay(_userStats!.lastActivityDate, today);
  }

  /// Método auxiliar para verificar si dos fechas son consecutivas.
  bool _isConsecutiveDay(DateTime date1, DateTime date2) {
    final diff = date2.difference(date1).inDays;
    return diff == 1;
  }

  /// Método auxiliar para verificar si dos fechas son el mismo día.
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Método auxiliar para cambiar estado de carga.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Limpia el error.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Métodos específicos para diferentes tipos de acciones

  /// Registra medición de glucosa.
  Future<void> registerGlucoseMeasurement(String userId) async {
    await registerUserAction(userId, AchievementType.glucose);
  }

  /// Registra actividad física.
  Future<void> registerActivity(String userId, int steps) async {
    await registerUserAction(userId, AchievementType.activity, value: steps);
  }

  /// Registra ingesta de carbohidratos.
  Future<void> registerCarbsIntake(String userId) async {
    await registerUserAction(userId, AchievementType.nutrition);
  }

  /// Registra sesión de educación.
  Future<void> registerEducationSession(String userId) async {
    await registerUserAction(userId, AchievementType.education);
  }

  /// Registra toma de medicamento.
  Future<void> registerMedication(String userId) async {
    await registerUserAction(userId, AchievementType.adherence);
  }

  /// Registra acción social (compartir).
  Future<void> registerSocialAction(String userId) async {
    await registerUserAction(userId, AchievementType.social);
  }

  /// Actualiza logro de nivel (llamado cuando sube de nivel).
  Future<void> updateLevelAchievement(String userId, int newLevel) async {
    try {
      final levelAchievements = _userAchievements
          .where((a) => a.type == AchievementType.milestone && a.title.contains('Nivel'))
          .toList();

      for (final achievement in levelAchievements) {
        if (newLevel >= achievement.targetValue && !achievement.isCompleted) {
          final updatedAchievement = await _repository.updateAchievementProgress(
            achievement.id,
            newLevel,
            userId,
          );

          final index = _userAchievements.indexWhere((a) => a.id == achievement.id);
          if (index != -1) {
            _userAchievements[index] = updatedAchievement;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar logro de nivel: $e';
      notifyListeners();
    }
  }
}