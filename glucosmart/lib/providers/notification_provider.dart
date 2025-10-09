import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../repositories/notification_repo.dart';
import '../utils/notification_util.dart';
import '../models/glucose.dart';
import '../models/medication.dart';

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

  /// Genera notificaciones inteligentes basadas en patrones de datos.
  /// Analiza glucosa, medicación y actividad para crear alertas relevantes.
  ///
  /// [glucoseData] Lista de mediciones de glucosa recientes
  /// [medicationData] Lista de dosis de medicación recientes
  /// [userId] ID del usuario
  Future<void> generateSmartNotifications({
    required List<Glucose> glucoseData,
    required List<Medication> medicationData,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final smartNotifications = <Notification>[];

      // 1. Notificaciones basadas en patrones de glucosa
      final glucosePatterns = _analyzeGlucosePatterns(glucoseData);
      smartNotifications.addAll(_createGlucoseBasedNotifications(glucosePatterns, userId));

      // 2. Recordatorios de medicación
      smartNotifications.addAll(_createMedicationReminders(medicationData, userId));

      // 3. Notificaciones de tendencias
      final trendNotifications = _analyzeTrends(glucoseData, medicationData);
      smartNotifications.addAll(trendNotifications);

      // Programar todas las notificaciones inteligentes
      for (final notification in smartNotifications) {
        await scheduleNotification(notification);
      }

    } catch (e) {
      _error = 'Error al generar notificaciones inteligentes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Analiza patrones en los datos de glucosa.
  Map<String, dynamic> _analyzeGlucosePatterns(List<Glucose> glucoseData) {
    if (glucoseData.isEmpty) return {};

    final values = glucoseData.map((g) => g.value).toList();
    final avgGlucose = values.reduce((a, b) => a + b) / values.length;

    final highs = values.where((v) => v > 180).length;
    final lows = values.where((v) => v < 70).length;
    final normals = values.where((v) => v >= 70 && v <= 140).length;

    // Calcular variabilidad (desviación estándar aproximada)
    final variance = values.map((v) => (v - avgGlucose) * (v - avgGlucose)).reduce((a, b) => a + b) / values.length;
    final variability = variance > 0 ? math.sqrt(variance) : 0.0;

    return {
      'avgGlucose': avgGlucose,
      'highCount': highs,
      'lowCount': lows,
      'normalCount': normals,
      'variability': variability,
      'totalReadings': values.length,
    };
  }

  /// Crea notificaciones basadas en patrones de glucosa.
  List<Notification> _createGlucoseBasedNotifications(Map<String, dynamic> patterns, String userId) {
    final notifications = <Notification>[];

    if (patterns.isEmpty) return notifications;

    final avgGlucose = patterns['avgGlucose'] as double;
    final highCount = patterns['highCount'] as int;
    final lowCount = patterns['lowCount'] as int;
    final variability = patterns['variability'] as double;

    // Notificación de glucosa alta frecuente
    if (highCount > 3) {
      notifications.add(Notification(
        id: '',
        userId: userId,
        title: 'Alerta: Glucosa frecuentemente alta',
        body: 'Has tenido ${highCount} lecturas altas esta semana. Revisa tu alimentación y medicación.',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        type: NotificationType.glucose,
        isActive: true,
      ));
    }

    // Notificación de hipoglucemia frecuente
    if (lowCount > 2) {
      notifications.add(Notification(
        id: '',
        userId: userId,
        title: 'Cuidado: Hipoglucemia frecuente',
        body: 'Has tenido ${lowCount} lecturas bajas. Ajusta tus dosis de insulina y monitorea de cerca.',
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        type: NotificationType.glucose,
        isActive: true,
      ));
    }

    // Notificación de alta variabilidad
    if (variability > 50) {
      notifications.add(Notification(
        id: '',
        userId: userId,
        title: 'Glucosa inestable',
        body: 'Tu glucosa varía mucho. Intenta mantener rutinas más consistentes.',
        scheduledTime: DateTime.now().add(const Duration(hours: 4)),
        type: NotificationType.glucose,
        isActive: true,
      ));
    }

    return notifications;
  }

  /// Crea recordatorios de medicación basados en patrones.
  List<Notification> _createMedicationReminders(List<Medication> medicationData, String userId) {
    final notifications = <Notification>[];

    // Recordatorios diarios para medicamentos comunes
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Recordatorio de insulina basal (asumiendo mañana temprano)
    notifications.add(Notification(
      id: '',
      userId: userId,
      title: 'Recordatorio: Insulina basal',
      body: 'No olvides tu dosis de insulina basal mañana por la mañana.',
      scheduledTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0),
      type: NotificationType.medication,
      isActive: true,
    ));

    // Recordatorio de medición de glucosa
    notifications.add(Notification(
      id: '',
      userId: userId,
      title: 'Hora de medir glucosa',
      body: 'Es momento de verificar tus niveles de azúcar en sangre.',
      scheduledTime: now.add(const Duration(hours: 2)),
      type: NotificationType.glucose,
      isActive: true,
    ));

    return notifications;
  }

  /// Analiza tendencias y crea notificaciones preventivas.
  List<Notification> _createTrendNotifications(List<Glucose> glucoseData, List<Medication> medicationData) {
    final notifications = <Notification>[];

    if (glucoseData.length < 7) return notifications;

    // Tendencia alcista en glucosa
    final recent = glucoseData.take(3).map((g) => g.value).toList();
    final older = glucoseData.skip(3).take(3).map((g) => g.value).toList();

    if (recent.isNotEmpty && older.isNotEmpty) {
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final olderAvg = older.reduce((a, b) => a + b) / older.length;

      if (recentAvg > olderAvg + 20) {
        notifications.add(Notification(
          id: '',
          userId: glucoseData.first.userId,
          title: 'Tendencia: Glucosa aumentando',
          body: 'Tu glucosa ha aumentado últimamente. Revisa posibles causas.',
          scheduledTime: DateTime.now().add(const Duration(hours: 3)),
          type: NotificationType.glucose,
          isActive: true,
        ));
      }
    }

    return notifications;
  }

  /// Método auxiliar para analizar tendencias.
  List<Notification> _analyzeTrends(List<Glucose> glucoseData, List<Medication> medicationData) {
    return _createTrendNotifications(glucoseData, medicationData);
  }
}