import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<String?> uploadImageToSupabase(imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      final response = await supabase.storage
          .from('profile-pics')
          .upload(fileName, imageFile);

      if (kDebugMode) {
        print("PICTURE RESPONSE : ${response}");
      }

      if (response.isNotEmpty) {
        final publicUrl = supabase.storage
            .from('profile-pics')
            .getPublicUrl(fileName);

        Get.snackbar("IMAGE RESULT", "IMAGE UPLOAD SUCCESSFULLY");
        return publicUrl;
      } else {
        debugPrint('UPLOAD FAILD');
        return null;
      }
    } catch (e) {
      debugPrint('ERROR WHILE UPLOADING THE IMAGE $e');
      return null;
    }
  }
}
