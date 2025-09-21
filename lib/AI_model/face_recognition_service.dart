import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/facenet_fixed.tflite');
      if (kDebugMode) {
        print(
          "Model loaded successfully INPUT, ${_interpreter.getInputTensors()}",
        );
        print(
          "Model loaded successfully OUTPUT, ${_interpreter.getInputTensors()}",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to load model: $e");
      }
    }
  }

  List<double> getEmbedding(img.Image faceImage) {
    // Resize to 160x160
    final resized = img.copyResize(faceImage, width: 160, height: 160);

    // Input tensor [1,160,160,3]
    var input = List.generate(
      1,
      (_) => List.generate(
        160,
        (_) => List.generate(160, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // Normalize [-1,1]
        input[0][y][x][0] = (r - 127.5) / 128.0;
        input[0][y][x][1] = (g - 127.5) / 128.0;
        input[0][y][x][2] = (b - 127.5) / 128.0;
      }
    }

    // Output tensor [1,512]
    var output = List.generate(1, (_) => List.filled(512, 0.0));

    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }
}
