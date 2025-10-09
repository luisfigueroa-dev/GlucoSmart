import 'package:flutter/foundation.dart';
import '../models/health_parameter.dart';
import '../repositories/health_parameter_repo.dart';

/// Provider para gestionar el estado de los parámetros de salud.
/// Maneja carga, adición, actualización y eliminación de parámetros.
/// Notifica a los widgets cuando cambia el estado.
class HealthParameterProvider with ChangeNotifier {
  /// Repositorio para operaciones de BD.
  final HealthParameterRepository _repository;

  /// Lista de parámetros cargados.
  List<HealthParameter> _parameters = [];

  /// Estado de carga.
  bool _isLoading = false;

  /// Mensaje de error.
  String? _error;

  /// Constructor que recibe el repositorio.
  HealthParameterProvider(this._repository);

  /// Getter para la lista de parámetros.
  List<HealthParameter> get parameters => _parameters;

  /// Getter para estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para mensaje de error.
  String? get error => _error;

  /// Carga todos los parámetros del usuario.
  Future<void> loadParameters(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _parameters = await _repository.getHealthParameters(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Carga parámetros de los últimos 30 días.
  Future<void> loadLast30DaysParameters(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _parameters = await _repository.getLast30DaysParameters(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Carga parámetros de un tipo específico.
  Future<void> loadParametersByType(String userId, HealthParameterType type) async {
    _setLoading(true);
    _error = null;
    try {
      _parameters = await _repository.getParametersByType(userId, type);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Agrega un nuevo parámetro.
  Future<void> addParameter(HealthParameter parameter) async {
    _setLoading(true);
    _error = null;
    try {
      final newParameter = await _repository.addHealthParameter(parameter);
      _parameters.insert(0, newParameter); // Agregar al inicio
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza un parámetro existente.
  Future<void> updateParameter(HealthParameter parameter) async {
    _setLoading(true);
    _error = null;
    try {
      final updatedParameter = await _repository.updateHealthParameter(parameter);
      final index = _parameters.indexWhere((p) => p.id == parameter.id);
      if (index != -1) {
        _parameters[index] = updatedParameter;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina un parámetro.
  Future<void> deleteParameter(String parameterId, String userId) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.deleteHealthParameter(parameterId, userId);
      _parameters.removeWhere((p) => p.id == parameterId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene el último parámetro de un tipo.
  Future<HealthParameter?> getLatestParameter(String userId, HealthParameterType type) async {
    try {
      return await _repository.getLatestParameter(userId, type);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Obtiene el promedio en un rango para un tipo.
  Future<double?> getAverageInRange(String userId, HealthParameterType type, DateTime start, DateTime end) async {
    try {
      return await _repository.getAverageInRange(userId, type, start, end);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
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