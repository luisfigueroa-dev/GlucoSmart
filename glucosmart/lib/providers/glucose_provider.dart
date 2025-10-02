import 'package:flutter/foundation.dart';
import '../models/glucose.dart';
import '../repositories/glucose_repo.dart';

/// Provider para manejar el estado de las mediciones de glucosa.
/// Utiliza ChangeNotifier para notificar cambios a los widgets escuchando.
/// Integra con GlucoseRepository para operaciones de datos.
/// Maneja errores y estados de carga de manera asíncrona.
/// Compatible con Dart 3.0 y null-safety.
class GlucoseProvider extends ChangeNotifier {
  /// Constructor que recibe el repositorio de glucosa.
  GlucoseProvider(this._repository);

  /// Repositorio para operaciones de base de datos.
  final GlucoseRepository _repository;

  /// Lista de mediciones de glucosa cargadas.
  List<Glucose> _measurements = [];

  /// Estado de carga para operaciones asíncronas.
  bool _isLoading = false;

  /// Mensaje de error en caso de fallos.
  String? _error;

  /// Getter para la lista de mediciones.
  List<Glucose> get measurements => _measurements;

  /// Getter para el estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para el mensaje de error.
  String? get error => _error;

  /// Carga las mediciones de glucosa de los últimos 7 días para un usuario.
  /// Actualiza el estado interno y notifica a los listeners.
  /// Maneja errores capturándolos y almacenándolos en [_error].
  ///
  /// [userId] El ID del usuario cuyas mediciones se cargan.
  Future<void> loadLast7Days(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Llamada asíncrona al repositorio para obtener datos.
      // Se ordenan por timestamp descendente en el repositorio.
      _measurements = await _repository.getLast7Days(userId);
    } catch (e) {
      // Captura cualquier error y lo almacena para mostrar en UI.
      _error = 'Error al cargar mediciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega una nueva medición de glucosa.
  /// Inserta en la base de datos y actualiza la lista local si es exitoso.
  /// Notifica cambios para actualizar la UI.
  /// Maneja errores de inserción.
  ///
  /// [glucose] La nueva medición a agregar (sin ID, se genera en BD).
  Future<void> addMeasurement(Glucose glucose) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Inserta la medición en la base de datos.
      // El ID se genera automáticamente en Supabase.
      final newId = await _repository.insert(glucose);

      // Crea una nueva instancia con el ID generado.
      final newGlucose = glucose.copyWith(id: newId);

      // Agrega a la lista local y ordena por timestamp descendente.
      // Esto mantiene la consistencia con el orden del repositorio.
      _measurements.insert(0, newGlucose);
      _measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      // Captura errores de inserción.
      _error = 'Error al agregar medición: $e';
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