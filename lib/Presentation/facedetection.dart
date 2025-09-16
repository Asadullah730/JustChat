import 'dart:io';
import 'package:chat_application/AI_model/face_detector_service.dart';
import 'package:chat_application/AI_model/face_recognition_service.dart';
import 'package:chat_application/AI_utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FaceMatchScreen extends StatefulWidget {
  @override
  _FaceMatchScreenState createState() => _FaceMatchScreenState();
}

class _FaceMatchScreenState extends State<FaceMatchScreen> {
  final picker = ImagePicker();
  final faceDetector = FaceDetectorService();
  final faceService = FaceRecognitionService();

  File? image1, image2;
  double? similarity;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    faceService.loadModel();
  }

  Future<void> pickImage(int slot) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      if (slot == 1) {
        image1 = File(pickedFile.path);
      } else {
        image2 = File(pickedFile.path);
      }
    });
  }

  Future<void> compareFaces() async {
    if (image1 == null || image2 == null) return;

    setState(() => loading = true);

    final face1 = await faceDetector.detectAndCropFace(image1!);
    final face2 = await faceDetector.detectAndCropFace(image2!);

    if (kDebugMode) {
      print("Face 1: $face1");
      print("Face 2: $face2");
    }

    if (face1 == null || face2 == null) {
      setState(() {
        loading = false;
        similarity = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Face not detected!")));
      return;
    }

    final emb1 = faceService.getEmbedding(face1);
    final emb2 = faceService.getEmbedding(face2);

    final sim = cosineSimilarity(emb1, emb2);

    setState(() {
      similarity = sim;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Face Matching")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickImage(1),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(12),
                        image: image1 != null
                            ? DecorationImage(
                                image: FileImage(image1!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: image1 == null
                          ? Center(child: Text("Select Image 1"))
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => pickImage(2),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple),
                        borderRadius: BorderRadius.circular(12),
                        image: image2 != null
                            ? DecorationImage(
                                image: FileImage(image2!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: image2 == null
                          ? Center(child: Text("Select Image 2"))
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.face_retouching_natural),
              label: Text("Compare Faces"),
              onPressed: loading ? null : compareFaces,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 20),
            if (loading) CircularProgressIndicator(),
            if (similarity != null && !loading)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Cosine Similarity: ${similarity!.toStringAsFixed(2)}\n"
                    "${similarity! > 0.7 ? "✅ Faces Match" : "❌ Faces Do Not Match"}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: similarity! > 0.7 ? Colors.green : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
