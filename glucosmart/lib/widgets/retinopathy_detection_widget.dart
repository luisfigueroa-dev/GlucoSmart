import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/ml_util.dart';

/// Widget para detección de retinopatía diabética mediante captura de imagen de retina.
/// Permite tomar foto usando la cámara del dispositivo, procesa on-device con MLUtil
/// utilizando el modelo de retinopatía, muestra el score de probabilidad y recomendaciones.
/// Compatible con Dart 3.0, null-safety y accesibilidad WCAG 2.2 AA.
class RetinopathyDetectionWidget extends StatefulWidget {
  /// Constructor del widget.
  const RetinopathyDetectionWidget({super.key});

  @override
  State<RetinopathyDetectionWidget> createState() => _RetinopathyDetectionWidgetState();
}

class _RetinopathyDetectionWidgetState extends State<RetinopathyDetectionWidget> {
  /// Instancia de MLUtil para procesamiento de imágenes.
  final MLUtil _mlUtil = MLUtil();

  /// Controlador de la cámara.
  CameraController? _cameraController;

  /// Lista de cámaras disponibles.
  List<CameraDescription>? _cameras;

  /// Estado de inicialización de la cámara.
  bool _isCameraInitialized = false;

  /// Estado de procesamiento de la imagen.
  bool _isProcessing = false;

  /// Probabilidad de retinopatía detectada (0.0 a 1.0).
  double? _retinopathyScore;

  /// Mensaje de error en caso de fallo.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadRetinopathyModel();
  }

  /// Inicializa la cámara del dispositivo.
  /// Lógica compleja: Se obtienen las cámaras disponibles, se selecciona la trasera por defecto,
  /// se configura el controlador con resolución media para balancear calidad y rendimiento,
  /// y se maneja errores para dispositivos sin cámara o permisos denegados.
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Seleccionar cámara trasera por defecto.
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium, // Balance entre calidad y rendimiento.
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        _setError('No se encontraron cámaras disponibles en el dispositivo.');
      }
    } catch (e) {
      _setError('Error al inicializar la cámara: $e');
    }
  }

  /// Carga el modelo de retinopatía en MLUtil.
  Future<void> _loadRetinopathyModel() async {
    try {
      await _mlUtil.loadRetinopathyModel();
    } catch (e) {
      _setError('Error al cargar modelo de retinopatía: $e');
    }
  }

  /// Toma una foto de la retina y procesa con ML.
  /// Lógica compleja: Se captura la imagen como archivo temporal, se pasa a MLUtil.detectRetinopathy
  /// que redimensiona la imagen a 224x224, normaliza píxeles RGB y ejecuta inferencia en el modelo CNN.
  /// El score se actualiza en el estado para mostrar resultados y recomendaciones.
  Future<void> _takePhotoAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _setError('Cámara no inicializada.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _retinopathyScore = null;
    });

    try {
      final image = await _cameraController!.takePicture();
      final score = await _mlUtil.detectRetinopathy(File(image.path));
      if (mounted) {
        setState(() {
          _retinopathyScore = score;
        });
      }
    } catch (e) {
      _setError('Error al procesar la imagen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Establece un mensaje de error en el estado.
  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  /// Genera recomendaciones basadas en el score de retinopatía.
  /// Lógica compleja: Umbrales definidos (bajo <0.3, medio 0.3-0.7, alto >0.7)
  /// para categorizar riesgo y proporcionar consejos personalizados sobre monitoreo y consulta médica.
  String _getRecommendations() {
    if (_retinopathyScore == null) return '';

    if (_retinopathyScore! < 0.3) {
      return 'Riesgo bajo de retinopatía. Continúa con controles regulares y monitoreo de glucosa.';
    } else if (_retinopathyScore! < 0.7) {
      return 'Riesgo moderado. Consulta a un oftalmólogo para evaluación detallada en los próximos 3-6 meses.';
    } else {
      return 'Riesgo alto de retinopatía. Busca atención médica inmediata con un especialista en retina.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título accesible.
            Semantics(
              header: true,
              child: Text(
                'Detección de Retinopatía Diabética',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),
            // Vista previa de la cámara.
            if (_isCameraInitialized && _cameraController != null)
              Semantics(
                label: 'Vista previa de la cámara para capturar imagen de retina',
                child: Container(
                  height: 250,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else if (_errorMessage != null)
              Semantics(
                label: 'Error en la inicialización de la cámara: $_errorMessage',
                child: Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              )
            else
              Semantics(
                label: 'Inicializando cámara',
                child: Container(
                  height: 250,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Botón para tomar foto.
            Center(
              child: Semantics(
                button: true,
                label: 'Tomar foto de retina para análisis',
                hint: 'Presiona para capturar imagen y procesar con IA',
                child: ElevatedButton.icon(
                  onPressed: _isCameraInitialized && !_isProcessing ? _takePhotoAndProcess : null,
                  icon: const Icon(Icons.camera),
                  label: const Text('Capturar Retina'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Indicador de procesamiento.
            if (_isProcessing)
              Semantics(
                label: 'Procesando imagen con inteligencia artificial',
                child: const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Analizando imagen...'),
                    ],
                  ),
                ),
              )
            // Resultados.
            else if (_retinopathyScore != null)
              Column(
                children: [
                  Semantics(
                    label: 'Score de retinopatía: ${(_retinopathyScore! * 100).toStringAsFixed(1)} por ciento',
                    child: Text(
                      'Probabilidad de Retinopatía: ${(_retinopathyScore! * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    label: 'Recomendaciones basadas en el score: ${_getRecommendations()}',
                    liveRegion: true, // Anuncia cambios.
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _retinopathyScore! < 0.3
                            ? Colors.green.shade100
                            : _retinopathyScore! < 0.7
                                ? Colors.yellow.shade100
                                : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _retinopathyScore! < 0.3
                                ? Icons.check_circle
                                : _retinopathyScore! < 0.7
                                    ? Icons.warning
                                    : Icons.error,
                            color: _retinopathyScore! < 0.3
                                ? Colors.green
                                : _retinopathyScore! < 0.7
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getRecommendations(),
                              style: TextStyle(
                                color: _retinopathyScore! < 0.3
                                    ? Colors.green.shade800
                                    : _retinopathyScore! < 0.7
                                        ? Colors.orange.shade800
                                        : Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else if (_errorMessage != null && !_isCameraInitialized)
              Semantics(
                label: _errorMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _mlUtil.dispose();
    super.dispose();
  }
}