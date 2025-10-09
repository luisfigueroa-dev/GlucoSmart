import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import '../repositories/activity_repo.dart';

/// Provider para gestionar el estado de las actividades físicas.
/// Maneja carga, adición, actualización y eliminación de actividades.
/// Notifica a los widgets cuando cambia el estado.
class ActivityProvider with ChangeNotifier {
  /// Repositorio para operaciones de BD.
  final ActivityRepository _repository;

  /// Lista de actividades cargadas.
  List<Activity> _activities = [];

  /// Estado de carga.
  bool _isLoading = false;

  /// Mensaje de error.
  String? _error;

  /// Constructor que recibe el repositorio.
  ActivityProvider(this._repository);

  /// Getter para la lista de actividades.
  List<Activity> get activities => _activities;

  /// Getter para estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para mensaje de error.
  String? get error => _error;

  /// Carga todas las actividades del usuario.
  Future<void> loadActivities(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _activities = await _repository.getActivities(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Carga actividades de los últimos 7 días.
  Future<void> loadLast7DaysActivities(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _activities = await _repository.getLast7DaysActivities(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Agrega una nueva actividad.
  Future<void> addActivity(Activity activity) async {
    _setLoading(true);
    _error = null;
    try {
      final newActivity = await _repository.addActivity(activity);
      _activities.insert(0, newActivity); // Agregar al inicio (más reciente)
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza una actividad existente.
  Future<void> updateActivity(Activity activity) async {
    _setLoading(true);
    _error = null;
    try {
      final updatedActivity = await _repository.updateActivity(activity);
      final index = _activities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _activities[index] = updatedActivity;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina una actividad.
  Future<void> deleteActivity(String activityId, String userId) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.deleteActivity(activityId, userId);
      _activities.removeWhere((a) => a.id == activityId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene el total de pasos en un rango de fechas.
  Future<int> getTotalStepsInRange(String userId, DateTime start, DateTime end) async {
    try {
      return await _repository.getTotalStepsInRange(userId, start, end);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Obtiene el total de calorías en un rango de fechas.
  Future<double> getTotalCaloriesInRange(String userId, DateTime start, DateTime end) async {
    try {
      return await _repository.getTotalCaloriesInRange(userId, start, end);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0.0;
    }
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
}