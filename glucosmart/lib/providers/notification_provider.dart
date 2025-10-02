import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../repositories/notification_repo.dart';
import '../utils/notification_util.dart';

/// Provider para manejar el estado de las notificaciones.
/// Utiliza ChangeNotifier para notificar cambios a los widgets escuchando.
/// Integra con NotificationRepository para operaciones de base de datos y NotificationUtil para scheduling local.
/// Maneja errores y estados de carga de manera asíncrona.
/// Compatible con Dart 3.0 y null-safety.
class NotificationProvider extends ChangeNotifier {
  /// Constructor que recibe el repositorio de notificaciones.
  NotificationProvider(this._repository, this._notificationUtil);

  /// Repositorio para operaciones de base de datos.
  final NotificationRepository _repository;

  /// Utilidad para manejar notificaciones locales.
  final NotificationUtil _notificationUtil;

  /// Lista de notificaciones activas cargadas.
  List<Notification> _activeNotifications = [];

  /// Estado de carga para operaciones asíncronas.
  bool _isLoading = false;

  /// Mensaje de error en caso de fallos.
  String? _error;

  /// Getter para la lista de notificaciones activas.
  List<Notification> get activeNotifications => _activeNotifications;

  /// Getter para el estado de carga.
  bool get isLoading => _isLoading;

  /// Getter para el mensaje de error.
  String? get error => _error;

  /// Carga las notificaciones activas para un usuario específico.
  /// Actualiza el estado interno, notifica a los listeners y sincroniza con NotificationUtil.
  /// Maneja errores capturándolos y almacenándolos en [_error].
  ///
  /// [userId] El ID del usuario cuyas notificaciones se cargan.
  Future<void> loadActiveNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Llamada asíncrona al repositorio para obtener notificaciones activas.
      _activeNotifications = await _repository.getActive(userId);

      // Sincronizar con NotificationUtil: programar todas las activas localmente.
      // Lógica compleja: Para cada notificación activa y futura, se programa localmente.
      // Se usa el hash del ID como int para el ID local, asumiendo unicidad.
      for (final notification in _activeNotifications) {
        if (notification.isActiveAndScheduled()) {
          await _notificationUtil.scheduleNotification(
            id: notification.id.hashCode,
            title: notification.title,
            body: notification.body,
            scheduledDate: notification.scheduledTime,
          );
        }
      }
    } catch (e) {
      // Captura cualquier error y lo almacena para mostrar en UI.
      _error = 'Error al cargar notificaciones activas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Programa una nueva notificación.
  /// Inserta en la base de datos, programa localmente y actualiza la lista si es exitoso.
  /// Notifica cambios para actualizar la UI.
  /// Maneja errores de inserción y scheduling.
  ///
  /// [notification] La nueva notificación a programar (sin ID, se genera en BD).
  Future<void> scheduleNotification(Notification notification) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Inserta la notificación en la base de datos.
      final newId = await _repository.insert(notification);

      // Crea una nueva instancia con el ID generado.
      final newNotification = notification.copyWith(id: newId);

      // Programa localmente usando NotificationUtil.
      await _notificationUtil.scheduleNotification(
        id: newId.hashCode,
        title: newNotification.title,
        body: newNotification.body,
        scheduledDate: newNotification.scheduledTime,
      );

      // Agrega a la lista local si está activa y futura.
      if (newNotification.isActiveAndScheduled()) {
        _activeNotifications.add(newNotification);
        // Ordenar por scheduledTime descendente.
        _activeNotifications.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
      }
    } catch (e) {
      // Captura errores de inserción o scheduling.
      _error = 'Error al programar notificación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancela una notificación específica por su ID.
  /// Actualiza en la base de datos a inactiva, cancela localmente y remueve de la lista.
  /// Notifica cambios para actualizar la UI.
  /// Maneja errores de actualización y cancelación.
  ///
  /// [id] El ID de la notificación a cancelar.
  Future<void> cancelNotification(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Actualiza en la base de datos a inactiva.
      await _repository.update(id, {'is_active': false});

      // Cancela localmente usando NotificationUtil.
      await _notificationUtil.cancelNotification(id.hashCode);

      // Remueve de la lista local.
      _activeNotifications.removeWhere((n) => n.id == id);
    } catch (e) {
      // Captura errores de actualización o cancelación.
      _error = 'Error al cancelar notificación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sincroniza las notificaciones activas con NotificationUtil.
  /// Cancela todas las locales y reprograma las activas actuales.
  /// Útil para asegurar consistencia después de cambios externos.
  /// Maneja errores de sincronización.
  Future<void> syncWithUtil() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancela todas las notificaciones locales.
      await _notificationUtil.cancelAllNotifications();

      // Reprograma todas las activas locales.
      // Lógica compleja: Similar a loadActiveNotifications, pero sin recargar de BD.
      for (final notification in _activeNotifications) {
        if (notification.isActiveAndScheduled()) {
          await _notificationUtil.scheduleNotification(
            id: notification.id.hashCode,
            title: notification.title,
            body: notification.body,
            scheduledDate: notification.scheduledTime,
          );
        }
      }
    } catch (e) {
      // Captura errores de sincronización.
      _error = 'Error al sincronizar notificaciones: $e';
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