import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Utilidad para manejar notificaciones locales integrando flutter_local_notifications y WorkManager.
/// Proporciona inicialización, scheduling, cancelación y manejo de permisos.
/// Utiliza Dart 3.0 con null-safety.
class NotificationUtil {
  static final NotificationUtil _instance = NotificationUtil._internal();
  factory NotificationUtil() => _instance;
  NotificationUtil._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa los plugins de notificaciones locales y WorkManager.
  /// Configura los ajustes para Android e iOS, y registra tareas en segundo plano.
  /// Debe llamarse en main() antes de usar otras funciones.
  Future<void> initialize() async {
    // Configuración para Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings);

    // Inicializar WorkManager
    await Workmanager().initialize(
      _callbackDispatcher,
      isInDebugMode: false, // Cambiar a true para desarrollo
    );

    // Registrar tarea periódica si es necesario
    await Workmanager().registerPeriodicTask(
      'checkNotifications',
      'checkNotifications',
      frequency: const Duration(hours: 1), // Verificar cada hora
    );
  }

  /// Solicita permisos para notificaciones.
  /// Maneja permisos para Android e iOS.
  /// Retorna true si se concedieron los permisos, false en caso contrario.
  Future<bool> requestPermissions() async {
    // Para Android 13+, solicitar permiso de notificaciones
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Programa una notificación local para una fecha y hora específica.
  /// Utiliza timezone para manejar zonas horarias correctamente.
  /// [id] Identificador único de la notificación.
  /// [title] Título de la notificación.
  /// [body] Cuerpo de la notificación.
  /// [scheduledDate] Fecha y hora programada en zona local.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Convertir a zona horaria local usando tz
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'glucose_channel',
      'Glucose Notifications',
      channelDescription: 'Notificaciones para recordatorios de glucosa',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela una notificación específica por su ID.
  /// [id] Identificador de la notificación a cancelar.
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancela todas las notificaciones programadas.
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Función de callback para WorkManager.
  /// Maneja tareas en segundo plano, como verificar notificaciones pendientes.
  /// Esta función debe ser top-level para que WorkManager la encuentre.
  @pragma('vm:entry-point')
  static void _callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      switch (task) {
        case 'checkNotifications':
          // Lógica compleja: Verificar notificaciones pendientes en base de datos
          // y programarlas localmente si es necesario.
          // Aquí se integraría con NotificationRepository para obtener notificaciones activas.
          // Por simplicidad, solo se registra el log; en producción, implementar lógica completa.
          print('Verificando notificaciones pendientes...');
          return Future.value(true);
        default:
          return Future.value(false);
      }
    });
  }
}