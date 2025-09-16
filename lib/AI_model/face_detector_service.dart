import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final _options = FaceDetectorOptions(
    performanceMode: FaceDetectorMode.accurate,
    enableTracking: false,
  );

  Future<img.Image?> detectAndCropFace(File imageFile) async {
    final faceDetector = FaceDetector(options: _options);
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) return null;

    final face = faces.first;
    final rect = face.boundingBox;

    final originalImage = img.decodeImage(imageFile.readAsBytesSync())!;
    final cropped = img.copyCrop(
      originalImage,
      x: rect.left.toInt(),
      y: rect.top.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );

    return cropped;
  }
}
