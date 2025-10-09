import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../repositories/medication_repo.dart';

/// Provider para manejar el estado de las dosis de medicamentos.
/// Utiliza ChangeNotifier para notificar cambios a los widgets escuchando.
/// Integra con MedicationRepository para operaciones de datos.
/// Maneja errores y estados de carga de manera asíncrona.
/// Compatible con Dart 3.0 y null-safety.
class MedicationProvider extends ChangeNotifier {
  /// Constructor que recibe el repositorio de medicamentos.
  MedicationProvider(this._repository);

  /// Repositorio para operaciones de base de datos.
  final MedicationRepository _repository;

  /// Lista de dosis de medicamentos cargadas.
  List<Medication> _entries = [];

  /// Estado de carga para operaciones asíncronas.
  bool _isLoading = false;

  /// Mensaje de error en caso de fallos.
  String? _error;

  /// Getter para la lista de dosis.
  List<Medication> get entries => _entries;

  /// Getter para el estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para el mensaje de error.
  String? get error => _error;

  /// Carga todas las dosis de medicamentos para un usuario.
  Future<void> loadAll(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _entries = await _repository.getAll(userId);
    } catch (e) {
      _error = 'Error al cargar dosis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga las dosis de medicamentos de los últimos 7 días para un usuario.
  /// Actualiza el estado interno y notifica a los listeners.
  /// Maneja errores capturándolos y almacenándolos en [_error].
  ///
  /// [userId] El ID del usuario cuyas dosis se cargan.
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
      _error = 'Error al cargar dosis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Agrega una nueva dosis de medicamento.
  /// Inserta en la base de datos y actualiza la lista local si es exitoso.
  /// Notifica cambios para actualizar la UI.
  /// Maneja errores de inserción.
  ///
  /// [medication] La nueva dosis a agregar (sin ID, se genera en BD).
  Future<void> addMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Inserta la dosis en la base de datos.
      // El ID se genera automáticamente en Supabase.
      final newId = await _repository.insert(medication);

      // Crea una nueva instancia con el ID generado.
      final newMedication = medication.copyWith(id: newId);

      // Agrega a la lista local y ordena por timestamp descendente.
      // Esto mantiene la consistencia con el orden del repositorio.
      _entries.insert(0, newMedication);
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      // Captura errores de inserción.
      _error = 'Error al agregar dosis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza una dosis de medicamento existente.
  Future<void> updateMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedMedication = await _repository.update(medication);
      final index = _entries.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        _entries[index] = updatedMedication;
        _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      _error = 'Error al actualizar dosis: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una dosis de medicamento.
  Future<void> deleteMedication(String medicationId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.delete(medicationId, userId);
      _entries.removeWhere((m) => m.id == medicationId);
    } catch (e) {
      _error = 'Error al eliminar dosis: $e';
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