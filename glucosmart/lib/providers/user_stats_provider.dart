import 'package:flutter/foundation.dart';
import '../models/user_stats.dart';
import '../repositories/user_stats_repo.dart';

/// Provider para gestionar estadísticas y gamificación del usuario.
/// Maneja estado de UserStats y operaciones relacionadas.
class UserStatsProvider with ChangeNotifier {
  /// Repositorio para operaciones de BD.
  final UserStatsRepository _repository;

  /// Estadísticas actuales del usuario.
  UserStats? _userStats;

  /// Estado de carga.
  bool _isLoading = false;

  /// Mensaje de error.
  String? _error;

  /// Constructor que recibe el repositorio.
  UserStatsProvider(this._repository);

  /// Getter para estadísticas.
  UserStats? get userStats => _userStats;

  /// Getter para estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para error.
  String? get error => _error;

  /// Carga las estadísticas del usuario.
  Future<void> loadUserStats(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userStats = await _repository.getUserStats(userId);
      if (_userStats == null) {
        _userStats = await _repository.createUserStats(userId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega puntos al usuario por completar acciones.
  Future<void> addPoints(String userId, int points, [String? achievement]) async {
    try {
      _userStats = await _repository.addPoints(userId, points);
      if (achievement != null && !_userStats!.achievements.contains(achievement)) {
        final newAchievements = List<String>.from(_userStats!.achievements)..add(achievement);
        _userStats = _userStats!.copyWith(achievements: newAchievements);
        await _repository.updateUserStats(_userStats!);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Actualiza las estadísticas manualmente.
  Future<void> updateStats(UserStats stats) async {
    try {
      _userStats = await _repository.updateUserStats(stats);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Limpia el estado (útil al cerrar sesión).
  void clear() {
    _userStats = null;
    _error = null;
    notifyListeners();
  }
}