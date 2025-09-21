import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';

class TFLiteHelper {
  static late Interpreter _interpreter;
  static bool _isInitialized = false;

  static Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/facenet_fixed.tflite');
      _isInitialized = true;

      if (kDebugMode) {
        print("TFLite model loaded successfully, $_interpreter");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to load model: $e");
      }
    }
  }

  static Interpreter get interpreter {
    if (!_isInitialized) throw Exception("Model not initialized");
    return _interpreter;
  }
}
