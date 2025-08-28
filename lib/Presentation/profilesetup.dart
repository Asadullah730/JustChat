import 'dart:io';
import 'package:chat_application/Presentation/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  const ProfileSetupScreen({super.key, required this.uid});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  File? _image;
  bool _saving = false;

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final picked = await p.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    String photoUrl = '';
    if (_image != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('${widget.uid}.jpg');
      await ref.putFile(_image!);
      photoUrl = await ref.getDownloadURL();
    }
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
      'displayName': _name.text.trim(),
      'photoUrl': photoUrl,
    }, SetOptions(merge: true));
    if (kDebugMode) {
      print("PROFILE UPDATED : ");
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _image == null ? null : FileImage(_image!),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
