import 'package:flutter/foundation.dart';
import '../models/carbs.dart';
import '../repositories/carbs_repo.dart';

/// Provider para manejar el estado de las ingestas de carbohidratos.
/// Utiliza ChangeNotifier para notificar cambios a los widgets escuchando.
/// Integra con CarbsRepository para operaciones de datos.
/// Maneja errores y estados de carga de manera asíncrona.
/// Compatible con Dart 3.0 y null-safety.
class CarbsProvider extends ChangeNotifier {
  /// Constructor que recibe el repositorio de carbohidratos.
  CarbsProvider(this._repository);

  /// Repositorio para operaciones de base de datos.
  final CarbsRepository _repository;

  /// Lista de ingestas de carbohidratos cargadas.
  List<Carbs> _entries = [];

  /// Estado de carga para operaciones asíncronas.
  bool _isLoading = false;

  /// Mensaje de error en caso de fallos.
  String? _error;

  /// Getter para la lista de ingestas.
  List<Carbs> get entries => _entries;

  /// Getter para el estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para el mensaje de error.
  String? get error => _error;

  /// Carga las ingestas de carbohidratos de los últimos 7 días para un usuario.
  /// Actualiza el estado interno y notifica a los listeners.
  /// Maneja errores capturándolos y almacenándolos en [_error].
  ///
  /// [userId] El ID del usuario cuyas ingestas se cargan.
  Future<void> loadLast7Days(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Llamada asíncrona al repositorio para obtener datos.
      // Se ordenan por timestamp descendente en el repositorio.
      _entries = await _repository.getLast7Days(userId);
    } catch (e) {
      // Captura cualquier error y lo almacena para mostrar en UI.
      _error = 'Error al cargar ingestas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega una nueva ingesta de carbohidratos.
  /// Inserta en la base de datos y actualiza la lista local si es exitoso.
  /// Notifica cambios para actualizar la UI.
  /// Maneja errores de inserción.
  ///
  /// [carbs] La nueva ingesta a agregar (sin ID, se genera en BD).
  Future<void> addCarbsIntake(Carbs carbs) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Inserta la ingesta en la base de datos.
      // El ID se genera automáticamente en Supabase.
      final newId = await _repository.insert(carbs);

      // Crea una nueva instancia con el ID generado.
      final newCarbs = carbs.copyWith(id: newId);

      // Agrega a la lista local y ordena por timestamp descendente.
      // Esto mantiene la consistencia con el orden del repositorio.
      _entries.insert(0, newCarbs);
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      // Captura errores de inserción.
      _error = 'Error al agregar ingesta: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el mensaje de error.
  /// Útil para resetear el estado después de mostrar el error al usuario.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}