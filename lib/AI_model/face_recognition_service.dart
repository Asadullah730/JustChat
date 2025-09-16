import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('facenet.tflite');
  }

  List<double> getEmbedding(img.Image faceImage) {
    // Resize face to 160x160 (FaceNet input size)
    final resized = img.copyResize(faceImage, width: 160, height: 160);

    // Input tensor [1, 160, 160, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        160,
        (_) => List.generate(160, (_) => List.filled(3, 0.0)),
      ),
    );

    if (kDebugMode) {
      print(
        "Input shape: ${input.length}, ${input[0].length}, ${input[0][0].length}, ${input[0][0][0].length}",
      );
    }

    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        final pixel = resized.getPixel(x, y); // returns Pixel object

        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // 🔹 Normalize from [0,255] → [-1,1]
        input[0][y][x][0] = (r - 127.5) / 128.0;
        input[0][y][x][1] = (g - 127.5) / 128.0;
        input[0][y][x][2] = (b - 127.5) / 128.0;
      }
    }

    // Output tensor [1, 128]
    var output = List.generate(1, (_) => List.filled(128, 0.0));
    if (kDebugMode) {
      print("Output shape: ${output.length}, ${output[0].length} ,");
      print("Running inference...");
    }

    _interpreter.run(input, output);
    if (kDebugMode) {
      print("RUNNING INFERENCE DONE : ${List<double>.from(output[0])}");
    }

    // Return 128D embedding vector
    return List<double>.from(output[0]);
  }
}
