import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Clase utilitaria para integración de TensorFlow Lite en la aplicación.
/// Proporciona funcionalidades de inferencia on-device para predicción de hipoglucemia
/// y detección de retinopatía diabética.
class MLUtil {
  Interpreter? _ardaInterpreter;
  Interpreter? _ohioInterpreter;
  Interpreter? _retinopathyInterpreter;

  /// Carga el modelo ARDA para predicción de hipoglucemia.
  /// Este modelo utiliza datos históricos de glucosa para predecir episodios de hipoglucemia.
  Future<void> loadArdaModel() async {
    try {
      _ardaInterpreter = await Interpreter.fromAsset('assets/models/arda.tflite');
    } catch (e) {
      throw Exception('Error al cargar modelo ARDA: $e');
    }
  }

  /// Carga el modelo OhioT1DM para predicción de hipoglucemia.
  /// Modelo alternativo basado en datos del conjunto OhioT1DM.
  Future<void> loadOhioModel() async {
    try {
      _ohioInterpreter = await Interpreter.fromAsset('assets/models/ohio.tflite');
    } catch (e) {
      throw Exception('Error al cargar modelo OhioT1DM: $e');
    }
  }

  /// Carga el modelo para detección de retinopatía.
  /// Utiliza imágenes de retina para clasificar presencia de retinopatía diabética.
  Future<void> loadRetinopathyModel() async {
    try {
      _retinopathyInterpreter = await Interpreter.fromAsset('assets/models/retinopathy.tflite');
    } catch (e) {
      throw Exception('Error al cargar modelo de retinopatía: $e');
    }
  }

  /// Predice la probabilidad de hipoglucemia basada en datos históricos.
  /// Utiliza el modelo ARDA si está cargado, de lo contrario OhioT1DM.
  ///
  /// [historicalData]: Lista de valores de glucosa históricos (últimas 24 horas, por ejemplo).
  /// Retorna la probabilidad de hipoglucemia (0.0 a 1.0).
  ///
  /// Lógica compleja: Los datos se normalizan y se pasan como tensor 1D al modelo.
  /// El modelo procesa la secuencia temporal para identificar patrones predictivos de hipoglucemia.
  Future<double> predictHypoglycemia(List<double> historicalData) async {
    if (_ardaInterpreter == null && _ohioInterpreter == null) {
      throw Exception('Ningún modelo de hipoglucemia está cargado');
    }

    try {
      final interpreter = _ardaInterpreter ?? _ohioInterpreter!;
      final inputShape = interpreter.getInputTensors()[0].shape;
      final outputShape = interpreter.getOutputTensors()[0].shape;

      // Normalizar datos (asumiendo rango 0-400 mg/dL)
      final normalizedData = historicalData.map((e) => e / 400.0).toList();

      // Preparar tensor de entrada
      final input = Float32List.fromList(normalizedData);
      final output = Float32List(outputShape.reduce((a, b) => a * b));

      interpreter.run(input, output);

      return output[0]; // Probabilidad de hipoglucemia
    } catch (e) {
      throw Exception('Error en predicción de hipoglucemia: $e');
    }
  }

  /// Detecta retinopatía diabética en una imagen de retina.
  /// Procesa la imagen y retorna la probabilidad de retinopatía.
  ///
  /// [imageFile]: Archivo de imagen de la retina.
  /// Retorna la probabilidad de retinopatía (0.0 a 1.0).
  ///
  /// Lógica compleja: La imagen se redimensiona a 224x224, se normaliza y se convierte
  /// a tensor RGB. El modelo CNN clasifica la presencia de anomalías retinopáticas.
  Future<double> detectRetinopathy(File imageFile) async {
    if (_retinopathyInterpreter == null) {
      throw Exception('Modelo de retinopatía no está cargado');
    }

    try {
      final interpreter = _retinopathyInterpreter!;
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Redimensionar a 224x224 (asumiendo entrada del modelo)
      final resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convertir a RGB y normalizar
      final rgbImage = img.copyResize(resizedImage, width: 224, height: 224);
      final input = Float32List(224 * 224 * 3);

      int index = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = rgbImage.getPixel(x, y);
          input[index++] = pixel.r / 255.0;
          input[index++] = pixel.g / 255.0;
          input[index++] = pixel.b / 255.0;
        }
      }

      final output = Float32List(1); // Asumiendo salida binaria
      interpreter.run(input, output);

      return output[0];
    } catch (e) {
      throw Exception('Error en detección de retinopatía: $e');
    }
  }

  /// Libera los recursos de los modelos cargados.
  void dispose() {
    _ardaInterpreter?.close();
    _ohioInterpreter?.close();
    _retinopathyInterpreter?.close();
    _ardaInterpreter = null;
    _ohioInterpreter = null;
    _retinopathyInterpreter = null;
  }
}